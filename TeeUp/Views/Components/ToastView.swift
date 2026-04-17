import SwiftUI

// MARK: - Toast Model
struct ToastItem: Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    var duration: Double = 2.5

    enum ToastType {
        case success, error, warning, info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
    }

    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: ToastItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.type.icon)
                .font(.title3)
                .foregroundStyle(toast.type.color)

            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastItem?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                ToastView(toast: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                            withAnimation(.easeOut(duration: 0.3)) { self.toast = nil }
                        }
                    }
                    .onTapGesture {
                        withAnimation { self.toast = nil }
                    }
            }
        }
        .animation(.spring(duration: 0.4), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<ToastItem?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
