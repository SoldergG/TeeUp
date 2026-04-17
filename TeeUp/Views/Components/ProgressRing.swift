import SwiftUI

struct ProgressRing: View {
    let progress: Double // 0.0 - 1.0
    var lineWidth: CGFloat = 6
    var size: CGFloat = 60
    var trackColor: Color = Color(.systemGray5)
    var progressColor: Color = AppTheme.primaryGreen

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress.clamped(to: 0...1))
                .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Score Ring (shows score with color-coded progress)
struct ScoreRing: View {
    let score: Int
    let par: Int
    var size: CGFloat = 44

    private var toPar: Int { score - par }
    private var progress: Double {
        Double(par) / Double(max(score, 1))
    }

    var body: some View {
        ZStack {
            ProgressRing(
                progress: progress.clamped(to: 0...1),
                lineWidth: 4,
                size: size,
                progressColor: GolfFormatters.scoreColor(for: toPar)
            )

            Text("\(score)")
                .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                .foregroundStyle(GolfFormatters.scoreColor(for: toPar))
        }
    }
}
