import SwiftUI

struct SectionHeader: View {
    let title: String
    var icon: String?
    var trailing: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.primaryGreen)
            }
            Text(title)
                .font(.headline)

            Spacer()

            if let trailing, let action {
                Button(action: action) {
                    Text(trailing)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryGreen)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Divider with text
struct DividerWithText: View {
    let text: String
    var color: Color = .secondary.opacity(0.3)

    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(color).frame(height: 1)
            Text(text).font(.caption).foregroundStyle(.secondary)
            Rectangle().fill(color).frame(height: 1)
        }
    }
}
