import SwiftUI

struct CreateGameSessionView: View {
    @Bindable var gameService: GameSessionService
    @Bindable var friendsService: FriendsService
    @Bindable var placesService: GooglePlacesService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCourse: GolfCourse?
    @State private var scheduledAt = Date().addingTimeInterval(86400)
    @State private var pricePerPerson: String = ""
    @State private var notes: String = ""
    @State private var selectedFriendIds: Set<String> = []
    @State private var showCoursePicker = false
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                // Campo
                Section {
                    if let course = selectedCourse {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.primaryGreen.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "flag.2.crossed.fill")
                                    .foregroundStyle(AppTheme.primaryGreen)
                                    .font(.subheadline)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(course.name).font(.headline)
                                Text(course.address).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Button("Mudar") { showCoursePicker = true }
                                .font(.caption).foregroundStyle(AppTheme.primaryGreen)
                        }
                    } else {
                        Button {
                            showCoursePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "flag.2.crossed.fill")
                                    .foregroundStyle(AppTheme.primaryGreen)
                                Text("Selecionar Campo")
                                    .foregroundStyle(AppTheme.primaryGreen)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
                            }
                        }
                    }
                } header: {
                    Text("Campo")
                }

                // Data e hora
                Section("Data e Hora") {
                    DatePicker(
                        "Data",
                        selection: $scheduledAt,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .tint(AppTheme.primaryGreen)
                }

                // Preço
                Section("Preço por Pessoa") {
                    HStack {
                        Text("€")
                            .foregroundStyle(.secondary)
                        TextField("0 (grátis)", text: $pricePerPerson)
                            .keyboardType(.decimalPad)
                    }
                }

                // Convidar amigos
                Section {
                    if friendsService.friends.isEmpty {
                        Text("Ainda não tens amigos adicionados")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(friendsService.friends) { item in
                            Button {
                                if selectedFriendIds.contains(item.profile.id) {
                                    selectedFriendIds.remove(item.profile.id)
                                } else {
                                    selectedFriendIds.insert(item.profile.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedFriendIds.contains(item.profile.id)
                                                  ? AppTheme.primaryGreen.opacity(0.15)
                                                  : Color.gray.opacity(0.1))
                                            .frame(width: 36, height: 36)
                                        Text(String(item.profile.displayName.prefix(1)).uppercased())
                                            .font(.subheadline.bold())
                                            .foregroundStyle(selectedFriendIds.contains(item.profile.id)
                                                            ? AppTheme.primaryGreen : .secondary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.profile.displayName).font(.subheadline).foregroundStyle(.primary)
                                        Text("HCP \(item.profile.handicapDisplay)").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedFriendIds.contains(item.profile.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.primaryGreen)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    HStack {
                        Text("Convidar Amigos")
                        Spacer()
                        if !selectedFriendIds.isEmpty {
                            Text("\(selectedFriendIds.count) selecionados")
                                .font(.caption).foregroundStyle(AppTheme.primaryGreen)
                        }
                    }
                }

                // Notas
                Section("Notas (opcional)") {
                    TextField("Ex: Partida de amigos, encontro às 8h00...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }

                if let err = errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Nova Partida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        createSession()
                    } label: {
                        if isCreating {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("Criar")
                        }
                    }
                    .disabled(selectedCourse == nil || isCreating)
                }
            }
            .sheet(isPresented: $showCoursePicker) {
                CoursePickerSheet(placesService: placesService, selected: $selectedCourse)
            }
        }
    }

    private func createSession() {
        guard let course = selectedCourse else { return }
        isCreating = true
        errorMessage = nil
        let price = Double(pricePerPerson.replacingOccurrences(of: ",", with: "."))
        Task {
            do {
                try await gameService.createSession(
                    course: course,
                    scheduledAt: scheduledAt,
                    pricePerPerson: price,
                    notes: notes,
                    friendIds: Array(selectedFriendIds)
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isCreating = false
            }
        }
    }
}

// MARK: - Course Picker Sheet
struct CoursePickerSheet: View {
    @Bindable var placesService: GooglePlacesService
    @Binding var selected: GolfCourse?
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [GolfCourse] {
        guard !search.isEmpty else { return placesService.courses }
        return placesService.courses.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { course in
                Button {
                    selected = course
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.primaryGreen.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "flag.fill")
                                .foregroundStyle(AppTheme.primaryGreen)
                                .font(.caption)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.name).font(.subheadline.bold()).foregroundStyle(.primary)
                            Text(course.distanceFormatted).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let price = course.priceLevel {
                            Text(String(repeating: "€", count: price + 1))
                                .font(.caption.bold()).foregroundStyle(AppTheme.accentGold)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .searchable(text: $search, prompt: "Pesquisar campo...")
            .navigationTitle("Selecionar Campo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
