import SwiftUI

/// Reusable info row for detail views
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var tint: Color = AppTheme.primaryGreen

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

/// Tappable info row with chevron
struct InfoRowLink: View {
    let icon: String
    let label: String
    var value: String?
    var tint: Color = AppTheme.primaryGreen
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(tint)
                    .frame(width: 24)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                if let value {
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
