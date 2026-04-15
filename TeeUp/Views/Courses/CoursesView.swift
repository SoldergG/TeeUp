import SwiftUI

struct CoursesListView: View {
    @Bindable var overpassService: OverpassService
    @Bindable var locationManager: LocationManager
    @State private var searchText = ""
    @State private var selectedCourse: OverpassCourse?
    @State private var showRadiusSheet = false

    private var filteredCourses: [OverpassCourse] {
        if searchText.isEmpty { return overpassService.courses }
        return overpassService.courses.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.address?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if overpassService.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("A procurar campos...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = overpassService.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Tentar novamente") {
                            refreshCourses()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if filteredCourses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "flag.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.primaryGreen.opacity(0.5))
                        Text("Nenhum campo encontrado")
                            .font(.headline)
                        Text("Aumenta o raio de pesquisa ou\nmove-te para outra localização")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Ajustar raio") {
                            showRadiusSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    coursesList
                }
            }
            .searchable(text: $searchText, prompt: "Pesquisar campos...")
            .navigationTitle("Campos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showRadiusSheet = true
                        } label: {
                            Label("Raio: \(Int(overpassService.searchRadiusKm)) km", systemImage: "circle.dashed")
                        }
                        Button {
                            refreshCourses()
                        } label: {
                            Label("Atualizar", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showRadiusSheet) {
                RadiusPickerSheet(
                    radius: $overpassService.searchRadiusKm,
                    onConfirm: { refreshCourses() }
                )
                .presentationDetents([.height(280)])
            }
            .sheet(item: $selectedCourse) { course in
                NavigationStack {
                    OverpassCourseDetailView(course: course)
                }
            }
        }
    }

    // MARK: - Courses List
    private var coursesList: some View {
        List {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundStyle(AppTheme.primaryGreen)
                Text("\(filteredCourses.count) campos num raio de \(Int(overpassService.searchRadiusKm)) km")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)

            ForEach(filteredCourses) { course in
                Button {
                    selectedCourse = course
                } label: {
                    OverpassCourseRow(course: course)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func refreshCourses() {
        guard let loc = locationManager.userLocation else {
            locationManager.requestLocation()
            return
        }
        Task {
            await overpassService.fetchCourses(near: loc.coordinate)
        }
    }
}

// MARK: - Course Row (Overpass)
struct OverpassCourseRow: View {
    let course: OverpassCourse

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.primaryGreen.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "flag.fill")
                    .foregroundStyle(AppTheme.primaryGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let holes = course.holes {
                        Text("\(holes)H")
                    }
                    if course.feeDisplay != "N/D" {
                        Text("·")
                        Text(course.feeDisplay)
                    }
                    if let addr = course.address {
                        Text("·")
                        Text(addr)
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(course.distanceFormatted)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.primaryGreen)
                if let op = course.operator_ {
                    Text(op)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Overpass Course Detail
struct OverpassCourseDetailView: View {
    let course: OverpassCourse
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "flag.2.crossed.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.primaryGreen)

                    Text(course.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        if let holes = course.holes {
                            Label("\(holes) buracos", systemImage: "flag")
                        }
                        if let par = course.par {
                            Label("Par \(par)", systemImage: "number")
                        }
                        Label(course.distanceFormatted, systemImage: "location")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .cardStyle()

                // Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Informação")
                        .font(.headline)

                    if let addr = course.address {
                        Label(addr, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                    }

                    if !course.phone.isEmpty {
                        Link(destination: URL(string: "tel:\(course.phone)")!) {
                            Label(course.phone, systemImage: "phone")
                                .font(.subheadline)
                        }
                    }

                    if !course.website.isEmpty {
                        Link(destination: URL(string: course.website) ?? URL(string: "https://google.com")!) {
                            Label(course.website, systemImage: "globe")
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                    }

                    if course.feeDisplay != "N/D" {
                        Label("Preço: \(course.feeDisplay)", systemImage: "eurosign.circle")
                            .font(.subheadline)
                    }

                    if let op = course.operator_ {
                        Label("Operador: \(op)", systemImage: "building.2")
                            .font(.subheadline)
                    }

                    if let hours = course.openingHours {
                        Label(hours, systemImage: "clock")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardStyle()

                // Directions button
                Button {
                    let url = URL(string: "http://maps.apple.com/?daddr=\(course.latitude),\(course.longitude)")!
                    UIApplication.shared.open(url)
                } label: {
                    Label("Como Chegar", systemImage: "car.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
            }
            .padding()
        }
        .background(AppTheme.secondaryBackground)
        .navigationTitle(course.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fechar") { dismiss() }
            }
        }
    }
}

// MARK: - Radius Picker
struct RadiusPickerSheet: View {
    @Binding var radius: Double
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let radiusOptions: [Double] = [10, 25, 50, 100, 200, 500]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Raio de Pesquisa")
                    .font(.headline)

                Text("\(Int(radius)) km")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryGreen)

                Slider(value: $radius, in: 5...500, step: 5)
                    .tint(AppTheme.primaryGreen)
                    .padding(.horizontal)

                HStack(spacing: 8) {
                    ForEach(radiusOptions, id: \.self) { opt in
                        Button {
                            radius = opt
                        } label: {
                            Text("\(Int(opt))")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(radius == opt ? AppTheme.primaryGreen : Color.gray.opacity(0.15))
                                .foregroundStyle(radius == opt ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }

                Button {
                    dismiss()
                    onConfirm()
                } label: {
                    Text("Aplicar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}
