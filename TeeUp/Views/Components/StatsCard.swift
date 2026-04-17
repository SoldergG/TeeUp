import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String
    var subtitle: String?
    var icon: String?
    var tint: Color = AppTheme.primaryGreen

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(tint)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stats Grid
struct StatsGrid: View {
    let items: [(title: String, value: String, icon: String?)]
    var columns: Int = 2

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                StatsCard(title: item.title, value: item.value, icon: item.icon)
            }
        }
    }
}
