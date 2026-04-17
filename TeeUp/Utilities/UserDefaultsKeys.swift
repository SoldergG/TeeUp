import Foundation

/// Centralized UserDefaults keys — prevents typos and duplicates
enum UDKey {
    static let hasSkippedLogin = "hasSkippedLogin"
    static let hasShownPermissions = "hasShownPermissions"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let lastReviewRequest = "lastReviewRequestDate"
    static let roundsCompleted = "roundsCompletedCount"
    static let preferredDistanceUnit = "preferredDistanceUnit"
    static let preferredTeeColor = "preferredTeeColor"
    static let showFairwayHits = "showFairwayHits"
    static let showPutts = "showPutts"
    static let showPenalties = "showPenalties"
    static let autoAdvanceHoles = "autoAdvanceHoles"
    static let hapticFeedback = "hapticFeedback"
    static let soundEffects = "soundEffects"
    static let searchRadiusKm = "searchRadiusKm"
    static let lastSyncDate = "lastSyncDate"
    static let appLaunchCount = "appLaunchCount"
    static let lastVersionPrompted = "lastVersionPrompted"
    static let mapStyle = "mapStyle"
    static let defaultScorecardLayout = "defaultScorecardLayout"
}

// MARK: - Convenience accessors
extension UserDefaults {
    var hapticFeedbackEnabled: Bool {
        get { object(forKey: UDKey.hapticFeedback) as? Bool ?? true }
        set { set(newValue, forKey: UDKey.hapticFeedback) }
    }

    var soundEffectsEnabled: Bool {
        get { object(forKey: UDKey.soundEffects) as? Bool ?? true }
        set { set(newValue, forKey: UDKey.soundEffects) }
    }

    var autoAdvanceHoles: Bool {
        get { object(forKey: UDKey.autoAdvanceHoles) as? Bool ?? true }
        set { set(newValue, forKey: UDKey.autoAdvanceHoles) }
    }

    var appLaunchCount: Int {
        get { integer(forKey: UDKey.appLaunchCount) }
        set { set(newValue, forKey: UDKey.appLaunchCount) }
    }
}
