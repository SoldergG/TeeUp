import SwiftUI
import MapKit

struct MapTabView: View {
    @Bindable var overpassService: OverpassService
    @Bindable var locationManager: LocationManager
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCourse: OverpassCourse?
    @State private var showDetail = false
    @State private var showRadiusSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    ForEach(overpassService.courses) { course in
                        Annotation(course.name,
                                   coordinate: course.coordinate,
                                   anchor: .bottom
                        ) {
                            Button {
                                selectedCourse = course
                            } label: {
                                coursePin
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

                // Top controls
                HStack {
                    Button {
                        showRadiusSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.dashed")
                            Text("\(Int(overpassService.searchRadiusKm)) km")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .tint(.primary)

                    Spacer()

                    if overpassService.isLoading {
                        ProgressView()
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    } else {
                        Button {
                            refreshCourses()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .tint(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Course card at bottom
                if let course = selectedCourse {
                    VStack {
                        Spacer()
                        courseCard(course)
                            .padding()
                            .transition(.move(edge: .bottom))
                    }
                }
            }
            .navigationTitle("Mapa")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let loc = locationManager.userLocation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(
                            latitudeDelta: overpassService.searchRadiusKm / 55.0,
                            longitudeDelta: overpassService.searchRadiusKm / 55.0
                        )
                    ))
                } else {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 39.5, longitude: -8.0),
                        span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6)
                    ))
                }
            }
            .sheet(isPresented: $showDetail) {
                if let course = selectedCourse {
                    NavigationStack {
                        OverpassCourseDetailView(course: course)
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
        }
    }

    private var coursePin: some View {
        VStack(spacing: 0) {
            Image(systemName: "flag.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .padding(6)
                .background(AppTheme.primaryGreen)
                .clipShape(Circle())

            Image(systemName: "triangle.fill")
                .font(.system(size: 6))
                .foregroundStyle(AppTheme.primaryGreen)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
    }

    private func courseCard(_ course: OverpassCourse) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.primaryGreen.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "flag.2.crossed.fill")
                    .foregroundStyle(AppTheme.primaryGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(course.distanceFormatted)
                    if let holes = course.holes {
                        Text("· \(holes)H")
                    }
                    if course.feeDisplay != "N/D" {
                        Text("· \(course.feeDisplay)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showDetail = true
            } label: {
                Text("Ver")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.primaryGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
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
