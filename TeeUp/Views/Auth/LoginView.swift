import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentNonce: String?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onLoginSuccess: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Image(systemName: "flag.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                    }

                    Text("TeeUp")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("O teu companheiro de golfe")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                // Features preview
                VStack(spacing: 12) {
                    FeatureRow(icon: "map.fill", text: "Descobre campos perto de ti")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Acompanha o teu handicap WHS")
                    FeatureRow(icon: "flag.2.crossed.fill", text: "Regista rondas buraco a buraco")
                    FeatureRow(icon: "person.2.fill", text: "Joga com amigos")
                }
                .padding(.horizontal, 24)

                Spacer()

                // Login buttons
                VStack(spacing: 14) {
                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Sign in with Google (via Supabase OAuth)
                    Button {
                        Task { await signInWithGoogle() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)
                            Text("Continuar com Google")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Skip (continue without account)
                    Button {
                        onLoginSuccess()
                    } label: {
                        Text("Continuar sem conta")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                if isLoading {
                    ProgressView()
                        .tint(.white)
                }

                Spacer()
                    .frame(height: 20)
            }
        }
    }

    // MARK: - Apple Sign In

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Erro na autenticação Apple"
                return
            }

            isLoading = true
            Task {
                do {
                    try await SupabaseManager.shared.signInWithApple(idToken: idToken, nonce: nonce)
                    await MainActor.run {
                        isLoading = false
                        onLoginSuccess()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Erro: \(error.localizedDescription)"
                    }
                }
            }

        case .failure(let error):
            errorMessage = "Apple Sign In falhou: \(error.localizedDescription)"
        }
    }

    // MARK: - Google Sign In (via Supabase OAuth)

    private func signInWithGoogle() async {
        isLoading = true
        do {
            try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "teeup://auth/callback")
            )
            await MainActor.run {
                isLoading = false
                onLoginSuccess()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Google Sign In falhou: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 28)
                .foregroundStyle(AppTheme.accentGold)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }
}
