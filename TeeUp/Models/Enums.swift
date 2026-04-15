import Foundation
import SwiftUI

// MARK: - Region
enum CourseRegion: String, Codable, CaseIterable, Identifiable {
    case norte = "Norte"
    case centro = "Centro"
    case lisboa = "Lisboa"
    case alentejo = "Alentejo"
    case algarve = "Algarve"
    case acores = "Açores"
    case madeira = "Madeira"
    // International
    case spain = "Espanha"
    case france = "França"
    case uk = "Reino Unido"
    case other = "Outro"

    var id: String { rawValue }
}

// MARK: - Tee Color
enum TeeColor: String, Codable, CaseIterable, Identifiable {
    case black = "Preto"
    case white = "Branco"
    case yellow = "Amarelo"
    case blue = "Azul"
    case red = "Vermelho"
    case green = "Verde"
    case gold = "Dourado"
    case ladies = "Senhoras"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .black: return .black
        case .white: return .white
        case .yellow: return .yellow
        case .blue: return .blue
        case .red: return .red
        case .green: return .green
        case .gold: return Color(hex: "C9A84C")
        case .ladies: return .pink
        }
    }
}

// MARK: - Wind
enum WindDirection: String, Codable, CaseIterable, Identifiable {
    case n = "N"
    case ne = "NE"
    case e = "E"
    case se = "SE"
    case s = "S"
    case sw = "SW"
    case w = "W"
    case nw = "NW"
    case none = "—"

    var id: String { rawValue }

    var angle: Double {
        switch self {
        case .n: return 0
        case .ne: return 45
        case .e: return 90
        case .se: return 135
        case .s: return 180
        case .sw: return 225
        case .w: return 270
        case .nw: return 315
        case .none: return 0
        }
    }
}

enum WindStrength: String, Codable, CaseIterable, Identifiable {
    case calm = "Calmo"
    case light = "Fraco"
    case moderate = "Moderado"
    case strong = "Forte"
    case veryStrong = "Muito Forte"

    var id: String { rawValue }
}

// MARK: - Fairway Hit
enum FairwayHit: String, Codable, CaseIterable, Identifiable {
    case yes = "Sim"
    case no = "Não"
    case na = "N/A"

    var id: String { rawValue }
}

// MARK: - Units
enum DistanceUnit: String, Codable, CaseIterable, Identifiable {
    case meters = "Metros"
    case yards = "Jardas"

    var id: String { rawValue }

    var abbreviation: String {
        switch self {
        case .meters: return "m"
        case .yards: return "yd"
        }
    }
}

// MARK: - Subscription
enum SubscriptionTier: String, Codable {
    case free = "Free"
    case pro = "Pro"
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
