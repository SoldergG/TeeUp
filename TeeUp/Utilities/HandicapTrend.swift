import Foundation
import SwiftUI

/// Analyzes handicap trends and provides insights
enum HandicapTrend {
    enum Direction {
        case improving, worsening, stable

        var label: String {
            switch self {
            case .improving: return "A melhorar"
            case .worsening: return "A subir"
            case .stable: return "Estável"
            }
        }

        var icon: String {
            switch self {
            case .improving: return "arrow.down.right"
            case .worsening: return "arrow.up.right"
            case .stable: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .improving: return .green
            case .worsening: return .red
            case .stable: return .orange
            }
        }
    }

    /// Determine trend from last N handicap records
    static func direction(from records: [HandicapRecord], window: Int = 5) -> Direction {
        guard records.count >= 2 else { return .stable }

        let recent = records.sorted { $0.date > $1.date }.prefix(window)
        guard let first = recent.last, let last = recent.first else { return .stable }

        let diff = last.handicapIndex - first.handicapIndex
        if diff < -0.5 { return .improving }
        if diff > 0.5 { return .worsening }
        return .stable
    }

    /// Average differential over last N rounds
    static func averageDifferential(from records: [HandicapRecord], count: Int = 10) -> Double {
        let recent = records.sorted { $0.date > $1.date }.prefix(count)
        guard recent.isNotEmpty else { return 0 }
        return recent.map(\.differential).average
    }

    /// Best differential in history
    static func bestDifferential(from records: [HandicapRecord]) -> Double? {
        records.map(\.differential).min()
    }

    /// Lowest handicap achieved
    static func lowestHandicap(from records: [HandicapRecord]) -> Double? {
        records.map(\.handicapIndex).min()
    }

    /// Projected handicap if current trend continues
    static func projectedHandicap(current: Double, records: [HandicapRecord]) -> Double {
        let dir = direction(from: records)
        switch dir {
        case .improving: return max(0, current - 0.5)
        case .worsening: return current + 0.5
        case .stable: return current
        }
    }
}
