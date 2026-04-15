import Foundation

/// World Handicap System (WHS) calculator
struct HandicapCalculator {

    /// Calculate Score Differential per WHS formula:
    /// (113 / Slope Rating) × (Adjusted Gross Score - Course Rating)
    static func scoreDifferential(
        adjustedGrossScore: Int,
        courseRating: Double,
        slopeRating: Int
    ) -> Double {
        guard slopeRating > 0 else { return 0 }
        let differential = (113.0 / Double(slopeRating)) * (Double(adjustedGrossScore) - courseRating)
        return (differential * 10).rounded() / 10 // 1 decimal
    }

    /// Calculate Adjusted Gross Score using Equitable Stroke Control (ESC)
    /// Max score per hole = Net Double Bogey = Par + 2 + handicap strokes received on that hole
    static func adjustedGrossScore(
        holeScores: [HoleScore],
        courseHandicap: Int
    ) -> Int {
        var total = 0
        for hole in holeScores {
            let strokesReceived = handicapStrokesForHole(
                strokeIndex: hole.strokeIndex,
                courseHandicap: courseHandicap,
                totalHoles: holeScores.count
            )
            let maxScore = hole.par + 2 + strokesReceived
            let adjusted = min(hole.grossScore, maxScore)
            total += adjusted
        }
        return total
    }

    /// How many handicap strokes a player receives on a specific hole
    static func handicapStrokesForHole(
        strokeIndex: Int,
        courseHandicap: Int,
        totalHoles: Int
    ) -> Int {
        guard courseHandicap > 0, strokeIndex > 0 else { return 0 }
        let fullRounds = courseHandicap / totalHoles
        let remainder = courseHandicap % totalHoles
        return fullRounds + (strokeIndex <= remainder ? 1 : 0)
    }

    /// Calculate Course Handicap from Handicap Index
    /// Course Handicap = Handicap Index × (Slope Rating / 113) + (Course Rating - Par)
    static func courseHandicap(
        handicapIndex: Double,
        slopeRating: Int,
        courseRating: Double,
        par: Int
    ) -> Int {
        let ch = handicapIndex * (Double(slopeRating) / 113.0) + (courseRating - Double(par))
        return Int(ch.rounded())
    }

    /// Calculate Playing Handicap (for stroke play, 95% of course handicap)
    static func playingHandicap(courseHandicap: Int) -> Int {
        return Int((Double(courseHandicap) * 0.95).rounded())
    }

    /// Calculate Handicap Index from a list of differentials (WHS rules)
    /// Uses the best N differentials depending on total count
    static func handicapIndex(from differentials: [Double]) -> Double {
        guard !differentials.isEmpty else { return 54.0 }

        let sorted = differentials.sorted()
        let count = sorted.count
        let used: [Double]
        let adjustment: Double

        switch count {
        case 1...3:
            used = [sorted[0]]
            adjustment = -2.0
        case 4...5:
            used = [sorted[0]]
            adjustment = -1.0
        case 6:
            used = Array(sorted.prefix(2))
            adjustment = -1.0
        case 7...8:
            used = Array(sorted.prefix(2))
            adjustment = 0
        case 9...11:
            used = Array(sorted.prefix(3))
            adjustment = 0
        case 12...14:
            used = Array(sorted.prefix(4))
            adjustment = 0
        case 15...16:
            used = Array(sorted.prefix(5))
            adjustment = 0
        case 17...18:
            used = Array(sorted.prefix(6))
            adjustment = 0
        case 19:
            used = Array(sorted.prefix(7))
            adjustment = 0
        default: // 20+
            used = Array(sorted.prefix(8))
            adjustment = 0
        }

        let average = used.reduce(0, +) / Double(used.count)
        let index = max(0, min(54.0, average + adjustment))
        return (index * 10).rounded() / 10
    }
}
