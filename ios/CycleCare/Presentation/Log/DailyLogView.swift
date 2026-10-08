import SwiftUI

struct DailyLogView: View {
    @ObservedObject var repository: CycleCareRepository
    var initialDate: Date = Date()
    var onDismiss: (() -> Void)? = nil

    @State private var selectedDate: Date = Date()
    @State private var flow: MenstrualFlow = .none
    @State private var selectedMood: MoodType? = nil
    @State private var selectedSymptoms: Set<SymptomType> = []
    @State private var crampsLevel: Double = 0
    @State private var libidoLevel: Double = 0
    @State private var sleepHours: Double = 7.5
    @State private var activity: ActivityLevel = .none
    @State private var discharge: DischargeType = .none
    @State private var notes: String = ""
    @State private var showSavedAlert = false

    private let healthKit = HealthKitManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date Selector
                    DatePicker(
                        "Ngày ghi nhận",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color.cycleSurface)
                    .cornerRadius(16)
                    .onChange(of: selectedDate) { newDate in
                        loadLog(for: newDate)
                    }

                    // Menstrual Flow Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Lượng máu kinh", systemImage: "drop.fill")
                            .font(.headline)
                            .foregroundColor(.periodRed)

                        HStack(spacing: 8) {
                            flowButton(title: "Không có", value: .none)
                            flowButton(title: "Nhẹ", value: .light)
                            flowButton(title: "Vừa", value: .medium)
                            flowButton(title: "Nhiều", value: .heavy)
                        }
                    }
                    .padding()
                    .background(Color.cycleSurface)
                    .cornerRadius(16)

                    // Mood Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tâm trạng", systemImage: "face.smiling.fill")
                            .font(.headline)
                            .foregroundColor(.cycleRose)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                            ForEach(MoodType.allCases, id: \.self) { mood in
                                Button {
                                    if selectedMood == mood {
                                        selectedMood = nil
                                    } else {
                                        selectedMood = mood
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(mood.emoji)
                                            .font(.title2)
                                        Text(mood.label)
                                            .font(.caption)
                                            .foregroundColor(selectedMood == mood ? .white : .primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selectedMood == mood ? Color.cycleRose : Color.cycleSurfaceVariant)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.cycleSurface)
                    .cornerRadius(16)

                    // Symptoms Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Triệu chứng cơ thể", systemImage: "cross.case.fill")
                            .font(.headline)
                            .foregroundColor(.cycleLavender)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(SymptomType.allCases, id: \.self) { symptom in
                                let isSelected = selectedSymptoms.contains(symptom)
                                Button {
                                    if isSelected {
                                        selectedSymptoms.remove(symptom)
                                    } else {
                                        selectedSymptoms.insert(symptom)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(symptom.emoji)
                                        Text(symptom.label)
                                            .font(.caption)
                                    }
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.cycleLavender : Color.cycleSurfaceVariant)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.cycleSurface)
                    .cornerRadius(16)

                    // Sliders: Cramps & Libido
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Mức độ đau bụng:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(crampsLevel))/5")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.periodRed)
                            }
                            Slider(value: $crampsLevel, in: 0...5, step: 1)
                                .tint(.periodRed)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Nhu cầu tình dục:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(libidoLevel))/3")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.cycleRose)
                            }
                            Slider(value: $libidoLevel, in: 0...3, step: 1)
                                .tint(.cycleRose)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Thời gian ngủ:")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f giờ", sleepHours))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.cycleLavender)
                            }
                            Slider(value: $sleepHours, in: 4...12, step: 0.5)
                                .tint(.cycleLavender)
                        }
                    }
                    .padding()
                    .background(Color.cycleSurface)
                    .cornerRadius(16)

                    // Cervical Mucus / Discharge
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Dịch âm đạo", systemImage: "bubbles.and.sparkles.fill")
                            .font(.headline)
                            .foregroundColor(.fertilePurple)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 95))], spacing: 8) {
                            ForEach(DischargeType.allCases, id: \.self) { type in
                                let isSelected = discharge == type
                                Button {
                                    discharge = type
                                } label: {
                                    Text(type.label)
                                        .font(.caption)
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color.fertilePurple : Color.cycleSurfaceVariant)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.cycleSurface)
                    .cornerRadius(16)

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Ghi chú cá nhân", systemImage: "note.text")
                            .font(.headline)

                        TextField("Thêm ghi chú triệu chứng, tâm sự hôm nay...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color.cycleSurfaceVariant)
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.cycleSurface)
                    .cornerRadius(16)

                    // Save Button
                    Button {
                        saveCurrentLog()
                    } label: {
                        Text("Lưu nhật ký")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.cycleRose)
                            .cornerRadius(26)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color.cycleBackground.ignoresSafeArea())
            .navigationTitle("Nhật ký ngày")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let dismiss = onDismiss {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Đóng") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Đã lưu nhật ký", isPresented: $showSavedAlert) {
                Button("OK") {
                    onDismiss?()
                }
            } message: {
                Text("Dữ liệu sức khỏe hôm nay đã được ghi nhận an toàn.")
            }
            .onAppear {
                selectedDate = initialDate
                loadLog(for: initialDate)
            }
        }
    }

    private func flowButton(title: String, value: MenstrualFlow) -> some View {
        Button {
            flow = value
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(flow == value ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(flow == value ? Color.periodRed : Color.cycleSurfaceVariant)
                .cornerRadius(10)
        }
    }

    private func loadLog(for date: Date) {
        if let log = repository.getDailyLog(for: date) {
            flow = log.flow
            selectedMood = log.mood
            selectedSymptoms = Set(log.symptoms)
            crampsLevel = Double(log.crampsIntensity ?? 0)
            libidoLevel = Double(log.libido ?? 0)
            sleepHours = log.sleepHours ?? 7.5
            activity = log.activity
            discharge = log.discharge
            notes = log.notes ?? ""
        } else {
            flow = .none
            selectedMood = nil
            selectedSymptoms = []
            crampsLevel = 0
            libidoLevel = 0
            sleepHours = 7.5
            activity = .none
            discharge = .none
            notes = ""
        }
    }

    private func saveCurrentLog() {
        let userId = repository.currentProfile?.id ?? repository.getOrCreateUserId()
        let log = DailyLog(
            userId: userId,
            date: selectedDate,
            flow: flow,
            crampsIntensity: Int(crampsLevel),
            mood: selectedMood,
            symptoms: Array(selectedSymptoms),
            libido: Int(libidoLevel),
            discharge: discharge,
            activity: activity,
            sleepHours: sleepHours,
            notes: notes.isEmpty ? nil : notes
        )
        repository.saveDailyLog(log)

        // HealthKit integration if flow is present
        if flow != .none {
            healthKit.writeMenstrualFlow(date: selectedDate, flow: flow) { _ in }
        }

        showSavedAlert = true
    }
}
