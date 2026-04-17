import SwiftUI

/// Wraps any scroll content with a golf-themed pull-to-refresh
struct GolfRefreshableScrollView<Content: View>: View {
    let onRefresh: () async -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            content()
        }
        .refreshable { await onRefresh() }
    }
}

/// Overlay that shows a loading state with a custom golf animation
struct GolfLoadingView: View {
    @State private var rotating = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.golf")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.primaryGreen)
                .rotationEffect(.degrees(rotating ? 10 : -10))
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: rotating)

            Text("A carregar...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .onAppear { rotating = true }
    }
}
