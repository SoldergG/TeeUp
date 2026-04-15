import Foundation
import SwiftData

// MARK: - Course
@Model
final class Course {
    @Attribute(.unique) var id: String
    var name: String
    var region: String // CourseRegion rawValue
    var address: String
    var latitude: Double
    var longitude: Double
    var phone: String
    var website: String
    var totalHoles: Int
    var greenFeeMin: Int
    var greenFeeMax: Int
    var averageRating: Double
    var reviewCount: Int
    var isFavorite: Bool

    @Relationship(deleteRule: .cascade) var tees: [Tee]

    init(
        id: String = UUID().uuidString,
        name: String,
        region: String,
        address: String,
        latitude: Double,
        longitude: Double,
        phone: String = "",
        website: String = "",
        totalHoles: Int = 18,
        greenFeeMin: Int = 0,
        greenFeeMax: Int = 0,
        averageRating: Double = 0,
        reviewCount: Int = 0,
        isFavorite: Bool = false,
        tees: [Tee] = []
    ) {
        self.id = id
        self.name = name
        self.region = region
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.phone = phone
        self.website = website
        self.totalHoles = totalHoles
        self.greenFeeMin = greenFeeMin
        self.greenFeeMax = greenFeeMax
        self.averageRating = averageRating
        self.reviewCount = reviewCount
        self.isFavorite = isFavorite
        self.tees = tees
    }

    var regionEnum: CourseRegion {
        CourseRegion(rawValue: region) ?? .other
    }

    var totalPar: Int {
        guard let firstTee = tees.first else { return 72 }
        return firstTee.holes.reduce(0) { $0 + $1.par }
    }

    var greenFeeRange: String {
        if greenFeeMin == 0 && greenFeeMax == 0 { return "N/D" }
        if greenFeeMin == greenFeeMax { return "€\(greenFeeMin)" }
        return "€\(greenFeeMin)–€\(greenFeeMax)"
    }
}

// MARK: - Tee
@Model
final class Tee {
    @Attribute(.unique) var id: String
    var name: String
    var color: String // TeeColor rawValue
    var courseRating: Double
    var slopeRating: Int

    @Relationship(deleteRule: .cascade) var holes: [HoleData]
    var course: Course?

    init(
        id: String = UUID().uuidString,
        name: String,
        color: String,
        courseRating: Double,
        slopeRating: Int,
        holes: [HoleData] = []
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.courseRating = courseRating
        self.slopeRating = slopeRating
        self.holes = holes
    }

    var colorEnum: TeeColor {
        TeeColor(rawValue: color) ?? .white
    }

    var totalDistance: Int {
        holes.reduce(0) { $0 + $1.distanceMeters }
    }
}

// MARK: - HoleData (course definition)
@Model
final class HoleData {
    var number: Int
    var par: Int
    var strokeIndex: Int
    var distanceMeters: Int

    var tee: Tee?

    init(number: Int, par: Int, strokeIndex: Int, distanceMeters: Int) {
        self.number = number
        self.par = par
        self.strokeIndex = strokeIndex
        self.distanceMeters = distanceMeters
    }

    func distanceInUnit(_ unit: DistanceUnit) -> Int {
        switch unit {
        case .meters: return distanceMeters
        case .yards: return Int(Double(distanceMeters) * 1.09361)
        }
    }
}
