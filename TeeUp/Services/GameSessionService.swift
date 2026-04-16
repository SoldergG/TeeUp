import Foundation
import Supabase

// MARK: - Models

struct GameSession: Identifiable, Codable {
    let id: String
    let creatorId: String
    let coursePlaceId: String
    let courseName: String
    let courseAddress: String?
    let courseLat: Double?
    let courseLng: Double?
    let scheduledAt: Date
    let pricePerPerson: Double?
    let notes: String?
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case creatorId = "creator_id"
        case coursePlaceId = "course_place_id"
        case courseName = "course_name"
        case courseAddress = "course_address"
        case courseLat = "course_lat"
        case courseLng = "course_lng"
        case scheduledAt = "scheduled_at"
        case pricePerPerson = "price_per_person"
        case createdAt = "created_at"
    }

    var isUpcoming: Bool { scheduledAt > Date() }
    var isPast: Bool { !isUpcoming }

    var scheduledDisplay: String {
        scheduledAt.formatted(date: .abbreviated, time: .shortened)
    }

    var priceDisplay: String {
        guard let p = pricePerPerson, p > 0 else { return "Grátis" }
        return String(format: "€%.0f/pessoa", p)
    }

    var statusDisplay: String {
        switch status {
        case "open": return "Aberto"
        case "confirmed": return "Confirmado"
        case "cancelled": return "Cancelado"
        case "completed": return "Concluído"
        default: return status
        }
    }
}

struct SessionParticipant: Identifiable, Codable {
    let id: String
    let sessionId: String
    let userId: String
    var status: String
    let finalScore: Int?
    let finalDifferential: Double?
    let createdAt: Date

    // Populated client-side
    var profile: FriendProfile?

    enum CodingKeys: String, CodingKey {
        case id, status
        case sessionId = "session_id"
        case userId = "user_id"
        case finalScore = "final_score"
        case finalDifferential = "final_differential"
        case createdAt = "created_at"
    }

    var statusColor: String {
        switch status {
        case "accepted": return "green"
        case "declined": return "red"
        default: return "orange"
        }
    }

    var statusIcon: String {
        switch status {
        case "accepted": return "checkmark.circle.fill"
        case "declined": return "xmark.circle.fill"
        default: return "clock.fill"
        }
    }
}

struct GameSessionDetail: Identifiable {
    let session: GameSession
    var participants: [SessionParticipant]
    var creatorProfile: FriendProfile?
    var id: String { session.id }

    var myUserId: String { SupabaseManager.shared.currentUser?.id.uuidString ?? "" }
    var isCreator: Bool { session.creatorId == myUserId }
    var myParticipant: SessionParticipant? { participants.first { $0.userId == myUserId } }
    var myStatus: String { isCreator ? "creator" : (myParticipant?.status ?? "unknown") }

    var acceptedCount: Int { participants.filter { $0.status == "accepted" }.count + 1 } // +1 creator
    var pendingCount: Int { participants.filter { $0.status == "pending" }.count }
}

// MARK: - New Session Input
struct NewGameSession: Encodable {
    let creator_id: String
    let course_place_id: String
    let course_name: String
    let course_address: String
    let course_lat: Double?
    let course_lng: Double?
    let scheduled_at: Date
    let price_per_person: Double?
    let notes: String
    let status: String
}

struct NewParticipant: Encodable {
    let session_id: String
    let user_id: String
    let status: String
}

// MARK: - Service

@MainActor
@Observable
final class GameSessionService {
    var sessions: [GameSessionDetail] = []
    var isLoading = false
    var errorMessage: String?

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private var myId: String { SupabaseManager.shared.currentUser?.id.uuidString ?? "" }
    var isAuthenticated: Bool { !myId.isEmpty }

    // MARK: - Fetch

    func fetchSessions() async {
        guard isAuthenticated else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Sessions I created
            let created: [GameSession] = try await client.from("game_sessions")
                .select("*")
                .eq("creator_id", value: myId)
                .order("scheduled_at", ascending: false)
                .execute().value

            // Sessions I'm invited to
            let myInvites: [SessionParticipant] = try await client.from("session_participants")
                .select("*")
                .eq("user_id", value: myId)
                .execute().value

            let invitedSessionIds = myInvites.map(\.sessionId)
            var invitedSessions: [GameSession] = []
            if !invitedSessionIds.isEmpty {
                invitedSessions = try await client.from("game_sessions")
                    .select("*")
                    .in("id", values: invitedSessionIds)
                    .order("scheduled_at", ascending: false)
                    .execute().value
            }

            // Merge unique sessions
            var allSessions = created
            for s in invitedSessions where !allSessions.contains(where: { $0.id == s.id }) {
                allSessions.append(s)
            }
            allSessions.sort { $0.scheduledAt > $1.scheduledAt }

            // Fetch participants for all sessions
            let sessionIds = allSessions.map(\.id)
            var allParticipants: [SessionParticipant] = []
            if !sessionIds.isEmpty {
                allParticipants = try await client.from("session_participants")
                    .select("*")
                    .in("session_id", values: sessionIds)
                    .execute().value
            }

            // Fetch profiles for all participant user IDs + creator IDs
            var userIds = Set(allParticipants.map(\.userId))
            allSessions.forEach { userIds.insert($0.creatorId) }
            let userIdArray = Array(userIds)

            var profiles: [FriendProfile] = []
            if !userIdArray.isEmpty {
                profiles = try await client.from("profiles")
                    .select("id, name, username, handicap_index, avatar_url")
                    .in("id", values: userIdArray)
                    .execute().value
            }

            // Build details
            sessions = allSessions.map { session in
                var parts = allParticipants
                    .filter { $0.sessionId == session.id }
                    .map { p -> SessionParticipant in
                        var p2 = p
                        p2.profile = profiles.first { $0.id == p.userId }
                        return p2
                    }
                let creatorProfile = profiles.first { $0.id == session.creatorId }
                return GameSessionDetail(session: session, participants: parts, creatorProfile: creatorProfile)
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Create

    func createSession(
        course: GolfCourse,
        scheduledAt: Date,
        pricePerPerson: Double?,
        notes: String,
        friendIds: [String]
    ) async throws {
        let newSession = NewGameSession(
            creator_id: myId,
            course_place_id: course.id,
            course_name: course.name,
            course_address: course.address,
            course_lat: course.latitude,
            course_lng: course.longitude,
            scheduled_at: scheduledAt,
            price_per_person: pricePerPerson,
            notes: notes,
            status: "open"
        )

        let created: GameSession = try await client.from("game_sessions")
            .insert(newSession)
            .select()
            .single()
            .execute().value

        // Add participants
        if !friendIds.isEmpty {
            let participants = friendIds.map {
                NewParticipant(session_id: created.id, user_id: $0, status: "pending")
            }
            try await client.from("session_participants")
                .insert(participants)
                .execute()
        }

        await fetchSessions()
    }

    // MARK: - Update Status

    func respondToSession(sessionId: String, accept: Bool) async throws {
        struct StatusUpdate: Encodable { let status: String }
        try await client.from("session_participants")
            .update(StatusUpdate(status: accept ? "accepted" : "declined"))
            .eq("session_id", value: sessionId)
            .eq("user_id", value: myId)
            .execute()
        await fetchSessions()
    }

    func cancelSession(sessionId: String) async throws {
        struct StatusUpdate: Encodable { let status: String }
        try await client.from("game_sessions")
            .update(StatusUpdate(status: "cancelled"))
            .eq("id", value: sessionId)
            .execute()
        await fetchSessions()
    }

    func submitScore(sessionId: String, score: Int, differential: Double) async throws {
        struct ScoreUpdate: Encodable {
            let final_score: Int
            let final_differential: Double
        }
        try await client.from("session_participants")
            .update(ScoreUpdate(final_score: score, final_differential: differential))
            .eq("session_id", value: sessionId)
            .eq("user_id", value: myId)
            .execute()
        await fetchSessions()
    }
}
