import SwiftUI

struct FriendsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.primaryGreen.opacity(0.5))

                VStack(spacing: 8) {
                    Text("Amigos")
                        .font(.title2.bold())
                    Text("Conecta-te com outros jogadores,\norganiza rondas e compete com amigos.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    // TODO: Sign in with Apple
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Iniciar Sessão com Apple")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
                .padding(.horizontal, 40)

                Text("As funcionalidades sociais requerem uma conta.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()
            }
            .padding()
            .navigationTitle("Amigos")
        }
    }
}
