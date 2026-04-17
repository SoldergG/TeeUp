import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Pesquisar..."
    var onSubmit: (() -> Void)?
    var onCancel: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField(placeholder, text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .onSubmit { onSubmit?() }

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if isFocused || !text.isEmpty {
                Button("Cancelar") {
                    text = ""
                    isFocused = false
                    onCancel?()
                }
                .font(.subheadline)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}
