import SwiftUI
import SwiftData

struct StartRoundView: View {
    @Bindable var viewModel: RoundsViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.name) private var courses: [Course]

    @State private var searchText = ""
    @State private var selectedCourse: Course?
    @State private var selectedTee: Tee?

    private var filteredCourses: [Course] {
        if searchText.isEmpty { return courses }
        return courses.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.region.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let course = selectedCourse {
                    teeSelection(for: course)
                } else {
                    courseSelection
                }
            }
            .navigationTitle("Nova Ronda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Course Selection
    private var courseSelection: some View {
        List {
            ForEach(filteredCourses) { course in
                Button {
                    selectedCourse = course
                    selectedTee = course.tees.first
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("\(course.region) · \(course.totalHoles) buracos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if course.averageRating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(AppTheme.accentGold)
                                Text(String(format: "%.1f", course.averageRating))
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Pesquisar campo...")
    }

    // MARK: - Tee Selection
    private func teeSelection(for course: Course) -> some View {
        VStack(spacing: 20) {
            // Course info
            VStack(spacing: 8) {
                Text(course.name)
                    .font(.title2.bold())
                Text("\(course.region) · \(course.totalHoles) buracos · Par \(course.totalPar)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            // Tees
            Text("Selecionar Tees")
                .font(.headline)

            if course.tees.isEmpty {
                Text("Nenhum tee disponível")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(course.tees) { tee in
                    Button {
                        selectedTee = tee
                    } label: {
                        HStack {
                            Circle()
                                .fill(tee.colorEnum.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle().stroke(.primary.opacity(0.2), lineWidth: 1)
                                )

                            VStack(alignment: .leading) {
                                Text(tee.name)
                                    .font(.headline)
                                Text("CR: \(String(format: "%.1f", tee.courseRating)) · SR: \(tee.slopeRating) · \(tee.totalDistance)m")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedTee?.id == tee.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primaryGreen)
                                    .font(.title3)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                .fill(selectedTee?.id == tee.id ?
                                      AppTheme.primaryGreen.opacity(0.1) :
                                      Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                .stroke(selectedTee?.id == tee.id ?
                                        AppTheme.primaryGreen : Color.gray.opacity(0.3),
                                        lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }

            Spacer()

            // Start button
            Button {
                guard let tee = selectedTee else { return }
                viewModel.modelContext = modelContext
                let _ = viewModel.createRound(course: course, tee: tee)
                dismiss()
            } label: {
                Text("Começar Ronda")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedTee != nil ? AppTheme.primaryGreen : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
            .disabled(selectedTee == nil)
            .padding()

            // Back button
            Button("Escolher outro campo") {
                selectedCourse = nil
                selectedTee = nil
            }
            .font(.subheadline)
            .padding(.bottom)
        }
    }
}
