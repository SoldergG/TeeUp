import SwiftUI

struct HoleInputView: View {
    @Bindable var holeScore: HoleScore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                holeHeader
                scoreSection
                statsSection
                windSection
                notesSection
            }
            .padding()
        }
    }

    // MARK: - Hole Header
    private var holeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Buraco \(holeScore.holeNumber)")
                    .font(.title.bold())
                HStack(spacing: 12) {
                    Label("Par \(holeScore.par)", systemImage: "flag.fill")
                    Label("SI \(holeScore.strokeIndex)", systemImage: "number")
                }
                .font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            // Score badge
            if holeScore.grossScore > 0 {
                VStack(spacing: 2) {
                    Text("\(holeScore.grossScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.scoreColor(for: holeScore.scoreToParValue))
                    Text(holeScore.scoreName)
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.scoreColor(for: holeScore.scoreToParValue))
                }
                .frame(width: 70)
            }
        }
        .padding()
        .background(
            holeScore.grossScore > 0
                ? AppTheme.scoreColor(for: holeScore.scoreToParValue).opacity(0.08)
                : Color(.secondarySystemBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .animation(.easeInOut(duration: 0.2), value: holeScore.grossScore)
    }

    // MARK: - Score Section (Number Grid)
    private var scoreSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Pancadas").font(.headline)
                Spacer()
                if holeScore.grossScore > 0 {
                    Text(holeScore.scoreName)
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(AppTheme.scoreColor(for: holeScore.scoreToParValue).opacity(0.15))
                        .foregroundStyle(AppTheme.scoreColor(for: holeScore.scoreToParValue))
                        .clipShape(Capsule())
                }
            }

            // Score grid 1–10
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(1...10, id: \.self) { score in
                    let toPar = score - holeScore.par
                    let isSelected = holeScore.grossScore == score
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            holeScore.grossScore = score
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(score)")
                                .font(.title3.bold())
                            Text(scoreLabel(score))
                                .font(.system(size: 8))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(isSelected ? AppTheme.scoreColor(for: toPar) : Color.gray.opacity(0.1))
                        .foregroundStyle(isSelected ? .white : (score == holeScore.par ? .primary : .secondary))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(score == holeScore.par ? AppTheme.primaryGreen.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                        .scaleEffect(isSelected ? 1.06 : 1.0)
                        .animation(.spring(duration: 0.2), value: isSelected)
                    }
                }
            }

            Divider()

            // Putts
            HStack {
                Label("Putts", systemImage: "circle.dotted").font(.headline)
                Spacer()
                StepperControl(value: $holeScore.putts, range: 0...10)
            }

            // Penalties
            HStack {
                Label("Penalidades", systemImage: "exclamationmark.triangle").font(.headline)
                Spacer()
                StepperControl(value: $holeScore.penalties, range: 0...5)
            }
        }
        .padding()
        .cardStyle()
    }

    private func scoreLabel(_ score: Int) -> String {
        let diff = score - holeScore.par
        switch diff {
        case ...(-3): return "Albatross+"
        case -2: return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Dbl"
        case 3: return "Tri"
        default: return "+\(diff)"
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 12) {
            // Fairway Hit
            HStack {
                Label("Fairway", systemImage: "arrow.up.forward").font(.headline)
                Spacer()
                Picker("", selection: Binding(
                    get: { FairwayHit(rawValue: holeScore.fairwayHit) ?? .na },
                    set: { holeScore.fairwayHit = $0.rawValue }
                )) {
                    ForEach(FairwayHit.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            Divider()
            ToggleRow(title: "Green in Regulation", icon: "circle.fill", isOn: $holeScore.gir)
            Divider()
            ToggleRow(title: "Sand Save", icon: "beach.umbrella", isOn: $holeScore.sandSave)
            Divider()
            ToggleRow(title: "Up & Down", icon: "arrow.up.right", isOn: $holeScore.upAndDown)
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Wind Section
    private var windSection: some View {
        VStack(spacing: 12) {
            Text("Vento").font(.headline).frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Direção").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: Binding(
                        get: { WindDirection(rawValue: holeScore.windDirection) ?? .none },
                        set: { holeScore.windDirection = $0.rawValue }
                    )) {
                        ForEach(WindDirection.allCases) { dir in Text(dir.rawValue).tag(dir) }
                    }
                    .pickerStyle(.menu)
                }

                VStack(spacing: 4) {
                    Text("Intensidade").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: Binding(
                        get: { WindStrength(rawValue: holeScore.windStrength) ?? .calm },
                        set: { holeScore.windStrength = $0.rawValue }
                    )) {
                        ForEach(WindStrength.allCases) { str in Text(str.rawValue).tag(str) }
                    }
                    .pickerStyle(.menu)
                }

                WindRoseView(
                    direction: WindDirection(rawValue: holeScore.windDirection) ?? .none,
                    strength: WindStrength(rawValue: holeScore.windStrength) ?? .calm
                )
                .frame(width: 60, height: 60)
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notas").font(.headline)
            TextField("Adicionar notas...", text: $holeScore.notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Stepper Control
struct StepperControl: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if value > range.lowerBound { value -= 1 }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2).foregroundStyle(AppTheme.primaryGreen)
            }

            Text("\(value)")
                .font(.title2.bold().monospacedDigit())
                .frame(minWidth: 36)

            Button {
                if value < range.upperBound { value += 1 }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2).foregroundStyle(AppTheme.primaryGreen)
            }
        }
    }
}

// MARK: - Toggle Row
struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Label(title, systemImage: icon).font(.subheadline)
            Spacer()
            Toggle("", isOn: $isOn).tint(AppTheme.primaryGreen)
        }
    }
}
