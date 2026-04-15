import Foundation
import CoreLocation

/// Fetches golf courses from OpenStreetMap via Overpass API (100% free, no API key)
@Observable
final class OverpassService {
    var courses: [OverpassCourse] = []
    var isLoading = false
    var errorMessage: String?
    var searchRadiusKm: Double = 50 // customizable radius

    private let overpassURL = "https://overpass-api.de/api/interpreter"

    /// Fetch golf courses within radius of a coordinate
    func fetchCourses(near coordinate: CLLocationCoordinate2D, radiusKm: Double? = nil) async {
        let radius = radiusKm ?? searchRadiusKm
        let radiusMeters = Int(radius * 1000)

        isLoading = true
        errorMessage = nil

        let query = """
        [out:json][timeout:30];
        (
          way["leisure"="golf_course"](around:\(radiusMeters),\(coordinate.latitude),\(coordinate.longitude));
          relation["leisure"="golf_course"](around:\(radiusMeters),\(coordinate.latitude),\(coordinate.longitude));
          node["leisure"="golf_course"](around:\(radiusMeters),\(coordinate.latitude),\(coordinate.longitude));
        );
        out center body;
        """

        guard let url = URL(string: overpassURL) else {
            errorMessage = "URL inválido"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "data=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")".data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Erro ao carregar campos"
                isLoading = false
                return
            }

            let result = try JSONDecoder().decode(OverpassResponse.self, from: data)
            let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            courses = result.elements.compactMap { element -> OverpassCourse? in
                // Get coordinates (center for ways/relations, direct for nodes)
                let lat = element.center?.lat ?? element.lat ?? 0
                let lon = element.center?.lon ?? element.lon ?? 0
                guard lat != 0, lon != 0 else { return nil }

                let name = element.tags?.name ?? element.tags?.nameEn ?? "Campo sem nome"
                let location = CLLocation(latitude: lat, longitude: lon)
                let distance = userLocation.distance(from: location)

                return OverpassCourse(
                    id: element.id,
                    name: name,
                    latitude: lat,
                    longitude: lon,
                    phone: element.tags?.phone ?? element.tags?.contactPhone ?? "",
                    website: element.tags?.website ?? element.tags?.contactWebsite ?? "",
                    address: element.tags?.fullAddress,
                    holes: element.tags?.holes,
                    par: element.tags?.par,
                    fee: element.tags?.fee,
                    operator_: element.tags?.operator_,
                    surface: element.tags?.surface,
                    distanceFromUser: distance,
                    openingHours: element.tags?.openingHours
                )
            }
            .sorted { $0.distanceFromUser < $1.distanceFromUser }

        } catch {
            errorMessage = "Erro: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Overpass API Response Models

struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

struct OverpassElement: Codable {
    let type: String
    let id: Int
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: OverpassTags?
}

struct OverpassCenter: Codable {
    let lat: Double
    let lon: Double
}

struct OverpassTags: Codable {
    let name: String?
    let nameEn: String?
    let phone: String?
    let contactPhone: String?
    let website: String?
    let contactWebsite: String?
    let holes: String?
    let par: String?
    let fee: String?
    let operator_: String?
    let surface: String?
    let openingHours: String?
    let addrStreet: String?
    let addrCity: String?
    let addrPostcode: String?
    let addrCountry: String?

    enum CodingKeys: String, CodingKey {
        case name
        case nameEn = "name:en"
        case phone
        case contactPhone = "contact:phone"
        case website
        case contactWebsite = "contact:website"
        case holes
        case par
        case fee
        case operator_ = "operator"
        case surface
        case openingHours = "opening_hours"
        case addrStreet = "addr:street"
        case addrCity = "addr:city"
        case addrPostcode = "addr:postcode"
        case addrCountry = "addr:country"
    }

    var fullAddress: String? {
        let parts = [addrStreet, addrCity, addrPostcode, addrCountry].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

// MARK: - Course Model from Overpass

struct OverpassCourse: Identifiable, Hashable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let phone: String
    let website: String
    let address: String?
    let holes: String?       // e.g., "18", "9"
    let par: String?         // e.g., "72"
    let fee: String?         // e.g., "yes", "€50-€120"
    let operator_: String?   // e.g., "Dom Pedro Golf"
    let surface: String?
    let distanceFromUser: Double // meters
    let openingHours: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var distanceFormatted: String {
        if distanceFromUser < 1000 {
            return "\(Int(distanceFromUser)) m"
        }
        return String(format: "%.1f km", distanceFromUser / 1000)
    }

    var holesCount: Int {
        Int(holes ?? "") ?? 18
    }

    var parValue: Int {
        Int(par ?? "") ?? 72
    }

    var feeDisplay: String {
        guard let fee = fee, !fee.isEmpty else { return "N/D" }
        if fee.lowercased() == "yes" { return "Pago" }
        if fee.lowercased() == "no" { return "Grátis" }
        return fee
    }
}
