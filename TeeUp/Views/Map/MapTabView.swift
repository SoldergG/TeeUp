import SwiftUI
import MapKit

struct MapTabView: View {
    @Bindable var placesService: GooglePlacesService
    @Bindable var locationManager: LocationManager
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCourse: GolfCourse?
    @State private var showDetail = false
    @State private var showRadiusSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Map
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    ForEach(placesService.courses) { course in
                        Annotation("", coordinate: course.coordinate, anchor: .bottom) {
                            CoursePinView(
                                isSelected: selectedCourse?.id == course.id,
                                rating: course.rating
                            )
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedCourse = course
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea(edges: .top)

                // Top pill buttons
                VStack {
                    HStack(spacing: 10) {
                        // Radius pill
                        MapPillButton(
                            icon: "circle.dashed",
                            label: "\(Int(placesService.searchRadiusKm)) km"
                        ) { showRadiusSheet = true }

                        Spacer()

                        // Refresh / loading
                        if placesService.isLoading {
                            MapPillButton(icon: "arrow.clockwise", label: "A carregar...") {}
                                .disabled(true)
                        } else {
                            MapPillButton(icon: "arrow.clockwise", label: "Atualizar") {
                                refresh()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()

                    // Course card
                    if let course = selectedCourse {
                        MapCourseCard(course: course) {
                            showDetail = true
                        } onDismiss: {
                            withAnimation { selectedCourse = nil }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Mapa")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { centerOnUser() }
            .sheet(isPresented: $showDetail) {
                if let course = selectedCourse {
                    NavigationStack { GolfCourseDetailView(course: course) }
                }
            }
            .sheet(isPresented: $showRadiusSheet) {
                RadiusPickerSheet(radius: $placesService.searchRadiusKm) { refresh() }
                    .presentationDetents([.height(280)])
            }
        }
    }

    private func centerOnUser() {
        if let loc = locationManager.userLocation {
            cameraPosition = .region(MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: placesService.searchRadiusKm / 55.0,
                    longitudeDelta: placesService.searchRadiusKm / 55.0
                )
            ))
        } else {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.5, longitude: -8.0),
                span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6)
            ))
        }
    }

    private func refresh() {
        guard let loc = locationManager.userLocation else {
            locationManager.requestPermission(); return
        }
        Task { await placesService.fetchCourses(near: loc.coordinate) }
    }
}

// MARK: - Course Pin
struct CoursePinView: View {
    let isSelected: Bool
    let rating: Double

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? AppTheme.accentGold : AppTheme.primaryGreen)
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                Image(systemName: "flag.fill")
                    .font(isSelected ? .body : .caption)
                    .foregroundStyle(.white)
            }
            // Pointer
            Image(systemName: "triangle.fill")
                .font(.system(size: isSelected ? 9 : 7))
                .foregroundStyle(isSelected ? AppTheme.accentGold : AppTheme.primaryGreen)
                .rotationEffect(.degrees(180))
                .offset(y: -3)
        }
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

// MARK: - Map Pill Button
struct MapPillButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption.bold())
                Text(label).font(.caption.bold())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Map Course Card
struct MapCourseCard: View {
    let course: GolfCourse
    let onSeeDetails: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.primaryGreen.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "flag.2.crossed.fill")
                    .foregroundStyle(AppTheme.primaryGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(course.name).font(.headline).lineLimit(1)
                HStack(spacing: 8) {
                    Text(course.distanceFormatted)
                    if course.rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill").foregroundStyle(AppTheme.accentGold)
                            Text(course.ratingDisplay)
                        }
                    }
                    if let open = course.openNow {
                        Text(open ? "Aberto" : "Fechado")
                            .foregroundStyle(open ? .green : .red)
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: onSeeDetails) {
                    Text("Ver")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(AppTheme.primaryGreen).foregroundStyle(.white)
                        .clipShape(Capsule())
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}
