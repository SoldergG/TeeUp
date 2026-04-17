import SwiftUI

struct ConfirmationOverlay: View {
    let title: String
    let message: String
    var confirmLabel: String = "Confirmar"
    var confirmRole: ButtonRole? = .destructive
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button("Cancelar") { onCancel() }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button(role: confirmRole) { onConfirm() } label: {
                    Text(confirmLabel)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(confirmRole == .destructive ? Color.red : AppTheme.primaryGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(24)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        .padding(.horizontal, 32)
    }
}

// MARK: - Confirmation modifier
extension View {
    func confirmationOverlay(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmLabel: String = "Confirmar",
        onConfirm: @escaping () -> Void
    ) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented.wrappedValue = false }

                ConfirmationOverlay(
                    title: title,
                    message: message,
                    confirmLabel: confirmLabel,
                    onConfirm: {
                        isPresented.wrappedValue = false
                        onConfirm()
                    },
                    onCancel: { isPresented.wrappedValue = false }
                )
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: isPresented.wrappedValue)
    }
}
