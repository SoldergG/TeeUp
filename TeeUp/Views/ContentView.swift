import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var roundsVM = RoundsViewModel()
    @State private var placesService = GooglePlacesService()
    @State private var locationManager = LocationManager()
    @State private var isLoggedIn = false
    @State private var hasCheckedAuth = false
    @State private var showPermissionsOnboarding = false

    var body: some View {
        Group {
            if !hasCheckedAuth {
                splashView
            } else if !isLoggedIn {
                LoginView {
                    withAnimation { isLoggedIn = true }
                }
            } else if showPermissionsOnboarding {
                PermissionsView(locationManager: locationManager) {
                    showPermissionsOnboarding = false
                }
            } else {
                mainTabView
            }
        }
        .task {
            // Check auth
            let hasUser = SupabaseManager.shared.isAuthenticated
            let hasSkipped = UserDefaults.standard.bool(forKey: "hasSkippedLogin")
            isLoggedIn = hasUser || hasSkipped
            hasCheckedAuth = true

            // Show permissions onboarding once
            if isLoggedIn && !UserDefaults.standard.bool(forKey: "hasShownPermissions") {
                showPermissionsOnboarding = true
            }
        }
    }

    // MARK: - Splash
    private var splashView: some View {
        ZStack {
            AppTheme.primaryGreen.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.white)
                Text("TeeUp")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Main Tab View
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            RoundsView(viewModel: roundsVM)
                .tabItem { Label("Rondas", systemImage: "flag.fill") }
                .tag(0)

            CoursesListView(placesService: placesService, locationManager: locationManager)
                .tabItem { Label("Campos", systemImage: "map.fill") }
                .tag(1)

            MapTabView(placesService: placesService, locationManager: locationManager)
                .tabItem { Label("Mapa", systemImage: "mappin.and.ellipse") }
                .tag(2)

            FriendsView()
                .tabItem { Label("Amigos", systemImage: "person.2.fill") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Perfil", systemImage: "person.circle.fill") }
                .tag(4)
        }
        .tint(AppTheme.primaryGreen)
        .onAppear {
            placesService.modelContext = modelContext
            roundsVM.modelContext = modelContext
            ensureUserProfile()
            UserDefaults.standard.set(true, forKey: "hasSkippedLogin")
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            guard let loc = newLocation, placesService.courses.isEmpty else { return }
            Task { await placesService.fetchCourses(near: loc.coordinate) }
        }
    }

    private func ensureUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        if profiles.isEmpty {
            modelContext.insert(UserProfile(name: "Jogador"))
            try? modelContext.save()
        }
    }
}

// MARK: - Permissions Onboarding
struct PermissionsView: View {
    let locationManager: LocationManager
    let onDone: () -> Void

    @State private var locationGranted = false
    @State private var notificationsGranted = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(AppTheme.accentGold)
                    Text("Antes de começar")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("O TeeUp precisa de algumas permissões\npara funcionar correctamente.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    PermissionRow(
                        icon: "location.fill",
                        title: "Localização",
                        description: "Para encontrar campos de golfe perto de ti",
                        isGranted: locationGranted
                    ) {
                        locationManager.requestPermission()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            locationGranted = locationManager.isAuthorized
                        }
                    }

                    PermissionRow(
                        icon: "bell.fill",
                        title: "Notificações",
                        description: "Para convites de rondas e actualizações",
                        isGranted: notificationsGranted
                    ) {
                        Task {
                            await requestNotificationPermission()
                            notificationsGranted = true
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    UserDefaults.standard.set(true, forKey: "hasShownPermissions")
                    onDone()
                } label: {
                    Text(locationGranted ? "Continuar" : "Continuar sem localização")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .foregroundStyle(AppTheme.primaryGreen)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppTheme.accentGold)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(description).font(.caption).foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            } else {
                Button("Permitir") { action() }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.15))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
