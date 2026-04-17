import Foundation
import CoreLocation
import SwiftData

// MARK: - Google Places Course Model
struct GolfCourse: Identifiable, Hashable, Codable {
    let id: String           // Google Place ID
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String
    let phone: String
    let website: String
    let rating: Double
    let userRatingCount: Int
    let priceLevel: Int?     // 0–4
    let openNow: Bool?
    let photoReference: String?
    var distanceFromUser: Double = 0

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var distanceFormatted: String {
        distanceFromUser < 1000
            ? "\(Int(distanceFromUser)) m"
            : String(format: "%.1f km", distanceFromUser / 1000)
    }

    var priceLevelDisplay: String {
        guard let p = priceLevel else { return "" }
        return String(repeating: "€", count: p + 1)
    }

    var ratingDisplay: String {
        rating > 0 ? String(format: "%.1f", rating) : ""
    }
}

// MARK: - SwiftData Cache Model
@Model
final class CachedCourseSearch {
    var id: String               // "\(lat)_\(lon)_\(radiusKm)"
    var coursesData: Data        // JSON encoded [GolfCourse]
    var fetchedAt: Date
    var latitude: Double
    var longitude: Double
    var radiusKm: Double

    init(id: String, coursesData: Data, latitude: Double, longitude: Double, radiusKm: Double) {
        self.id = id
        self.coursesData = coursesData
        self.fetchedAt = .now
        self.latitude = latitude
        self.longitude = longitude
        self.radiusKm = radiusKm
    }

    var isExpired: Bool {
        Date().timeIntervalSince(fetchedAt) > 86400  // 24 hours
    }
}

// MARK: - Google Places Service
@Observable
final class GooglePlacesService {
    // ⚠️ Replace with your Google Places API key
    private let apiKey = "AIzaSyDxzqcOHjeb-ch9_oa8hxTPssNSdWzLwj8"
    private let baseURL = "https://places.googleapis.com/v1/places:searchNearby"

    var courses: [GolfCourse] = []
    var isLoading = false
    var errorMessage: String?
    var searchRadiusKm: Double = 50
    var modelContext: ModelContext?

    // Performance: deduplicate in-flight requests
    private var currentFetchTask: Task<Void, Never>?
    // Performance: reuse JSON coders
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - Fetch with cache + deduplication
    func fetchCourses(near coordinate: CLLocationCoordinate2D, radiusKm: Double? = nil) async {
        // Performance: cancel previous in-flight request
        currentFetchTask?.cancel()

        let radius = radiusKm ?? searchRadiusKm
        let cacheKey = cacheId(lat: coordinate.latitude, lon: coordinate.longitude, radius: radius)

        // 1. Try cache first
        if let cached = getCached(key: cacheKey) {
            courses = enrichWithDistance(cached, from: coordinate)
            return
        }

        // 2. Fetch from API (deduplicated)
        isLoading = true
        errorMessage = nil

        let task = Task {
            do {
                let fetched = try await searchGolfCourses(near: coordinate, radiusMeters: Int(radius * 1000))
                guard !Task.isCancelled else { return }
                let enriched = enrichWithDistance(fetched, from: coordinate)
                courses = enriched
                saveToCache(courses: fetched, key: cacheKey, coordinate: coordinate, radius: radius)
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = "Erro ao carregar campos: \(error.localizedDescription)"
            }
            isLoading = false
        }
        currentFetchTask = task
        await task.value
    }

    // MARK: - Google Places API call
    private func searchGolfCourses(near coordinate: CLLocationCoordinate2D, radiusMeters: Int) async throws -> [GolfCourse] {
        guard var urlComponents = URLComponents(string: baseURL) else { throw PlacesError.invalidURL }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = urlComponents.url else { throw PlacesError.invalidURL }

        let body: [String: Any] = [
            "includedTypes": ["golf_course"],
            "maxResultCount": 20,
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": coordinate.latitude,
                        "longitude": coordinate.longitude
                    ],
                    "radius": min(Double(radiusMeters), 50000)  // max 50km per request
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "places.id,places.displayName,places.location,places.formattedAddress,places.nationalPhoneNumber,places.websiteUri,places.rating,places.userRatingCount,places.priceLevel,places.currentOpeningHours,places.photos",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )

        let (data, response) = try await URLSession.golf.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            if let body = String(data: data, encoding: .utf8) {
                print("Google Places error: \(body)")
            }
            throw PlacesError.httpError
        }

        let result = try Self.decoder.decode(PlacesResponse.self, from: data)
        return result.places?.map { GolfCourse(from: $0) } ?? []
    }

    // MARK: - Cache helpers
    private func cacheId(lat: Double, lon: Double, radius: Double) -> String {
        // Round to 2 decimal places so nearby searches reuse cache
        String(format: "%.2f_%.2f_%.0f", lat, lon, radius)
    }

    private func getCached(key: String) -> [GolfCourse]? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<CachedCourseSearch>(
            predicate: #Predicate { $0.id == key }
        )
        guard let cached = try? context.fetch(descriptor).first,
              !cached.isExpired else { return nil }

        return try? Self.decoder.decode([GolfCourse].self, from: cached.coursesData)
    }

    private func saveToCache(courses: [GolfCourse], key: String, coordinate: CLLocationCoordinate2D, radius: Double) {
        guard let context = modelContext,
              let data = try? Self.encoder.encode(courses) else { return }

        // Remove old cache for same key
        let descriptor = FetchDescriptor<CachedCourseSearch>(
            predicate: #Predicate { $0.id == key }
        )
        if let old = try? context.fetch(descriptor) {
            old.forEach { context.delete($0) }
        }

        let cache = CachedCourseSearch(
            id: key,
            coursesData: data,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            radiusKm: radius
        )
        context.insert(cache)
        try? context.save()
    }

    private func enrichWithDistance(_ courses: [GolfCourse], from location: CLLocationCoordinate2D) -> [GolfCourse] {
        let userLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return courses.map { course in
            var c = course
            let courseLoc = CLLocation(latitude: course.latitude, longitude: course.longitude)
            c.distanceFromUser = userLoc.distance(from: courseLoc)
            return c
        }.sorted { $0.distanceFromUser < $1.distanceFromUser }
    }

    // MARK: - Cache invalidation
    func clearCache() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<CachedCourseSearch>()
        if let all = try? context.fetch(descriptor) {
            all.forEach { context.delete($0) }
            try? context.save()
        }
        courses = []
    }
}

// MARK: - Response Models
private struct PlacesResponse: Codable {
    let places: [PlaceResult]?
}

private struct PlaceResult: Codable {
    let id: String?
    let displayName: LocalizedText?
    let location: LatLng?
    let formattedAddress: String?
    let nationalPhoneNumber: String?
    let websiteUri: String?
    let rating: Double?
    let userRatingCount: Int?
    let priceLevel: String?
    let currentOpeningHours: OpeningHours?
    let photos: [Photo]?
}

private struct LocalizedText: Codable { let text: String? }
private struct LatLng: Codable { let latitude: Double; let longitude: Double }
private struct OpeningHours: Codable { let openNow: Bool? }
private struct Photo: Codable { let name: String? }

private extension GolfCourse {
    init(from p: PlaceResult) {
        let priceLevelMap = ["PRICE_LEVEL_FREE": 0, "PRICE_LEVEL_INEXPENSIVE": 1,
                              "PRICE_LEVEL_MODERATE": 2, "PRICE_LEVEL_EXPENSIVE": 3,
                              "PRICE_LEVEL_VERY_EXPENSIVE": 4]
        self.id = p.id ?? UUID().uuidString
        self.name = p.displayName?.text ?? "Campo de Golfe"
        self.latitude = p.location?.latitude ?? 0
        self.longitude = p.location?.longitude ?? 0
        self.address = p.formattedAddress ?? ""
        self.phone = p.nationalPhoneNumber ?? ""
        self.website = p.websiteUri ?? ""
        self.rating = p.rating ?? 0
        self.userRatingCount = p.userRatingCount ?? 0
        self.priceLevel = p.priceLevel.flatMap { priceLevelMap[$0] }
        self.openNow = p.currentOpeningHours?.openNow
        self.photoReference = p.photos?.first?.name
        self.distanceFromUser = 0
    }
}

enum PlacesError: Error {
    case invalidURL
    case httpError
}
