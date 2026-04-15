import SwiftUI

enum AppTheme {
    static let primaryGreen = Color(hex: "1B4D2E")
    static let accentGold = Color(hex: "C9A84C")
    static let lightGreen = Color(hex: "2D7A4A")
    static let darkGreen = Color(hex: "0F2E1A")
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)

    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 10
    static let cardShadowRadius: CGFloat = 4
    static let cardShadowY: CGFloat = 2

    static let birdie = Color.blue
    static let eagle = Color.indigo
    static let par = Color.green
    static let bogey = Color.orange
    static let doubleBogey = Color.red
    static let worse = Color.red.opacity(0.8)

    static func scoreColor(for scoreToPar: Int) -> Color {
        switch scoreToPar {
        case ...(-2): return eagle
        case -1: return birdie
        case 0: return par
        case 1: return bogey
        case 2: return doubleBogey
        default: return worse
        }
    }
}

// MARK: - Card Modifier
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: AppTheme.cardShadowRadius, y: AppTheme.cardShadowY)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
