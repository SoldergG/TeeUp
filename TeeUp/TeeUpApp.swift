import SwiftUI
import SwiftData

@main
struct TeeUpApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle OAuth callback (Google Sign In via Supabase)
                    Task {
                        try? await SupabaseManager.shared.client.auth.session(from: url)
                    }
                }
        }
        .modelContainer(for: [
            Course.self,
            Tee.self,
            HoleData.self,
            Round.self,
            HoleScore.self,
            UserProfile.self,
            HandicapRecord.self,
            CachedCourseSearch.self
        ])
    }
}
