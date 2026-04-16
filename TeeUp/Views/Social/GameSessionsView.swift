import SwiftUI

struct GameSessionsView: View {
    @Bindable var gameService: GameSessionService
    @Bindable var friendsService: FriendsService
    @Bindable var placesService: GooglePlacesService
    @State private var showCreate = false

    private var upcoming: [GameSessionDetail] {
        gameService.sessions.filter { $0.session.isUpcoming && $0.session.status != "cancelled" }
    }

    private var past: [GameSessionDetail] {
        gameService.sessions.filter { $0.session.isPast || $0.session.status == "cancelled" }
    }

    var body: some View {
        Group {
            if !gameService.isAuthenticated {
                notLoggedInView
            } else if gameService.isLoading && gameService.sessions.isEmpty {
                ProgressView("A carregar...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if gameService.sessions.isEmpty {
                emptyView
            } else {
                sessionsList
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateGameSessionView(
                gameService: gameService,
                friendsService: friendsService,
                placesService: placesService
            )
        }
        .refreshable { await gameService.fetchSessions() }
        .task { await gameService.fetchSessions() }
    }

    private var notLoggedInView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2.circle")
                .font(.system(size: 56)).foregroundStyle(AppTheme.primaryGreen.opacity(0.4))
            Text("Inicia sessão para criar e gerir partidas com amigos.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "figure.golf")
                .font(.system(size: 56)).foregroundStyle(AppTheme.primaryGreen.opacity(0.4))
            Text("Nenhuma partida agendada")
                .font(.headline)
            Text("Cria uma partida e convida os teus amigos a jogar!")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button {
                showCreate = true
            } label: {
                Label("Nova Partida", systemImage: "plus.circle.fill")
                    .font(.headline).padding(.horizontal, 24).padding(.vertical, 12)
                    .background(AppTheme.primaryGreen).foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    private var sessionsList: some View {
        List {
            if !upcoming.isEmpty {
                Section("Próximas Partidas") {
                    ForEach(upcoming) { detail in
                        NavigationLink {
                            GameSessionDetailView(detail: detail, gameService: gameService)
                        } label: {
                            GameSessionRow(detail: detail)
                        }
                    }
                }
            }

            if !past.isEmpty {
                Section("Partidas Anteriores") {
                    ForEach(past) { detail in
                        NavigationLink {
                            GameSessionDetailView(detail: detail, gameService: gameService)
                        } label: {
                            GameSessionRow(detail: detail)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Session Row
struct GameSessionRow: View {
    let detail: GameSessionDetail

    var session: GameSession { detail.session }

    var statusBadge: (label: String, color: Color) {
        switch detail.myStatus {
        case "creator": return ("Criador", AppTheme.accentGold)
        case "accepted": return ("Aceite", .green)
        case "declined": return ("Recusado", .red)
        case "pending": return ("Pendente", .orange)
        default: return (session.statusDisplay, .blue)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Date block
            VStack(spacing: 2) {
                Text(dayString)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryGreen)
                Text(monthString)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 44)
            .padding(.vertical, 6)
            .background(AppTheme.primaryGreen.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.courseName)
                    .font(.headline).lineLimit(1)

                HStack(spacing: 8) {
                    Label(timeString, systemImage: "clock")
                    Label("\(detail.acceptedCount) jogadores", systemImage: "person.2")
                    if session.pricePerPerson ?? 0 > 0 {
                        Label(session.priceDisplay, systemImage: "eurosign")
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            // Status badge
            Text(statusBadge.label)
                .font(.caption2.bold())
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(statusBadge.color.opacity(0.12))
                .foregroundStyle(statusBadge.color)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private var dayString: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: session.scheduledAt)
    }

    private var monthString: String {
        let f = DateFormatter(); f.dateFormat = "MMM"; f.locale = Locale(identifier: "pt_PT")
        return f.string(from: session.scheduledAt)
    }

    private var timeString: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: session.scheduledAt)
    }
}
