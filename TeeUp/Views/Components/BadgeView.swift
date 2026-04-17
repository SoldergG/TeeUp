import SwiftUI

struct BadgeView: View {
    let text: String
    var color: Color = AppTheme.primaryGreen
    var style: BadgeStyle = .filled

    enum BadgeStyle {
        case filled, outlined, subtle
    }

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(background)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(style == .outlined ? color : .clear, lineWidth: 1.5)
            )
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .filled: color
        case .outlined: Color.clear
        case .subtle: color.opacity(0.12)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled: .white
        case .outlined: color
        case .subtle: color
        }
    }
}

// MARK: - Score Badge
struct ScoreBadge: View {
    let toPar: Int

    var body: some View {
        BadgeView(
            text: GolfFormatters.parLabelPT(for: toPar),
            color: GolfFormatters.scoreColor(for: toPar),
            style: .subtle
        )
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String

    private var config: (label: String, color: Color) {
        switch status.lowercased() {
        case "active", "aceite": return ("Ativo", .green)
        case "pending", "pendente": return ("Pendente", .orange)
        case "cancelled", "cancelado": return ("Cancelado", .red)
        case "completed", "concluido": return ("Concluido", .blue)
        default: return (status.capitalized, .gray)
        }
    }

    var body: some View {
        BadgeView(text: config.label, color: config.color, style: .subtle)
    }
}
