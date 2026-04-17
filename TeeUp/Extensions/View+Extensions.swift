import SwiftUI
import UIKit

// MARK: - Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }

    @ViewBuilder
    func ifLet<T, Content: View>(_ optional: T?, transform: (Self, T) -> Content) -> some View {
        if let value = optional { transform(self, value) } else { self }
    }
}

// MARK: - Keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func dismissKeyboardOnTap() -> some View {
        onTapGesture { hideKeyboard() }
    }
}

// MARK: - Navigation
extension View {
    func navigationBarGreen() -> some View {
        toolbarBackground(AppTheme.primaryGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Loading Overlay
extension View {
    func loadingOverlay(_ isLoading: Bool, message: String = "A carregar...") -> some View {
        overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Shake Animation
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0
        ))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeEffect(animatableData: trigger ? 1 : 0))
    }
}

// MARK: - Glow Effect
extension View {
    func glow(color: Color = AppTheme.accentGold, radius: CGFloat = 8) -> some View {
        shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

// MARK: - Read Size
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: SizePreferenceKey.self, value: geo.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

// MARK: - Redacted Shimmer
extension View {
    func shimmer(active: Bool) -> some View {
        self.if(active) { view in
            view.redacted(reason: .placeholder)
                .overlay(ShimmerOverlay())
        }
    }
}

struct ShimmerOverlay: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(0.3), .clear],
            startPoint: .init(x: phase - 0.5, y: 0.5),
            endPoint: .init(x: phase + 0.5, y: 0.5)
        )
        .mask(Rectangle())
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 2
            }
        }
    }
}

// MARK: - Bounce on Tap
extension View {
    func bounceTap(scale: CGFloat = 0.95) -> some View {
        ButtonBounceWrapper(scale: scale) { self }
    }
}

private struct ButtonBounceWrapper<Content: View>: View {
    let scale: CGFloat
    @ViewBuilder let content: () -> Content
    @State private var pressed = false

    var body: some View {
        content()
            .scaleEffect(pressed ? scale : 1)
            .animation(.spring(duration: 0.2), value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
    }
}

// MARK: - Gradient Border
extension View {
    func gradientBorder(
        colors: [Color] = [AppTheme.primaryGreen, AppTheme.accentGold],
        lineWidth: CGFloat = 2,
        cornerRadius: CGFloat = AppTheme.cornerRadius
    ) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: lineWidth
                )
        )
    }
}
