import SwiftUI
import SwiftData

struct StartRoundView: View {
    @Bindable var viewModel: RoundsViewModel
    @Bindable var placesService: GooglePlacesService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.name) private var savedCourses: [Course]

    @State private var searchText = ""
    @State private var selectedCourse: Course?
    @State private var selectedTee: Tee?
    @State private var selectedPlacesCourse: GolfCourse?
    @State private var showConfigureSheet = false
    @State private var navigateToScorecard: Round?
    @State private var showScorecard = false

    private var filteredPlacesCourses: [GolfCourse] {
        guard !searchText.isEmpty else { return placesService.courses }
        return placesService.courses.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredSavedCourses: [Course] {
        guard !searchText.isEmpty else { return savedCourses }
        return savedCourses.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let course = selectedCourse {
                    teeSelectionView(for: course)
                } else {
                    coursePickerView
                }
            }
            .navigationTitle("Nova Ronda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showConfigureSheet) {
                if let places = selectedPlacesCourse {
                    ConfigureRoundSheet(course: places) { round in
                        showConfigureSheet = false
                        navigateToScorecard = round
                        showScorecard = true
                    } onCancel: {
                        showConfigureSheet = false
                        selectedPlacesCourse = nil
                    }
                    .environmentObject(ViewModelWrapper(vm: viewModel))
                }
            }
            .fullScreenCover(isPresented: $showScorecard) {
                if let round = navigateToScorecard {
                    NavigationStack {
                        ScorecardView(round: round, viewModel: viewModel)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Fechar") {
                                        showScorecard = false
                                        dismiss()
                                    }
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: - Course Picker
    private var coursePickerView: some View {
        List {
            // Nearby courses from Google Places
            if !filteredPlacesCourses.isEmpty {
                Section {
                    ForEach(filteredPlacesCourses) { course in
                        PlacesCourseRow(course: course) {
                            selectedPlacesCourse = course
                            showConfigureSheet = true
                        }
                    }
                } header: {
                    Label("Campos Próximos", systemImage: "location.fill")
                }
            } else if placesService.isLoading {
                Section {
                    HStack {
                        ProgressView().scaleEffect(0.8)
                        Text("A procurar campos...").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                }
            } else if placesService.courses.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "location.slash")
                            .font(.title2).foregroundStyle(.secondary)
                        Text("Nenhum campo próximo encontrado")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }
            }

            // Saved courses from SwiftData
            if !filteredSavedCourses.isEmpty {
                Section("Os Meus Campos") {
                    ForEach(filteredSavedCourses) { course in
                        Button {
                            selectedCourse = course
                            selectedTee = course.tees.first
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(course.name).font(.headline).foregroundStyle(.primary)
                                    Text("\(course.region) · \(course.totalHoles) buracos")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Pesquisar campo...")
        .listStyle(.insetGrouped)
    }

    // MARK: - Tee Selection (saved courses)
    private func teeSelectionView(for course: Course) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(course.name).font(.title2.bold()).multilineTextAlignment(.center)
                Text("\(course.region) · \(course.totalHoles) buracos · Par \(course.totalPar)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.top)

            Text("Selecionar Tees").font(.headline)

            if course.tees.isEmpty {
                Text("Nenhum tee disponível").foregroundStyle(.secondary)
            } else {
                ForEach(course.tees) { tee in
                    Button {
                        selectedTee = tee
                    } label: {
                        HStack {
                            Circle().fill(tee.colorEnum.color)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(.primary.opacity(0.2), lineWidth: 1))
                            VStack(alignment: .leading) {
                                Text(tee.name).font(.headline)
                                Text("CR: \(String(format: "%.1f", tee.courseRating)) · SR: \(tee.slopeRating)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedTee?.id == tee.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primaryGreen).font(.title3)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                .fill(selectedTee?.id == tee.id ? AppTheme.primaryGreen.opacity(0.1) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                                .stroke(selectedTee?.id == tee.id ? AppTheme.primaryGreen : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }

            Spacer()

            Button {
                guard let tee = selectedTee else { return }
                viewModel.modelContext = modelContext
                let round = viewModel.createRound(course: course, tee: tee)
                navigateToScorecard = round
                showScorecard = true
            } label: {
                Text("Começar Ronda")
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(selectedTee != nil ? AppTheme.primaryGreen : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
            .disabled(selectedTee == nil)
            .padding()

            Button("Escolher outro campo") {
                selectedCourse = nil; selectedTee = nil
            }
            .font(.subheadline).padding(.bottom)
        }
    }
}

// MARK: - Places Course Row
struct PlacesCourseRow: View {
    let course: GolfCourse
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.primaryGreen.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "flag.fill")
                        .foregroundStyle(AppTheme.primaryGreen)
                        .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(course.name).font(.headline).foregroundStyle(.primary).lineLimit(1)
                    HStack(spacing: 8) {
                        Text(course.distanceFormatted).font(.caption).foregroundStyle(.secondary)
                        if course.rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill").foregroundStyle(AppTheme.accentGold)
                                Text(course.ratingDisplay)
                            }
                            .font(.caption2)
                        }
                    }
                }

                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Configure Round Sheet
struct ConfigureRoundSheet: View {
    let course: GolfCourse
    let onStart: (Round) -> Void
    let onCancel: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var vmWrapper: ViewModelWrapper

    @State private var courseRating: Double = 72.0
    @State private var slopeRating: Int = 113
    @State private var holeCount: Int = 18
    @State private var isStarting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Course header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primaryGreen.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: "flag.2.crossed.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(AppTheme.primaryGreen)
                        }
                        Text(course.name)
                            .font(.title3.bold())
                            .multilineTextAlignment(.center)
                        if !course.address.isEmpty {
                            Text(course.address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primaryGreen.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))

                    // Holes picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Número de Buracos")
                            .font(.headline)
                        HStack(spacing: 12) {
                            ForEach([9, 18], id: \.self) { n in
                                Button {
                                    holeCount = n
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("\(n)")
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                        Text("buracos")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(holeCount == n ? AppTheme.primaryGreen : Color.gray.opacity(0.1))
                                    .foregroundStyle(holeCount == n ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                                }
                            }
                        }
                    }

                    // Course Rating + Slope
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Dados do Campo (opcional)")
                            .font(.headline)

                        HStack {
                            Text("Course Rating")
                                .font(.subheadline)
                            Spacer()
                            HStack(spacing: 12) {
                                Button { courseRating = max(60, courseRating - 0.1) } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3).foregroundStyle(AppTheme.primaryGreen)
                                }
                                Text(String(format: "%.1f", courseRating))
                                    .font(.headline.monospacedDigit())
                                    .frame(minWidth: 44)
                                Button { courseRating = min(80, courseRating + 0.1) } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3).foregroundStyle(AppTheme.primaryGreen)
                                }
                            }
                        }

                        HStack {
                            Text("Slope Rating")
                                .font(.subheadline)
                            Spacer()
                            HStack(spacing: 12) {
                                Button { slopeRating = max(55, slopeRating - 1) } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3).foregroundStyle(AppTheme.primaryGreen)
                                }
                                Text("\(slopeRating)")
                                    .font(.headline.monospacedDigit())
                                    .frame(minWidth: 44)
                                Button { slopeRating = min(155, slopeRating + 1) } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3).foregroundStyle(AppTheme.primaryGreen)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))

                    // Start button
                    Button {
                        isStarting = true
                        vmWrapper.vm.modelContext = modelContext
                        let round = vmWrapper.vm.createRoundFromGolfCourse(
                            course,
                            holes: holeCount,
                            courseRating: courseRating,
                            slopeRating: slopeRating
                        )
                        onStart(round)
                    } label: {
                        Group {
                            if isStarting {
                                ProgressView().tint(.white)
                            } else {
                                Label("Começar Ronda", systemImage: "flag.fill")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    }
                    .disabled(isStarting)
                }
                .padding()
            }
            .navigationTitle("Configurar Ronda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: onCancel)
                }
            }
        }
    }
}

// Helper to pass ViewModel through EnvironmentObject
final class ViewModelWrapper: ObservableObject {
    let vm: RoundsViewModel
    init(vm: RoundsViewModel) { self.vm = vm }
}
