import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonLabel: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.primaryGreen.opacity(0.4))
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let label = buttonLabel, let action {
                Button(action: action) {
                    Label(label, systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppTheme.primaryGreen)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }

            Spacer()
        }
    }
}
