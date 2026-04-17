import UIKit

/// Open external URLs safely
enum OpenURLHelper {
    static func openMaps(latitude: Double, longitude: Double, name: String) {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        // Try Apple Maps first
        if let url = URL(string: "maps://?ll=\(latitude),\(longitude)&q=\(encodedName)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }
        // Fallback to Google Maps web
        if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)") {
            UIApplication.shared.open(url)
        }
    }

    static func openPhone(_ number: String) {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel:\(cleaned)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    static func openWebsite(_ urlString: String) {
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    static func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
