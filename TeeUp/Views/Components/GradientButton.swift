import SwiftUI

struct GradientButton: View {
    let title: String
    var icon: String?
    var colors: [Color] = [AppTheme.primaryGreen, AppTheme.lightGreen]
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            Haptics.medium()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    if let icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 8, y: 4)
        }
        .disabled(isLoading)
        .bounceTap()
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    var icon: String?
    var tint: Color = AppTheme.primaryGreen
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(tint.opacity(0.12))
            .foregroundStyle(tint)
            .clipShape(Capsule())
        }
        .bounceTap(scale: 0.97)
    }
}
