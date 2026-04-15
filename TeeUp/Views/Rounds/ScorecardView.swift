import SwiftUI
import SwiftData

struct ScorecardView: View {
    @Bindable var round: Round
    @Bindable var viewModel: RoundsViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.name) private var profiles: [UserProfile]
    @State private var currentHoleIndex = 0
    @State private var showSummary = false

    private var userProfile: UserProfile? { profiles.first }
    private var sortedHoles: [HoleScore] {
        round.holeScores.sorted { $0.holeNumber < $1.holeNumber }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar

            // Hole navigation
            if !sortedHoles.isEmpty {
                TabView(selection: $currentHoleIndex) {
                    ForEach(Array(sortedHoles.enumerated()), id: \.element.holeNumber) { index, hole in
                        HoleInputView(holeScore: hole)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            // Bottom bar
            bottomBar
        }
        .navigationTitle("\(round.courseName)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSummary) {
            if let profile = userProfile {
                RoundSummaryView(round: round)
                    .onAppear {
                        viewModel.modelContext = modelContext
                        viewModel.completeRound(round, userProfile: profile)
                    }
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 2) {
            ForEach(0..<sortedHoles.count, id: \.self) { i in
                let hole = sortedHoles[i]
                Rectangle()
                    .fill(holeProgressColor(hole, index: i))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func holeProgressColor(_ hole: HoleScore, index: Int) -> Color {
        if index == currentHoleIndex {
            return AppTheme.accentGold
        }
        if hole.grossScore > 0 && index < currentHoleIndex {
            return AppTheme.scoreColor(for: hole.scoreToParValue)
        }
        return Color.gray.opacity(0.3)
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack {
            // Previous
            Button {
                withAnimation { currentHoleIndex = max(0, currentHoleIndex - 1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .disabled(currentHoleIndex == 0)

            Spacer()

            // Score summary
            VStack(spacing: 2) {
                Text("Total: \(round.totalScore)")
                    .font(.headline)
                let scoreToPar = round.scoreToPar
                Text(scoreToPar == 0 ? "E" : (scoreToPar > 0 ? "+\(scoreToPar)" : "\(scoreToPar)"))
                    .font(.caption)
                    .foregroundStyle(AppTheme.scoreColor(for: scoreToPar))
            }

            Spacer()

            if currentHoleIndex < sortedHoles.count - 1 {
                // Next
                Button {
                    withAnimation { currentHoleIndex = min(sortedHoles.count - 1, currentHoleIndex + 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
            } else {
                // Finish
                Button {
                    showSummary = true
                } label: {
                    Text("Terminar")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.primaryGreen)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
