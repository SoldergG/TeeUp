import Foundation
import Supabase

// MARK: - Data Models
struct FriendProfile: Identifiable, Codable, Hashable {
    let id: String
    let name: String?
    let username: String?
    let handicapIndex: Double?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, username
        case handicapIndex = "handicap_index"
        case avatarUrl = "avatar_url"
    }

    var displayName: String { name ?? username ?? "Jogador" }
    var handicapDisplay: String {
        guard let h = handicapIndex else { return "—" }
        return String(format: "%.1f", h)
    }
}

struct FriendshipRow: Identifiable, Codable {
    let id: String
    let requesterId: String
    let addresseeId: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, status
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
    }
}

struct FriendItem: Identifiable, Hashable {
    let friendshipId: String
    let profile: FriendProfile
    var id: String { profile.id }
}

// MARK: - Service
@MainActor
@Observable
final class FriendsService {
    var friends: [FriendItem] = []
    var pendingIncoming: [(friendship: FriendshipRow, profile: FriendProfile?)] = []
    var pendingSent: [FriendshipRow] = []
    var searchResults: [FriendProfile] = []
    var isLoading = false
    var errorMessage: String?

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private var myId: String { SupabaseManager.shared.currentUser?.id.uuidString ?? "" }

    var isAuthenticated: Bool { !myId.isEmpty }

    // MARK: - Fetch All
    func fetchAll() async {
        guard isAuthenticated else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Accepted friendships
            let accepted: [FriendshipRow] = try await client.from("friendships")
                .select("id, requester_id, addressee_id, status")
                .or("requester_id.eq.\(myId),addressee_id.eq.\(myId)")
                .eq("status", value: "accepted")
                .execute().value

            let friendIds = accepted.map { f in
                f.requesterId == myId ? f.addresseeId : f.requesterId
            }

            if !friendIds.isEmpty {
                let profiles: [FriendProfile] = try await client.from("profiles")
                    .select("id, name, username, handicap_index, avatar_url")
                    .in("id", values: friendIds)
                    .execute().value

                friends = accepted.compactMap { row in
                    let fId = row.requesterId == myId ? row.addresseeId : row.requesterId
                    guard let profile = profiles.first(where: { $0.id == fId }) else { return nil }
                    return FriendItem(friendshipId: row.id, profile: profile)
                }
            } else {
                friends = []
            }

            // Pending incoming
            let incoming: [FriendshipRow] = try await client.from("friendships")
                .select("id, requester_id, addressee_id, status")
                .eq("addressee_id", value: myId)
                .eq("status", value: "pending")
                .execute().value

            if !incoming.isEmpty {
                let requesterIds = incoming.map(\.requesterId)
                let requesterProfiles: [FriendProfile] = try await client.from("profiles")
                    .select("id, name, username, handicap_index, avatar_url")
                    .in("id", values: requesterIds)
                    .execute().value

                pendingIncoming = incoming.map { row in
                    let profile = requesterProfiles.first(where: { $0.id == row.requesterId })
                    return (friendship: row, profile: profile)
                }
            } else {
                pendingIncoming = []
            }

            // Pending sent
            pendingSent = try await client.from("friendships")
                .select("id, requester_id, addressee_id, status")
                .eq("requester_id", value: myId)
                .eq("status", value: "pending")
                .execute().value

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Search
    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty, isAuthenticated else {
            searchResults = []; return
        }
        do {
            let results: [FriendProfile] = try await client.from("profiles")
                .select("id, name, username, handicap_index, avatar_url")
                .or("username.ilike.%\(query)%,name.ilike.%\(query)%")
                .neq("id", value: myId)
                .limit(20)
                .execute().value
            searchResults = results
        } catch {
            searchResults = []
        }
    }

    // MARK: - Actions
    func sendRequest(to userId: String) async throws {
        struct NewFriendship: Encodable {
            let requester_id: String
            let addressee_id: String
            let status: String
        }
        try await client.from("friendships")
            .insert(NewFriendship(requester_id: myId, addressee_id: userId, status: "pending"))
            .execute()
        await fetchAll()
    }

    func acceptRequest(friendshipId: String) async throws {
        struct StatusUpdate: Encodable { let status: String }
        try await client.from("friendships")
            .update(StatusUpdate(status: "accepted"))
            .eq("id", value: friendshipId)
            .execute()
        await fetchAll()
    }

    func rejectRequest(friendshipId: String) async throws {
        try await client.from("friendships")
            .delete()
            .eq("id", value: friendshipId)
            .execute()
        await fetchAll()
    }

    func removeFriend(item: FriendItem) async throws {
        try await client.from("friendships")
            .delete()
            .eq("id", value: item.friendshipId)
            .execute()
        await fetchAll()
    }

    func cancelRequest(friendshipId: String) async throws {
        try await client.from("friendships")
            .delete()
            .eq("id", value: friendshipId)
            .execute()
        await fetchAll()
    }

    func isFriend(_ userId: String) -> Bool {
        friends.contains { $0.profile.id == userId }
    }

    func hasPendingSent(to userId: String) -> Bool {
        pendingSent.contains { $0.addresseeId == userId }
    }
}
