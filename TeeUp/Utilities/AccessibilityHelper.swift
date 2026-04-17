import SwiftUI

// MARK: - Accessibility extensions
extension View {
    /// Add golf-specific accessibility labels
    func scoreAccessibility(score: Int, par: Int, hole: Int) -> some View {
        let toPar = score - par
        let label = "Buraco \(hole): \(score) pancadas, \(GolfFormatters.parLabelPT(for: toPar))"
        return self.accessibilityLabel(label)
    }

    func handicapAccessibility(_ value: Double) -> some View {
        accessibilityLabel("Handicap: \(GolfFormatters.handicap(value))")
    }

    func courseAccessibility(name: String, distance: String, rating: Double) -> some View {
        let label = "\(name), a \(distance), classificação \(String(format: "%.1f", rating)) estrelas"
        return self.accessibilityLabel(label)
    }
}

// MARK: - Dynamic Type support
extension Font {
    /// Golf-specific scaled fonts
    static var golfScore: Font {
        .system(.title, design: .rounded).bold().monospacedDigit()
    }

    static var golfHole: Font {
        .system(.headline, design: .rounded).monospacedDigit()
    }

    static var golfStat: Font {
        .system(.subheadline, design: .rounded).monospacedDigit()
    }

    static var golfCaption: Font {
        .system(.caption, design: .rounded)
    }
}

// MARK: - Reduced motion check
extension View {
    @ViewBuilder
    func animationSafe<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            self.animation(animation, value: value)
        }
    }
}
