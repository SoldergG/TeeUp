import SwiftUI

struct RoundRow: View {
    let round: Round

    var body: some View {
        HStack(spacing: 12) {
            // Score circle
            ZStack {
                Circle()
                    .fill(AppTheme.scoreColor(for: round.scoreToPar).opacity(0.15))
                    .frame(width: 50, height: 50)
                Text("\(round.totalScore)")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.scoreColor(for: round.scoreToPar))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(round.courseName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(round.dateFormatted)
                    Text("·")
                    Text(round.teeName)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Differential
            VStack(alignment: .trailing, spacing: 4) {
                Text(round.scoreToParString)
                    .font(.headline)
                    .foregroundStyle(AppTheme.scoreColor(for: round.scoreToPar))
                if round.isCompleted {
                    Text(String(format: "%.1f", round.differential))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
