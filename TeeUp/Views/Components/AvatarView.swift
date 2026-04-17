import SwiftUI

struct AvatarView: View {
    let name: String
    var size: CGFloat = 44
    var backgroundColor: Color = AppTheme.primaryGreen.opacity(0.15)
    var textColor: Color = AppTheme.primaryGreen

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)

            Text(name.initials)
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
        }
    }
}

// MARK: - Avatar with badge
struct AvatarBadgeView: View {
    let name: String
    var size: CGFloat = 44
    var badgeCount: Int = 0
    var badgeColor: Color = .red

    var body: some View {
        AvatarView(name: name, size: size)
            .overlay(alignment: .topTrailing) {
                if badgeCount > 0 {
                    Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badgeColor)
                        .clipShape(Capsule())
                        .offset(x: 4, y: -4)
                }
            }
    }
}
