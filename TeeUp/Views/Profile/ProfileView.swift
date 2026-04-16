import SwiftUI
import SwiftData
import Charts

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.name) private var profiles: [UserProfile]
    @State private var showSettings = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    handicapSection
                    statsSection
                    handicapHistoryChart
                }
                .padding()
            }
            .background(AppTheme.secondaryBackground)
            .navigationTitle("Perfil")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task {
                // Sync from Supabase
                if SupabaseManager.shared.isAuthenticated, let remote = try? await SupabaseManager.shared.fetchProfile(), let profile = profile {
                    if let n = remote.name, !n.isEmpty { profile.name = n }
                    if let u = remote.username, !u.isEmpty { profile.username = u }
                    if let h = remote.handicapIndex { profile.handicapIndex = h }
                    try? modelContext.save()
                }
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGreen.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.primaryGreen)
            }

            Text(profile?.name ?? "Jogador")
                .font(.title2.bold())

            if let username = profile?.username, !username.isEmpty {
                Text("@\(username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }

    // MARK: - Handicap Section
    private var handicapSection: some View {
        VStack(spacing: 12) {
            Text("Handicap Index")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(String(format: "%.1f", profile?.handicapIndex ?? 54.0))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryGreen)

            Text("World Handicap System")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ProfileStat(title: "Rondas", value: "\(profile?.roundsPlayedTotal ?? 0)", icon: "flag.fill")
            ProfileStat(title: "Melhor", value: profile?.bestScore ?? 0 > 0 ? "\(profile!.bestScore)" : "—", icon: "trophy.fill")
            ProfileStat(title: "Plano", value: profile?.isPro == true ? "Pro" : "Free", icon: "crown.fill")
        }
    }

    // MARK: - Handicap History Chart
    private var handicapHistoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Histórico de Handicap")
                .font(.headline)

            if let records = profile?.handicapHistory, !records.isEmpty {
                let sorted = records.sorted { $0.date < $1.date }
                Chart {
                    ForEach(Array(sorted.enumerated()), id: \.offset) { _, record in
                        LineMark(
                            x: .value("Data", record.date),
                            y: .value("HI", record.handicapIndex)
                        )
                        .foregroundStyle(AppTheme.primaryGreen)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Data", record.date),
                            y: .value("HI", record.handicapIndex)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.primaryGreen.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 200)
            } else {
                Text("Jogue rondas para ver o histórico")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Profile Stat
struct ProfileStat: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accentGold)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.name) private var profiles: [UserProfile]

    @State private var name = ""
    @State private var username = ""
    @State private var isSaving = false
    @State private var showSignOutAlert = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                Section("Perfil") {
                    TextField("Nome", text: $name)
                    TextField("Username (@...)", text: $username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Unidades") {
                    if let profile = profile {
                        Picker("Distância", selection: Binding(
                            get: { profile.unitEnum },
                            set: { profile.distanceUnit = $0.rawValue }
                        )) {
                            ForEach(DistanceUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                    }
                }

                Section("Subscrição") {
                    HStack {
                        Text("Plano Atual")
                        Spacer()
                        Text(profile?.isPro == true ? "Pro" : "Free")
                            .foregroundStyle(profile?.isPro == true ? AppTheme.accentGold : .secondary)
                    }
                    if profile?.isPro != true {
                        Button {
                            // TODO: Paywall
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill").foregroundStyle(AppTheme.accentGold)
                                Text("Atualizar para Pro").foregroundStyle(AppTheme.primaryGreen)
                            }
                        }
                    }
                }

                Section("Conta") {
                    Button("Terminar Sessão", role: .destructive) {
                        showSignOutAlert = true
                    }
                }

                Section("Sobre") {
                    HStack {
                        Text("Versão")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Definições")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveProfile()
                    } label: {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("Guardar")
                        }
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear {
                name = profile?.name ?? ""
                username = profile?.username ?? ""
            }
            .alert("Terminar Sessão", isPresented: $showSignOutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Terminar", role: .destructive) {
                    Task {
                        try? await SupabaseManager.shared.signOut()
                        UserDefaults.standard.removeObject(forKey: "hasSkippedLogin")
                        dismiss()
                    }
                }
            } message: {
                Text("Tens a certeza que queres terminar sessão?")
            }
        }
    }

    private func saveProfile() {
        isSaving = true
        // Save locally
        profile?.name = name
        profile?.username = username
        try? modelContext.save()

        // Sync to Supabase
        Task {
            if SupabaseManager.shared.isAuthenticated {
                let data = ProfileData(name: name, username: username)
                try? await SupabaseManager.shared.updateProfile(data)
            }
            isSaving = false
            dismiss()
        }
    }
}
