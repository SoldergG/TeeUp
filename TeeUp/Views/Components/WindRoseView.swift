import SwiftUI

struct WindRoseView: View {
    let direction: WindDirection
    let strength: WindStrength

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)

            // Cardinal points
            ForEach(WindDirection.allCases.filter { $0 != .none }, id: \.self) { dir in
                Text(dir.rawValue)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
                    .offset(y: -32)
                    .rotationEffect(.degrees(dir.angle))
            }

            // Arrow
            if direction != .none {
                Image(systemName: "arrow.up")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(arrowColor)
                    .rotationEffect(.degrees(direction.angle))
            } else {
                Image(systemName: "minus")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var arrowColor: Color {
        switch strength {
        case .calm: return .gray
        case .light: return .blue.opacity(0.6)
        case .moderate: return .blue
        case .strong: return .orange
        case .veryStrong: return .red
        }
    }
}
