import SwiftUI
import Charts

/// Bar chart showing distribution of scores (eagles, birdies, pars, etc.)
struct ScoreDistributionChart: View {
    let rounds: [Round]

    private var distribution: [(label: String, count: Int, color: Color)] {
        var eagles = 0, birdies = 0, pars = 0, bogeys = 0, doubles = 0, worse = 0

        for round in rounds {
            for hole in round.holeScores {
                let diff = hole.grossScore - hole.par
                switch diff {
                case ...(-2): eagles += 1
                case -1: birdies += 1
                case 0: pars += 1
                case 1: bogeys += 1
                case 2: doubles += 1
                default: worse += 1
                }
            }
        }

        return [
            ("Eagle", eagles, .indigo),
            ("Birdie", birdies, .blue),
            ("Par", pars, AppTheme.primaryGreen),
            ("Bogey", bogeys, .orange),
            ("2x Bogey", doubles, .red),
            ("Pior", worse, .red.opacity(0.6))
        ].filter { $0.count > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Distribuição de Scores")
                .font(.headline)

            Chart(distribution, id: \.label) { item in
                BarMark(
                    x: .value("Tipo", item.label),
                    y: .value("Quantidade", item.count)
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
            }
            .frame(height: 160)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}
