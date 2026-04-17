import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        if !NetworkMonitor.shared.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.caption.bold())
                Text("Sem ligação à internet")
                    .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color.orange)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Modifier
struct OfflineBannerModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            OfflineBanner()
            content
        }
        .animation(.easeInOut(duration: 0.3), value: NetworkMonitor.shared.isConnected)
    }
}

extension View {
    func withOfflineBanner() -> some View {
        modifier(OfflineBannerModifier())
    }
}
