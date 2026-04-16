import Foundation
import SwiftData
import SwiftUI

@Observable
class RoundsViewModel {
    var modelContext: ModelContext?

    func fetchRounds() -> [Round] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Round>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchRecentRounds(limit: Int = 10) -> [Round] {
        guard let context = modelContext else { return [] }
        var descriptor = FetchDescriptor<Round>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchCompletedRounds() -> [Round] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Round>(
            predicate: #Predicate<Round> { $0.isCompleted },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func deleteRound(_ round: Round) {
        modelContext?.delete(round)
        try? modelContext?.save()
    }

    func completeRound(_ round: Round, userProfile: UserProfile) {
        let courseHandicap = HandicapCalculator.courseHandicap(
            handicapIndex: userProfile.handicapIndex,
            slopeRating: round.slopeRating,
            courseRating: round.courseRating,
            par: round.holeScores.reduce(0) { $0 + $1.par }
        )

        round.adjustedGrossScore = HandicapCalculator.adjustedGrossScore(
            holeScores: round.holeScores,
            courseHandicap: courseHandicap
        )

        round.differential = HandicapCalculator.scoreDifferential(
            adjustedGrossScore: round.adjustedGrossScore,
            courseRating: round.courseRating,
            slopeRating: round.slopeRating
        )

        round.totalPutts = round.holeScores.reduce(0) { $0 + $1.putts }
        round.isCompleted = true

        // Update handicap
        let allRounds = fetchCompletedRounds()
        let differentials = allRounds.map(\.differential)
        let newIndex = HandicapCalculator.handicapIndex(from: differentials)
        userProfile.handicapIndex = newIndex
        userProfile.roundsPlayedTotal = allRounds.count

        // Update best score
        let totalScore = round.totalScore
        if userProfile.bestScore == 0 || totalScore < userProfile.bestScore {
            userProfile.bestScore = totalScore
            userProfile.bestScoreCourse = round.courseName
        }

        // Add handicap record
        let record = HandicapRecord(
            date: round.date,
            handicapIndex: newIndex,
            differential: round.differential,
            courseName: round.courseName
        )
        userProfile.handicapHistory.append(record)

        try? modelContext?.save()
    }

    // Standard 18-hole par 72 template
    private static let standardLayout: [(par: Int, si: Int)] = [
        (4,1),(4,9),(3,13),(4,5),(5,3),(4,11),(3,17),(4,7),(5,15),
        (4,2),(4,10),(3,14),(4,6),(5,4),(4,12),(3,18),(4,8),(5,16)
    ]

    func createRoundFromGolfCourse(_ golfCourse: GolfCourse, holes: Int = 18, courseRating: Double = 72.0, slopeRating: Int = 113) -> Round {
        let round = Round(
            courseId: golfCourse.id,
            courseName: golfCourse.name,
            teeId: "default",
            teeName: "Tees Brancos",
            courseRating: courseRating,
            slopeRating: slopeRating
        )

        let layout = Array(Self.standardLayout.prefix(holes))
        for (index, hole) in layout.enumerated() {
            let score = HoleScore(
                holeNumber: index + 1,
                par: hole.par,
                strokeIndex: hole.si,
                grossScore: hole.par
            )
            round.holeScores.append(score)
        }

        modelContext?.insert(round)
        try? modelContext?.save()
        return round
    }

    func createRound(course: Course, tee: Tee) -> Round {
        let round = Round(
            courseId: course.id,
            courseName: course.name,
            teeId: tee.id,
            teeName: tee.name,
            courseRating: tee.courseRating,
            slopeRating: tee.slopeRating
        )

        let sortedHoles = tee.holes.sorted { $0.number < $1.number }
        for holeData in sortedHoles {
            let score = HoleScore(
                holeNumber: holeData.number,
                par: holeData.par,
                strokeIndex: holeData.strokeIndex,
                grossScore: holeData.par // default to par
            )
            round.holeScores.append(score)
        }

        modelContext?.insert(round)
        try? modelContext?.save()
        return round
    }
}
