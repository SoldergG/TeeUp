import UIKit

enum Haptics {
    /// Light tap — for selections, subtle taps
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium tap — for primary buttons
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Soft tap — for score grid, smooth interactions
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Rigid tap — for toggles, sharp feedback
    static func rigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    /// Selection change — when swiping through options
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Success — completed action
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning — unsaved or risky action
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Error — failed action
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Score feedback based on score-to-par (special haptic for birdies/eagles)
    static func score(toPar: Int) {
        switch toPar {
        case ...(-2): // Eagle or better
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.success)
        case -1: // Birdie
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case 0: // Par
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case 1: // Bogey
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        default: // Double bogey or worse
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.warning)
        }
    }
}
