import SwiftUI

struct FriendsView: View {
    @Bindable var service: FriendsService
    @Bindable var gameService: GameSessionService
    @Bindable var placesService: GooglePlacesService
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var errorAlert: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("Amigos").tag(0)
                    Text("Partidas").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if selectedTab == 0 {
                    Group {
                        if !service.isAuthenticated {
                            notLoggedInView
                        } else {
                            mainContent
                        }
                    }
                } else {
                    GameSessionsView(
                        gameService: gameService,
                        friendsService: service,
                        placesService: placesService
                    )
                }
            }
            .navigationTitle(selectedTab == 0 ? "Amigos" : "Partidas")
            .toolbar {
                if selectedTab == 0 && service.isAuthenticated {
                    ToolbarItem(placement: .topBarTrailing) {
                        if service.isLoading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Button {
                                Task { await service.fetchAll() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
                }
            }
            .task {
                if service.isAuthenticated {
                    await service.fetchAll()
                }
            }
            .alert("Erro", isPresented: Binding(
                get: { errorAlert != nil },
                set: { if !$0 { errorAlert = nil } }
            )) {
                Button("OK") { errorAlert = nil }
            } message: {
                if let err = errorAlert { Text(err) }
            }
        }
    }

    // MARK: - Not Logged In
    private var notLoggedInView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.primaryGreen.opacity(0.5))
            VStack(spacing: 8) {
                Text("Funcionalidades Sociais")
                    .font(.title2.bold())
                Text("Inicia sessão para adicionar amigos,\ncompartilhar rondas e competir.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Pesquisar jogadores...", text: $searchText)
                        .autocorrectionDisabled()
                        .onSubmit { Task { await service.search(query: searchText) } }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if !searchText.isEmpty {
                    Button("Cancelar") {
                        searchText = ""
                        service.searchResults = []
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.subheadline)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
            .onChange(of: searchText) { _, q in
                Task { await service.search(query: q) }
            }

            if !searchText.isEmpty {
                searchResultsList
            } else {
                friendsList
            }
        }
    }

    // MARK: - Search Results
    private var searchResultsList: some View {
        List {
            if service.searchResults.isEmpty && !searchText.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "person.slash")
                            .font(.title2).foregroundStyle(.secondary)
                        Text("Nenhum jogador encontrado")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding()
                    .listRowBackground(Color.clear)
                }
            } else {
                Section("Resultados") {
                    ForEach(service.searchResults) { profile in
                        SearchResultRow(
                            profile: profile,
                            isFriend: service.isFriend(profile.id),
                            isPending: service.hasPendingSent(to: profile.id)
                        ) {
                            Task {
                                do {
                                    try await service.sendRequest(to: profile.id)
                                } catch {
                                    errorAlert = error.localizedDescription
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Friends List
    private var friendsList: some View {
        List {
            // Pending incoming requests
            if !service.pendingIncoming.isEmpty {
                Section {
                    ForEach(service.pendingIncoming, id: \.friendship.id) { item in
                        PendingRequestRow(
                            profile: item.profile,
                            onAccept: {
                                Task {
                                    do { try await service.acceptRequest(friendshipId: item.friendship.id) }
                                    catch { errorAlert = error.localizedDescription }
                                }
                            },
                            onReject: {
                                Task {
                                    do { try await service.rejectRequest(friendshipId: item.friendship.id) }
                                    catch { errorAlert = error.localizedDescription }
                                }
                            }
                        )
                    }
                } header: {
                    Label("Pedidos de Amizade (\(service.pendingIncoming.count))", systemImage: "person.badge.plus")
                        .foregroundStyle(AppTheme.primaryGreen)
                }
            }

            // Friends
            if service.friends.isEmpty && !service.isLoading {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 44))
                            .foregroundStyle(AppTheme.primaryGreen.opacity(0.3))
                        Text("Ainda não tens amigos")
                            .font(.headline)
                        Text("Pesquisa pelo nome ou username de outros jogadores para os adicionar.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                }
            } else if !service.friends.isEmpty {
                Section("Amigos (\(service.friends.count))") {
                    ForEach(service.friends) { item in
                        FriendRow(item: item)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        do { try await service.removeFriend(item: item) }
                                        catch { errorAlert = error.localizedDescription }
                                    }
                                } label: {
                                    Label("Remover", systemImage: "person.fill.xmark")
                                }
                            }
                    }
                }
            }

            // Pending sent
            if !service.pendingSent.isEmpty {
                Section("Pedidos Enviados") {
                    ForEach(service.pendingSent) { friendship in
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.orange)
                                .frame(width: 32)
                            Text("Pedido pendente")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Cancelar") {
                                Task {
                                    do { try await service.cancelRequest(friendshipId: friendship.id) }
                                    catch { errorAlert = error.localizedDescription }
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await service.fetchAll() }
    }
}

// MARK: - Friend Row
struct FriendRow: View {
    let item: FriendItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGreen.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(String(item.profile.displayName.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.profile.displayName)
                    .font(.headline)
                if let username = item.profile.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.profile.handicapDisplay)
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.primaryGreen)
                Text("HCP")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pending Request Row
struct PendingRequestRow: View {
    let profile: FriendProfile?
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentGold.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(String((profile?.displayName ?? "?").prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(AppTheme.accentGold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(profile?.displayName ?? "Jogador")
                    .font(.headline)
                Text("HCP \(profile?.handicapDisplay ?? "—")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onReject) {
                    Image(systemName: "xmark")
                        .font(.subheadline.bold())
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(Circle())
                }

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.subheadline.bold())
                        .frame(width: 36, height: 36)
                        .background(AppTheme.primaryGreen.opacity(0.15))
                        .foregroundStyle(AppTheme.primaryGreen)
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let profile: FriendProfile
    let isFriend: Bool
    let isPending: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(String(profile.displayName.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.displayName).font(.headline)
                if let username = profile.username, !username.isEmpty {
                    Text("@\(username)").font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isFriend {
                Label("Amigos", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.primaryGreen)
            } else if isPending {
                Text("Enviado")
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            } else {
                Button(action: onAdd) {
                    Label("Adicionar", systemImage: "person.badge.plus")
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(AppTheme.primaryGreen)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
