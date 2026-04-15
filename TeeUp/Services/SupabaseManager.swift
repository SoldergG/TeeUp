import Foundation
import Supabase
import Auth

@Observable
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    var currentUser: User? { client.auth.currentUser }
    var isAuthenticated: Bool { currentUser != nil }

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://bolsrjupsxzglrjbdezr.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvbHNyanVwc3h6Z2xyamJkZXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxODkyMDMsImV4cCI6MjA5MTc2NTIwM30.2K0XOEUIFYl25wX00YYj4F_62bc5ZgvXwYRRtxl8Q_I"
        )
    }

    // MARK: - Auth

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Profile

    func fetchProfile() async throws -> ProfileData? {
        guard let userId = currentUser?.id else { return nil }
        return try await client.from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func updateProfile(_ profile: ProfileData) async throws {
        guard let userId = currentUser?.id else { return }
        try await client.from("profiles")
            .update(profile)
            .eq("id", value: userId.uuidString)
            .execute()
    }
}

// MARK: - Profile Data (Codable for Supabase)
struct ProfileData: Codable, Sendable {
    var name: String?
    var username: String?
    var avatarUrl: String?
    var homeCourseName: String?
    var handicapIndex: Double?
    var subscriptionTier: String?
    var distanceUnit: String?
    var roundsPlayedTotal: Int?
    var bestScore: Int?
    var bestScoreCourse: String?

    enum CodingKeys: String, CodingKey {
        case name, username
        case avatarUrl = "avatar_url"
        case homeCourseName = "home_course_name"
        case handicapIndex = "handicap_index"
        case subscriptionTier = "subscription_tier"
        case distanceUnit = "distance_unit"
        case roundsPlayedTotal = "rounds_played_total"
        case bestScore = "best_score"
        case bestScoreCourse = "best_score_course"
    }
}
