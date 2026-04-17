import SwiftUI
import SwiftData

@main
struct TeeUpApp: App {
    init() {
        // Performance: deferred background setup
        StartupOptimizer.performDeferredSetup()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .withOfflineBanner()
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
