import SwiftUI
import Charts

struct RoundSummaryView: View {
    let round: Round

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryHeader
                    scorecard
                    statsGrid
                    scoreDistributionChart
                }
                .padding()
            }
            .background(AppTheme.secondaryBackground)
            .navigationTitle("Resumo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header
    private var summaryHeader: some View {
        VStack(spacing: 8) {
            Text(round.courseName)
                .font(.title2.bold())
            Text("\(round.dateFormatted) · \(round.teeName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 30) {
                VStack {
                    Text("\(round.totalScore)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryGreen)
                    Text("Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text(round.scoreToParString)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.scoreColor(for: round.scoreToPar))
                    Text("vs Par")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if round.isCompleted {
                    VStack {
                        Text(String(format: "%.1f", round.differential))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accentGold)
                        Text("Diferencial")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Scorecard
    private var scorecard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scorecard")
                .font(.headline)

            let holes = round.holeScores.sorted { $0.holeNumber < $1.holeNumber }

            // Front 9
            if holes.count > 0 {
                scorecardSection(holes: Array(holes.prefix(min(9, holes.count))), label: "OUT")
            }

            // Back 9
            if holes.count > 9 {
                scorecardSection(holes: Array(holes.suffix(from: 9)), label: "IN")
            }
        }
        .padding()
        .cardStyle()
    }

    private func scorecardSection(holes: [HoleScore], label: String) -> some View {
        VStack(spacing: 4) {
            // Hole numbers
            HStack(spacing: 0) {
                Text("H")
                    .frame(width: 28)
                    .font(.caption2.bold())
                ForEach(holes, id: \.holeNumber) { hole in
                    Text("\(hole.holeNumber)")
                        .frame(maxWidth: .infinity)
                        .font(.caption2)
                }
                Text(label)
                    .frame(width: 32)
                    .font(.caption2.bold())
            }
            .foregroundStyle(.secondary)

            // Par
            HStack(spacing: 0) {
                Text("Par")
                    .frame(width: 28)
                    .font(.caption2)
                ForEach(holes, id: \.holeNumber) { hole in
                    Text("\(hole.par)")
                        .frame(maxWidth: .infinity)
                        .font(.caption2)
                }
                Text("\(holes.reduce(0) { $0 + $1.par })")
                    .frame(width: 32)
                    .font(.caption2.bold())
            }
            .foregroundStyle(.secondary)

            // Scores
            HStack(spacing: 0) {
                Text("S")
                    .frame(width: 28)
                    .font(.caption2.bold())
                ForEach(holes, id: \.holeNumber) { hole in
                    Text("\(hole.grossScore)")
                        .frame(maxWidth: .infinity)
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.scoreColor(for: hole.scoreToParValue))
                }
                Text("\(holes.reduce(0) { $0 + $1.grossScore })")
                    .frame(width: 32)
                    .font(.caption.bold())
            }

            // Putts
            HStack(spacing: 0) {
                Text("P")
                    .frame(width: 28)
                    .font(.caption2)
                ForEach(holes, id: \.holeNumber) { hole in
                    Text("\(hole.putts)")
                        .frame(maxWidth: .infinity)
                        .font(.caption2)
                }
                Text("\(holes.reduce(0) { $0 + $1.putts })")
                    .frame(width: 32)
                    .font(.caption2.bold())
            }
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estatísticas")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                StatCard(title: "GIR", value: String(format: "%.0f%%", round.girPercentage), icon: "scope")
                StatCard(title: "Fairways", value: String(format: "%.0f%%", round.fairwayPercentage), icon: "arrow.up.forward")
                StatCard(title: "Putts/Ronda", value: "\(round.totalPutts)", icon: "circle.dotted")
                StatCard(title: "Scrambling", value: String(format: "%.0f%%", round.scramblingPercentage), icon: "arrow.uturn.up")
                StatCard(title: "Avg Par 3", value: String(format: "%.1f", round.averageScoreForPar(3)), icon: "3.circle")
                StatCard(title: "Avg Par 4", value: String(format: "%.1f", round.averageScoreForPar(4)), icon: "4.circle")
                StatCard(title: "Avg Par 5", value: String(format: "%.1f", round.averageScoreForPar(5)), icon: "5.circle")
                StatCard(title: "Penalidades", value: "\(round.holeScores.reduce(0) { $0 + $1.penalties })", icon: "exclamationmark.triangle")
            }
        }
    }

    // MARK: - Score Distribution Chart
    private var scoreDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distribuição de Scores")
                .font(.headline)

            let distribution = scoreDistribution()
            Chart {
                ForEach(distribution, id: \.name) { item in
                    BarMark(
                        x: .value("Tipo", item.name),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
            }
            .frame(height: 180)
        }
        .padding()
        .cardStyle()
    }

    private func scoreDistribution() -> [(name: String, count: Int, color: Color)] {
        let holes = round.holeScores
        return [
            ("Eagle-", holes.filter { $0.scoreToParValue <= -2 }.count, AppTheme.eagle),
            ("Birdie", holes.filter { $0.scoreToParValue == -1 }.count, AppTheme.birdie),
            ("Par", holes.filter { $0.scoreToParValue == 0 }.count, AppTheme.par),
            ("Bogey", holes.filter { $0.scoreToParValue == 1 }.count, AppTheme.bogey),
            ("Dbl+", holes.filter { $0.scoreToParValue >= 2 }.count, AppTheme.doubleBogey),
        ]
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.primaryGreen)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}
