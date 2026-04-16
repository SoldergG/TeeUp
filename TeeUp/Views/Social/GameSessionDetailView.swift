import SwiftUI
import MapKit

struct GameSessionDetailView: View {
    let detail: GameSessionDetail
    @Bindable var gameService: GameSessionService
    @Environment(\.dismiss) private var dismiss

    @State private var showScoreEntry = false
    @State private var scoreInput = ""
    @State private var showCancelAlert = false
    @State private var errorMessage: String?

    var session: GameSession { detail.session }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                participantsCard
                if !detail.participants.filter({ $0.finalScore != nil }).isEmpty {
                    scoresCard
                }
                actionsCard
            }
            .padding()
        }
        .background(AppTheme.secondaryBackground)
        .navigationTitle("Partida")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScoreEntry) {
            scoreEntrySheet
        }
        .alert("Cancelar Partida", isPresented: $showCancelAlert) {
            Button("Não", role: .cancel) {}
            Button("Cancelar Partida", role: .destructive) {
                Task {
                    try? await gameService.cancelSession(sessionId: session.id)
                    dismiss()
                }
            }
        } message: {
            Text("Tens a certeza que queres cancelar esta partida?")
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 14) {
            // Status badge
            HStack {
                Spacer()
                Text(session.statusDisplay)
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }

            // Course name
            VStack(spacing: 6) {
                Image(systemName: "flag.2.crossed.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.primaryGreen)
                Text(session.courseName)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                if let addr = session.courseAddress, !addr.isEmpty {
                    Text(addr)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }

            Divider()

            // Info row
            HStack(spacing: 0) {
                infoItem(icon: "calendar", label: "Data", value: session.scheduledDisplay)
                Divider().frame(height: 40)
                infoItem(icon: "person.2.fill", label: "Jogadores", value: "\(detail.acceptedCount)")
                Divider().frame(height: 40)
                infoItem(icon: "eurosign.circle", label: "Preço", value: session.priceDisplay)
            }

            // Go to course button
            if let lat = session.courseLat, let lng = session.courseLng {
                Button {
                    let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lng)")!
                    UIApplication.shared.open(url)
                } label: {
                    Label("Como Chegar", systemImage: "car.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.primaryGreen.opacity(0.1))
                        .foregroundStyle(AppTheme.primaryGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
        .padding()
        .cardStyle()
    }

    private func infoItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(AppTheme.primaryGreen)
            Text(value).font(.subheadline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusColor: Color {
        switch session.status {
        case "confirmed": return .green
        case "cancelled": return .red
        case "completed": return AppTheme.accentGold
        default: return .blue
        }
    }

    // MARK: - Participants Card
    private var participantsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Participantes")
                .font(.headline)

            // Creator
            if let creator = detail.creatorProfile ?? SessionParticipant(
                id: "", sessionId: "", userId: session.creatorId,
                status: "creator", finalScore: nil, finalDifferential: nil,
                createdAt: Date()
            ).profile {
                participantRow(
                    name: creator.displayName,
                    handicap: creator.handicapDisplay,
                    statusIcon: "crown.fill",
                    statusColor: AppTheme.accentGold,
                    statusLabel: "Criador"
                )
            } else {
                participantRow(
                    name: "Criador",
                    handicap: "—",
                    statusIcon: "crown.fill",
                    statusColor: AppTheme.accentGold,
                    statusLabel: "Criador"
                )
            }

            if !detail.participants.isEmpty {
                Divider()
            }

            ForEach(Array(detail.participants.enumerated()), id: \.element.id) { index, participant in
                participantRow(
                    name: participant.profile?.displayName ?? "Jogador",
                    handicap: participant.profile?.handicapDisplay ?? "—",
                    statusIcon: participant.statusIcon,
                    statusColor: statusColorFor(participant.status),
                    statusLabel: statusLabelFor(participant.status)
                )
                if index < detail.participants.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private func participantRow(name: String, handicap: String, statusIcon: String, statusColor: Color, statusLabel: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text(String(name.prefix(1)).uppercased())
                    .font(.subheadline.bold())
                    .foregroundStyle(statusColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.bold())
                Text("HCP \(handicap)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: statusIcon).font(.caption).foregroundStyle(statusColor)
                Text(statusLabel).font(.caption.bold()).foregroundStyle(statusColor)
            }
        }
    }

    private func statusColorFor(_ status: String) -> Color {
        switch status {
        case "accepted": return .green
        case "declined": return .red
        default: return .orange
        }
    }

    private func statusLabelFor(_ status: String) -> String {
        switch status {
        case "accepted": return "Aceite"
        case "declined": return "Recusado"
        default: return "Pendente"
        }
    }

    // MARK: - Scores Card
    private var scoresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resultados")
                .font(.headline)

            let scored = detail.participants
                .filter { $0.finalScore != nil }
                .sorted { ($0.finalScore ?? 0) < ($1.finalScore ?? 0) }

            ForEach(Array(scored.enumerated()), id: \.element.id) { index, p in
                HStack {
                    Text("\(index + 1).")
                        .font(.headline)
                        .foregroundStyle(index == 0 ? AppTheme.accentGold : .secondary)
                        .frame(width: 24)

                    Text(p.profile?.displayName ?? "Jogador")
                        .font(.subheadline)

                    Spacer()

                    if let score = p.finalScore {
                        Text("\(score)")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryGreen)
                    }

                    if let diff = p.finalDifferential {
                        Text(String(format: "(%.1f)", diff))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if index < scored.count - 1 { Divider() }
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Actions Card
    private var actionsCard: some View {
        VStack(spacing: 10) {
            // Pending invite: accept/decline
            if detail.myStatus == "pending" {
                HStack(spacing: 12) {
                    Button {
                        Task { try? await gameService.respondToSession(sessionId: session.id, accept: false) }
                    } label: {
                        Text("Recusar")
                            .font(.headline).frame(maxWidth: .infinity).padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    }
                    Button {
                        Task { try? await gameService.respondToSession(sessionId: session.id, accept: true) }
                    } label: {
                        Text("Aceitar")
                            .font(.headline).frame(maxWidth: .infinity).padding()
                            .background(AppTheme.primaryGreen)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    }
                }
            }

            // Accepted: submit score
            if (detail.myStatus == "accepted" || detail.isCreator),
               session.status == "open" || session.status == "confirmed" {
                Button {
                    showScoreEntry = true
                } label: {
                    Label("Submeter Score", systemImage: "flag.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(AppTheme.accentGold)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
            }

            // Creator: cancel
            if detail.isCreator && session.status == "open" {
                Button(role: .destructive) {
                    showCancelAlert = true
                } label: {
                    Text("Cancelar Partida")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }

            if let err = errorMessage {
                Text(err).font(.caption).foregroundStyle(.red)
            }
        }
    }

    // MARK: - Score Entry Sheet
    private var scoreEntrySheet: some View {
        NavigationStack {
            Form {
                Section("O teu score total") {
                    TextField("Ex: 78", text: $scoreInput)
                        .keyboardType(.numberPad)
                        .font(.title2)
                }
                Section {
                    Text("Introduz o número total de pancadas na ronda.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Submeter Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showScoreEntry = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submeter") {
                        guard let score = Int(scoreInput) else { return }
                        Task {
                            try? await gameService.submitScore(
                                sessionId: session.id,
                                score: score,
                                differential: 0
                            )
                            showScoreEntry = false
                        }
                    }
                    .disabled(Int(scoreInput) == nil)
                }
            }
        }
        .presentationDetents([.height(260)])
    }
}
