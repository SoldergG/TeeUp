import Foundation
import WeatherKit
import CoreLocation

/// Fetches current weather for golf conditions
@Observable
final class WeatherHelper {
    var temperature: Double?
    var windSpeed: Double?
    var windDirection: String?
    var condition: String?
    var symbolName: String?
    var isLoading = false

    @MainActor
    func fetchWeather(for coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let weather = try await WeatherService.shared.weather(
                for: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )
            let current = weather.currentWeather

            temperature = current.temperature.converted(to: .celsius).value
            windSpeed = current.wind.speed.converted(to: .kilometersPerHour).value
            windDirection = compassDirection(from: current.wind.direction.converted(to: .degrees).value)
            condition = current.condition.description
            symbolName = current.symbolName
        } catch {
            print("Weather error: \(error.localizedDescription)")
        }
    }

    var temperatureDisplay: String {
        guard let t = temperature else { return "--" }
        return "\(Int(t))°C"
    }

    var windDisplay: String {
        guard let speed = windSpeed else { return "--" }
        let dir = windDirection ?? ""
        return "\(Int(speed)) km/h \(dir)"
    }

    var isGoodForGolf: Bool {
        guard let temp = temperature, let wind = windSpeed else { return true }
        return temp > 10 && temp < 38 && wind < 40
    }

    private func compassDirection(from degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((degrees + 22.5) / 45) % 8
        return directions[index]
    }
}
