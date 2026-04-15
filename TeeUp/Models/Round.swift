import Foundation
import SwiftData

// MARK: - Round
@Model
final class Round {
    @Attribute(.unique) var id: String
    var courseId: String
    var courseName: String
    var teeId: String
    var teeName: String
    var courseRating: Double
    var slopeRating: Int
    var date: Date
    var isCompleted: Bool
    var adjustedGrossScore: Int
    var differential: Double
    var totalPutts: Int
    var notes: String

    @Relationship(deleteRule: .cascade) var holeScores: [HoleScore]

    init(
        id: String = UUID().uuidString,
        courseId: String,
        courseName: String,
        teeId: String,
        teeName: String,
        courseRating: Double,
        slopeRating: Int,
        date: Date = .now,
        isCompleted: Bool = false,
        adjustedGrossScore: Int = 0,
        differential: Double = 0,
        totalPutts: Int = 0,
        notes: String = "",
        holeScores: [HoleScore] = []
    ) {
        self.id = id
        self.courseId = courseId
        self.courseName = courseName
        self.teeId = teeId
        self.teeName = teeName
        self.courseRating = courseRating
        self.slopeRating = slopeRating
        self.date = date
        self.isCompleted = isCompleted
        self.adjustedGrossScore = adjustedGrossScore
        self.differential = differential
        self.totalPutts = totalPutts
        self.notes = notes
        self.holeScores = holeScores
    }

    // MARK: - Computed Stats
    var totalScore: Int {
        holeScores.reduce(0) { $0 + $1.grossScore }
    }

    var scoreToPar: Int {
        holeScores.reduce(0) { $0 + ($1.grossScore - $1.par) }
    }

    var scoreToParString: String {
        let diff = scoreToPar
        if diff == 0 { return "E" }
        return diff > 0 ? "+\(diff)" : "\(diff)"
    }

    var girPercentage: Double {
        let girHoles = holeScores.filter { $0.gir }
        guard !holeScores.isEmpty else { return 0 }
        return Double(girHoles.count) / Double(holeScores.count) * 100
    }

    var fairwayPercentage: Double {
        let applicable = holeScores.filter { $0.fairwayHit != FairwayHit.na.rawValue }
        guard !applicable.isEmpty else { return 0 }
        let hit = applicable.filter { $0.fairwayHit == FairwayHit.yes.rawValue }
        return Double(hit.count) / Double(applicable.count) * 100
    }

    var averagePutts: Double {
        guard !holeScores.isEmpty else { return 0 }
        return Double(holeScores.reduce(0) { $0 + $1.putts }) / Double(holeScores.count)
    }

    var scramblingPercentage: Double {
        let missedGIR = holeScores.filter { !$0.gir }
        guard !missedGIR.isEmpty else { return 0 }
        let saved = missedGIR.filter { $0.upAndDown }
        return Double(saved.count) / Double(missedGIR.count) * 100
    }

    var dateFormatted: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Score by hole type
    func averageScoreForPar(_ par: Int) -> Double {
        let holes = holeScores.filter { $0.par == par }
        guard !holes.isEmpty else { return 0 }
        return Double(holes.reduce(0) { $0 + $1.grossScore }) / Double(holes.count)
    }
}

// MARK: - HoleScore
@Model
final class HoleScore {
    var holeNumber: Int
    var par: Int
    var strokeIndex: Int
    var grossScore: Int
    var putts: Int
    var fairwayHit: String // FairwayHit rawValue
    var gir: Bool
    var sandSave: Bool
    var upAndDown: Bool
    var penalties: Int
    var windDirection: String // WindDirection rawValue
    var windStrength: String // WindStrength rawValue
    var notes: String

    var round: Round?

    init(
        holeNumber: Int,
        par: Int,
        strokeIndex: Int,
        grossScore: Int = 0,
        putts: Int = 0,
        fairwayHit: String = FairwayHit.na.rawValue,
        gir: Bool = false,
        sandSave: Bool = false,
        upAndDown: Bool = false,
        penalties: Int = 0,
        windDirection: String = WindDirection.none.rawValue,
        windStrength: String = WindStrength.calm.rawValue,
        notes: String = ""
    ) {
        self.holeNumber = holeNumber
        self.par = par
        self.strokeIndex = strokeIndex
        self.grossScore = grossScore
        self.putts = putts
        self.fairwayHit = fairwayHit
        self.gir = gir
        self.sandSave = sandSave
        self.upAndDown = upAndDown
        self.penalties = penalties
        self.windDirection = windDirection
        self.windStrength = windStrength
        self.notes = notes
    }

    var scoreToParValue: Int {
        grossScore - par
    }

    var scoreName: String {
        let diff = scoreToParValue
        switch diff {
        case ...(-3): return "Albatross"
        case -2: return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Double Bogey"
        case 3: return "Triple Bogey"
        default: return "+\(diff)"
        }
    }
}
