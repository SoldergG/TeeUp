import Foundation
import SwiftUI

/// Centralized, cached formatters for golf-specific data
enum GolfFormatters {
    // MARK: - Score to Par
    static func parLabel(for score: Int) -> String {
        switch score {
        case ...(-3): return "Albatross"
        case -2: return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Double Bogey"
        case 3: return "Triple Bogey"
        default: return "+\(score)"
        }
    }

    static func parLabelPT(for score: Int) -> String {
        switch score {
        case ...(-3): return "Albatroz"
        case -2: return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Duplo Bogey"
        case 3: return "Triplo Bogey"
        default: return "+\(score)"
        }
    }

    // MARK: - Handicap
    static func handicap(_ value: Double) -> String {
        if value <= 0 { return "+\(String(format: "%.1f", abs(value)))" }
        return String(format: "%.1f", value)
    }

    // MARK: - Differential
    static func differential(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    // MARK: - Distance
    static func distance(meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    // MARK: - Score color
    static func scoreColor(for toPar: Int) -> Color {
        switch toPar {
        case ...(-2): return .indigo
        case -1: return .blue
        case 0: return AppTheme.primaryGreen
        case 1: return .orange
        default: return .red
        }
    }

    // MARK: - Round duration
    static func duration(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)min" }
        return "\(m) min"
    }

    // MARK: - Green fee
    static func greenFee(_ value: Double) -> String {
        if value == 0 { return "Grátis" }
        return String(format: "%.0f €", value)
    }

    // MARK: - Stat percentage
    static func percentage(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    // MARK: - Putts average
    static func puttsAvg(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    // MARK: - Pace of play
    static func paceOfPlay(minutesPerHole: Double) -> String {
        let m = Int(minutesPerHole)
        let s = Int((minutesPerHole - Double(m)) * 60)
        return "\(m):\(String(format: "%02d", s)) / buraco"
    }
}
