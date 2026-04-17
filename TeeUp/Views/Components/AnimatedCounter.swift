import SwiftUI

struct AnimatedCounter: View {
    let value: Int
    var font: Font = .title.bold().monospacedDigit()
    var color: Color = AppTheme.primaryGreen

    var body: some View {
        Text("\(value)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: value))
            .animation(.spring(duration: 0.3), value: value)
    }
}

// MARK: - Score Counter (with +/- and par color)
struct ScoreCounter: View {
    @Binding var score: Int
    let par: Int
    var minScore: Int = 1
    var maxScore: Int = 15

    private var toPar: Int { score - par }

    var body: some View {
        HStack(spacing: 16) {
            Button {
                guard score > minScore else { return }
                score -= 1
                if UserDefaults.standard.hapticFeedbackEnabled { Haptics.light() }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(score > minScore ? AppTheme.primaryGreen : .gray.opacity(0.3))
            }
            .disabled(score <= minScore)

            VStack(spacing: 2) {
                AnimatedCounter(
                    value: score,
                    font: .system(size: 32, weight: .bold, design: .rounded).monospacedDigit(),
                    color: GolfFormatters.scoreColor(for: toPar)
                )

                Text(GolfFormatters.parLabelPT(for: toPar))
                    .font(.caption2.bold())
                    .foregroundStyle(GolfFormatters.scoreColor(for: toPar))
            }
            .frame(minWidth: 60)

            Button {
                guard score < maxScore else { return }
                score += 1
                if UserDefaults.standard.hapticFeedbackEnabled { Haptics.light() }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(score < maxScore ? AppTheme.primaryGreen : .gray.opacity(0.3))
            }
            .disabled(score >= maxScore)
        }
    }
}
