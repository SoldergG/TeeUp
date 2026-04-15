import SwiftUI

struct HoleInputView: View {
    @Bindable var holeScore: HoleScore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hole header
                holeHeader

                // Score input
                scoreSection

                // Stats toggles
                statsSection

                // Wind
                windSection

                // Notes
                notesSection
            }
            .padding()
        }
    }

    // MARK: - Hole Header
    private var holeHeader: some View {
        VStack(spacing: 4) {
            Text("Buraco \(holeScore.holeNumber)")
                .font(.title.bold())
            HStack(spacing: 16) {
                Label("Par \(holeScore.par)", systemImage: "flag.fill")
                Label("SI \(holeScore.strokeIndex)", systemImage: "number")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Score Section
    private var scoreSection: some View {
        VStack(spacing: 12) {
            // Gross Score
            HStack {
                Text("Pancadas")
                    .font(.headline)
                Spacer()
                StepperControl(value: $holeScore.grossScore, range: 1...15)
            }

            // Score name badge
            if holeScore.grossScore > 0 {
                Text(holeScore.scoreName)
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AppTheme.scoreColor(for: holeScore.scoreToParValue).opacity(0.2))
                    .foregroundStyle(AppTheme.scoreColor(for: holeScore.scoreToParValue))
                    .clipShape(Capsule())
            }

            Divider()

            // Putts
            HStack {
                Text("Putts")
                    .font(.headline)
                Spacer()
                StepperControl(value: $holeScore.putts, range: 0...10)
            }

            // Penalties
            HStack {
                Text("Penalidades")
                    .font(.headline)
                Spacer()
                StepperControl(value: $holeScore.penalties, range: 0...5)
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 12) {
            // Fairway Hit
            HStack {
                Label("Fairway", systemImage: "arrow.up.forward")
                    .font(.headline)
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

            // GIR
            ToggleRow(title: "Green in Regulation", icon: "circle.fill", isOn: $holeScore.gir)

            Divider()

            // Sand Save
            ToggleRow(title: "Sand Save", icon: "beach.umbrella", isOn: $holeScore.sandSave)

            Divider()

            // Up & Down
            ToggleRow(title: "Up & Down", icon: "arrow.up.right", isOn: $holeScore.upAndDown)
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Wind Section
    private var windSection: some View {
        VStack(spacing: 12) {
            Text("Vento")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                // Direction
                VStack(spacing: 4) {
                    Text("Direção")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: Binding(
                        get: { WindDirection(rawValue: holeScore.windDirection) ?? .none },
                        set: { holeScore.windDirection = $0.rawValue }
                    )) {
                        ForEach(WindDirection.allCases) { dir in
                            Text(dir.rawValue).tag(dir)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Strength
                VStack(spacing: 4) {
                    Text("Intensidade")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: Binding(
                        get: { WindStrength(rawValue: holeScore.windStrength) ?? .calm },
                        set: { holeScore.windStrength = $0.rawValue }
                    )) {
                        ForEach(WindStrength.allCases) { str in
                            Text(str.rawValue).tag(str)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Mini wind rose
            WindRoseView(
                direction: WindDirection(rawValue: holeScore.windDirection) ?? .none,
                strength: WindStrength(rawValue: holeScore.windStrength) ?? .calm
            )
            .frame(width: 80, height: 80)
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notas")
                .font(.headline)
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
                    .font(.title2)
                    .foregroundStyle(AppTheme.primaryGreen)
            }

            Text("\(value)")
                .font(.title2.bold().monospacedDigit())
                .frame(minWidth: 36)

            Button {
                if value < range.upperBound { value += 1 }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.primaryGreen)
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
            Label(title, systemImage: icon)
                .font(.subheadline)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(AppTheme.primaryGreen)
        }
    }
}
