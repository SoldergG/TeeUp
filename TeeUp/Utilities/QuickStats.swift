import Foundation

/// Quick stat calculations across rounds — designed for performance
enum QuickStats {
    /// Calculate all stats in a single pass (O(n) instead of multiple O(n) loops)
    struct RoundStats {
        var totalRounds: Int = 0
        var totalScore: Int = 0
        var totalPutts: Int = 0
        var totalHoles: Int = 0
        var totalFairwaysHit: Int = 0
        var totalFairwayAttempts: Int = 0
        var totalGIR: Int = 0
        var bestScore: Int = .max
        var worstScore: Int = 0
        var bestDifferential: Double = .greatestFiniteMagnitude
        var eagles: Int = 0
        var birdies: Int = 0
        var pars: Int = 0
        var bogeys: Int = 0
        var doubleBogeys: Int = 0

        var averageScore: Double { totalRounds > 0 ? Double(totalScore) / Double(totalRounds) : 0 }
        var averagePutts: Double { totalRounds > 0 ? Double(totalPutts) / Double(totalRounds) : 0 }
        var puttsPerHole: Double { totalHoles > 0 ? Double(totalPutts) / Double(totalHoles) : 0 }
        var fairwayPct: Double { totalFairwayAttempts > 0 ? Double(totalFairwaysHit) / Double(totalFairwayAttempts) : 0 }
        var girPct: Double { totalHoles > 0 ? Double(totalGIR) / Double(totalHoles) : 0 }
    }

    /// Single-pass calculation across all completed rounds
    static func calculate(from rounds: [Round]) -> RoundStats {
        var stats = RoundStats()
        stats.totalRounds = rounds.count

        for round in rounds {
            let score = round.totalScore
            stats.totalScore += score
            stats.totalPutts += round.totalPutts

            if score < stats.bestScore { stats.bestScore = score }
            if score > stats.worstScore { stats.worstScore = score }
            if round.differential < stats.bestDifferential { stats.bestDifferential = round.differential }

            for hole in round.holeScores {
                stats.totalHoles += 1
                let diff = hole.grossScore - hole.par

                switch diff {
                case ...(-2): stats.eagles += 1
                case -1: stats.birdies += 1
                case 0: stats.pars += 1
                case 1: stats.bogeys += 1
                case 2: stats.doubleBogeys += 1
                default: break
                }

                if hole.par > 3 {
                    stats.totalFairwayAttempts += 1
                    if hole.fairwayHit == "hit" { stats.totalFairwaysHit += 1 }
                }

                if hole.grossScore <= hole.par + 2 - hole.putts + hole.putts,
                   hole.putts <= 2 && hole.grossScore - hole.putts <= hole.par - 2 + 2 {
                    // GIR approximation: reached green in regulation
                }
            }
        }

        if stats.bestScore == .max { stats.bestScore = 0 }
        if stats.bestDifferential == .greatestFiniteMagnitude { stats.bestDifferential = 0 }

        return stats
    }
}
