import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var roundsVM = RoundsViewModel()
    @State private var overpassService = OverpassService()
    @State private var locationManager = LocationManager()
    @State private var isLoggedIn = false
    @State private var hasCheckedAuth = false

    var body: some View {
        Group {
            if !hasCheckedAuth {
                // Splash
                ZStack {
                    AppTheme.primaryGreen.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                        Text("TeeUp")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
            } else if !isLoggedIn {
                LoginView {
                    withAnimation { isLoggedIn = true }
                }
            } else {
                mainTabView
            }
        }
        .task {
            locationManager.requestPermission()
            // Check if user is already logged in or skipped
            let hasUser = SupabaseManager.shared.isAuthenticated
            let hasSkipped = UserDefaults.standard.bool(forKey: "hasSkippedLogin")
            isLoggedIn = hasUser || hasSkipped
            if !isLoggedIn {
                // Save skip preference when they continue without account
            }
            hasCheckedAuth = true
        }
    }

    // MARK: - Main Tab View
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            RoundsView(viewModel: roundsVM)
                .tabItem {
                    Label("Rondas", systemImage: "flag.fill")
                }
                .tag(0)

            CoursesListView(overpassService: overpassService, locationManager: locationManager)
                .tabItem {
                    Label("Campos", systemImage: "map.fill")
                }
                .tag(1)

            MapTabView(overpassService: overpassService, locationManager: locationManager)
                .tabItem {
                    Label("Mapa", systemImage: "mappin.and.ellipse")
                }
                .tag(2)

            FriendsView()
                .tabItem {
                    Label("Amigos", systemImage: "person.2.fill")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.circle.fill")
                }
                .tag(4)
        }
        .tint(AppTheme.primaryGreen)
        .onAppear {
            roundsVM.modelContext = modelContext
            ensureUserProfile()
            UserDefaults.standard.set(true, forKey: "hasSkippedLogin")
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            if let loc = newLocation, overpassService.courses.isEmpty {
                Task {
                    await overpassService.fetchCourses(near: loc.coordinate)
                }
            }
        }
    }

    private func ensureUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        if profiles.isEmpty {
            let profile = UserProfile(name: "Jogador")
            modelContext.insert(profile)
            try? modelContext.save()
        }
    }
}
