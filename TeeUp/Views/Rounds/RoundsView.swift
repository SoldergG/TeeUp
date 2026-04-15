import SwiftUI
import SwiftData
import Charts

struct RoundsView: View {
    @Bindable var viewModel: RoundsViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.name) private var profiles: [UserProfile]
    @State private var showStartRound = false

    private var userProfile: UserProfile? { profiles.first }
    private var recentRounds: [Round] { viewModel.fetchRecentRounds(limit: 20) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    handicapCard
                    startRoundButton
                    if !recentRounds.isEmpty {
                        handicapChart
                        roundsList
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .background(AppTheme.secondaryBackground)
            .navigationTitle("Rondas")
            .sheet(isPresented: $showStartRound) {
                StartRoundView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.modelContext = modelContext
            }
        }
    }

    // MARK: - Handicap Card
    private var handicapCard: some View {
        VStack(spacing: 8) {
            Text("Handicap Index")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", userProfile?.handicapIndex ?? 54.0))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryGreen)
            if let profile = userProfile {
                HStack(spacing: 16) {
                    StatBadge(label: "Rondas", value: "\(profile.roundsPlayedTotal)")
                    if profile.bestScore > 0 {
                        StatBadge(label: "Melhor", value: "\(profile.bestScore)")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal)
        .cardStyle()
    }

    // MARK: - Start Round Button
    private var startRoundButton: some View {
        Button {
            showStartRound = true
        } label: {
            Label("Iniciar Ronda", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.primaryGreen)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
    }

    // MARK: - Handicap Chart
    private var handicapChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolução do Handicap")
                .font(.headline)

            Chart {
                let completedRounds = recentRounds.filter(\.isCompleted).reversed()
                ForEach(Array(completedRounds.enumerated()), id: \.offset) { index, round in
                    LineMark(
                        x: .value("Ronda", index + 1),
                        y: .value("Diferencial", round.differential)
                    )
                    .foregroundStyle(AppTheme.primaryGreen)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Ronda", index + 1),
                        y: .value("Diferencial", round.differential)
                    )
                    .foregroundStyle(AppTheme.accentGold)
                }
            }
            .frame(height: 180)
            .chartYAxisLabel("Diferencial")
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Rounds List
    private var roundsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Últimas Rondas")
                .font(.headline)

            ForEach(recentRounds) { round in
                NavigationLink {
                    RoundSummaryView(round: round)
                } label: {
                    RoundRow(round: round)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.2.crossed")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.primaryGreen.opacity(0.5))
            Text("Nenhuma ronda registada")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Toca em \"Iniciar Ronda\" para começar")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 40)
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
