import Foundation
import SwiftData

// MARK: - UserProfile
@Model
final class UserProfile {
    @Attribute(.unique) var id: String
    var name: String
    var username: String
    var homeCourseId: String
    var homeCourseName: String
    var handicapIndex: Double
    var subscriptionTier: String // SubscriptionTier rawValue
    var distanceUnit: String // DistanceUnit rawValue
    var roundsPlayedTotal: Int
    var bestScore: Int
    var bestScoreCourse: String

    @Relationship(deleteRule: .cascade) var handicapHistory: [HandicapRecord]

    init(
        id: String = UUID().uuidString,
        name: String = "",
        username: String = "",
        homeCourseId: String = "",
        homeCourseName: String = "",
        handicapIndex: Double = 54.0,
        subscriptionTier: String = SubscriptionTier.free.rawValue,
        distanceUnit: String = DistanceUnit.meters.rawValue,
        roundsPlayedTotal: Int = 0,
        bestScore: Int = 0,
        bestScoreCourse: String = "",
        handicapHistory: [HandicapRecord] = []
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.homeCourseId = homeCourseId
        self.homeCourseName = homeCourseName
        self.handicapIndex = handicapIndex
        self.subscriptionTier = subscriptionTier
        self.distanceUnit = distanceUnit
        self.roundsPlayedTotal = roundsPlayedTotal
        self.bestScore = bestScore
        self.bestScoreCourse = bestScoreCourse
        self.handicapHistory = handicapHistory
    }

    var isPro: Bool {
        subscriptionTier == SubscriptionTier.pro.rawValue
    }

    var unitEnum: DistanceUnit {
        DistanceUnit(rawValue: distanceUnit) ?? .meters
    }
}

// MARK: - HandicapRecord
@Model
final class HandicapRecord {
    var date: Date
    var handicapIndex: Double
    var differential: Double
    var courseName: String

    var userProfile: UserProfile?

    init(date: Date, handicapIndex: Double, differential: Double, courseName: String) {
        self.date = date
        self.handicapIndex = handicapIndex
        self.differential = differential
        self.courseName = courseName
    }
}
