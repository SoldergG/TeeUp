import SwiftUI
import SwiftData

@main
struct TeeUpApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Course.self,
            Tee.self,
            HoleData.self,
            Round.self,
            HoleScore.self,
            UserProfile.self,
            HandicapRecord.self
        ])
    }
}
