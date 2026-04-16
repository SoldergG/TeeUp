import SwiftUI

struct CoursesListView: View {
    @Bindable var placesService: GooglePlacesService
    @Bindable var locationManager: LocationManager
    @State private var searchText = ""
    @State private var selectedCourse: GolfCourse?
    @State private var showRadiusSheet = false

    private var filtered: [GolfCourse] {
        guard !searchText.isEmpty else { return placesService.courses }
        return placesService.courses.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if placesService.isLoading {
                    loadingView
                } else if let error = placesService.errorMessage {
                    errorView(error)
                } else if filtered.isEmpty {
                    emptyView
                } else {
                    coursesList
                }
            }
            .searchable(text: $searchText, prompt: "Pesquisar campos...")
            .navigationTitle("Campos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showRadiusSheet = true } label: {
                            Label("Raio: \(Int(placesService.searchRadiusKm)) km", systemImage: "circle.dashed")
                        }
                        Button { refresh() } label: {
                            Label("Atualizar", systemImage: "arrow.clockwise")
                        }
                        Button(role: .destructive) { placesService.clearCache() } label: {
                            Label("Limpar cache", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showRadiusSheet) {
                RadiusPickerSheet(radius: $placesService.searchRadiusKm) { refresh() }
                    .presentationDetents([.height(280)])
            }
            .sheet(item: $selectedCourse) { course in
                NavigationStack { GolfCourseDetailView(course: course) }
            }
        }
    }

    // MARK: - States
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text("A procurar campos perto de ti...")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44)).foregroundStyle(.orange)
            Text(msg).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Tentar novamente") { refresh() }.buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.slash")
                .font(.system(size: 48)).foregroundStyle(AppTheme.primaryGreen.opacity(0.4))
            Text("Nenhum campo encontrado")
                .font(.headline)
            Text("Aumenta o raio ou verifica a localização")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Ajustar raio") { showRadiusSheet = true }.buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var coursesList: some View {
        List {
            Section {
                HStack(spacing: 6) {
                    Image(systemName: "location.circle.fill")
                        .foregroundStyle(AppTheme.primaryGreen)
                    Text("\(filtered.count) campos · raio \(Int(placesService.searchRadiusKm)) km")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(filtered) { course in
                Button { selectedCourse = course } label: {
                    CourseRow(course: course)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }

    private func refresh() {
        guard let loc = locationManager.userLocation else {
            locationManager.requestPermission(); return
        }
        Task { await placesService.fetchCourses(near: loc.coordinate) }
    }
}

// MARK: - Course Row
struct CourseRow: View {
    let course: GolfCourse

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.primaryGreen.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: "flag.fill")
                    .foregroundStyle(AppTheme.primaryGreen)
                    .font(.body)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(course.name).font(.subheadline.bold()).lineLimit(1)
                HStack(spacing: 5) {
                    if !course.address.isEmpty {
                        Text(course.address).lineLimit(1)
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(course.distanceFormatted)
                    .font(.caption.bold()).foregroundStyle(AppTheme.primaryGreen)
                if course.rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(AppTheme.accentGold)
                        Text(course.ratingDisplay)
                    }
                    .font(.caption2)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Course Detail
struct GolfCourseDetailView: View {
    let course: GolfCourse
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "flag.2.crossed.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.primaryGreen)
                    Text(course.name)
                        .font(.title2.bold()).multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Label(course.distanceFormatted, systemImage: "location")
                        if course.rating > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(AppTheme.accentGold)
                                Text("\(course.ratingDisplay) (\(course.userRatingCount))")
                            }
                        }
                        if let open = course.openNow {
                            Label(open ? "Aberto" : "Fechado",
                                  systemImage: open ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(open ? .green : .red)
                        }
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .cardStyle()

                // Info
                VStack(alignment: .leading, spacing: 14) {
                    if !course.address.isEmpty {
                        Label(course.address, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                    }
                    if !course.phone.isEmpty {
                        Link(destination: URL(string: "tel:\(course.phone)")!) {
                            Label(course.phone, systemImage: "phone").font(.subheadline)
                        }
                    }
                    if !course.website.isEmpty, let url = URL(string: course.website) {
                        Link(destination: url) {
                            Label(course.website, systemImage: "globe")
                                .font(.subheadline).lineLimit(1)
                        }
                    }
                    if let price = course.priceLevel {
                        Label("Preço: \(String(repeating: "€", count: price + 1))",
                              systemImage: "eurosign.circle")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardStyle()

                // Directions
                Button {
                    let url = URL(string: "http://maps.apple.com/?daddr=\(course.latitude),\(course.longitude)")!
                    UIApplication.shared.open(url)
                } label: {
                    Label("Como Chegar", systemImage: "car.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(AppTheme.primaryGreen).foregroundStyle(.white)
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
    private let options: [Double] = [10, 25, 50, 100, 200, 500]

    var body: some View {
        VStack(spacing: 20) {
            Text("Raio de Pesquisa").font(.headline)

            Text("\(Int(radius)) km")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryGreen)

            Slider(value: $radius, in: 5...500, step: 5)
                .tint(AppTheme.primaryGreen).padding(.horizontal)

            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    Button { radius = opt } label: {
                        Text("\(Int(opt))")
                            .font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(radius == opt ? AppTheme.primaryGreen : Color.gray.opacity(0.15))
                            .foregroundStyle(radius == opt ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }

            Button { dismiss(); onConfirm() } label: {
                Text("Aplicar")
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(AppTheme.primaryGreen).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
            .padding(.horizontal)
        }
        .padding(.top, 24)
    }
}
