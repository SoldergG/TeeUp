import SwiftUI

struct WeatherBadge: View {
    let weather: WeatherHelper

    var body: some View {
        if let symbol = weather.symbolName {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .symbolRenderingMode(.multicolor)
                Text(weather.temperatureDisplay)
                    .font(.caption.bold())

                if let wind = weather.windSpeed, wind > 15 {
                    Divider().frame(height: 12)
                    Image(systemName: "wind")
                    Text(weather.windDisplay)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}

/// Inline weather for course cards
struct CourseWeatherTag: View {
    let temperature: String
    let symbol: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .symbolRenderingMode(.multicolor)
                .font(.caption2)
            Text(temperature)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
}
