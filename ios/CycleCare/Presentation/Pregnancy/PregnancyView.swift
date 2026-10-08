import SwiftUI

struct PregnancyView: View {
    @ObservedObject var repository: CycleCareRepository

    @State private var lmpDate: Date = Calendar.current.date(byAdding: .day, value: -112, to: Date())! // default ~16 weeks
    @State private var showDatePicker = false
    @State private var kickCount = 0
    @State private var isKickCountingActive = false
    @State private var kickTimerSeconds = 0
    @State private var timer: Timer? = nil

    private var profile: UserProfile {
        repository.currentProfile ?? UserProfile()
    }

    private var dueDate: Date {
        Calendar.current.date(byAdding: .day, value: 280, to: lmpDate) ?? Date()
    }

    private var totalDaysPregnant: Int {
        let days = Calendar.current.dateComponents([.day], from: lmpDate, to: Date()).day ?? 0
        return max(0, min(294, days))
    }

    private var currentWeek: Int {
        max(1, (totalDaysPregnant / 7) + 1)
    }

    private var currentDayOfWeek: Int {
        totalDaysPregnant % 7
    }

    private var daysRemaining: Int {
        max(0, 280 - totalDaysPregnant)
    }

    private var progressRatio: Double {
        min(1.0, Double(totalDaysPregnant) / 280.0)
    }

    private var trimester: String {
        if currentWeek <= 13 {
            return "1st Trimester (Weeks 1 - 13)"
        } else if currentWeek <= 27 {
            return "2nd Trimester (Weeks 14 - 27)"
        } else {
            return "3rd Trimester (Weeks 28 - 40+)"
        }
    }

    private var milestone: FetalMilestone {
        FetalMilestone.forWeek(currentWeek)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with due date and adjustment
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pregnancy Journey")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(trimester)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    Button {
                        showDatePicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text("Edit Date")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.cycleLavenderLight)
                        .foregroundColor(.cycleLavender)
                        .cornerRadius(12)
                    }
                }

                // Gestational Age Flo-style Big Ring
                ZStack {
                    Circle()
                        .stroke(Color.cycleLavenderLight.opacity(0.4), lineWidth: 20)
                        .frame(width: 250, height: 250)

                    Circle()
                        .trim(from: 0, to: CGFloat(progressRatio))
                        .stroke(
                            LinearGradient(
                                colors: [.cycleLavender, .cycleRose],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 6) {
                        Text("Week \(currentWeek)")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.cycleLavender)

                        Text("Day \(currentDayOfWeek)")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("\(daysRemaining) days until due date")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.cycleSurfaceVariant)
                            .cornerRadius(10)

                        Text("Due Date: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 270)

                // Fetal Milestone & Fruit Comparison Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Baby's Size Today")
                                .font(.headline)
                            Text("Size of a \(milestone.fruitComparison)")
                                .font(.subheadline)
                                .foregroundColor(.cycleRose)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.cycleRose)
                    }

                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Est. Length")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f cm", milestone.lengthCm))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Divider()
                            .frame(height: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Est. Weight")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(milestone.weightGrams >= 1000 ?
                                 String(format: "%.1f kg", milestone.weightGrams / 1000.0) :
                                 String(format: "%.0f g", milestone.weightGrams))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(12)
                    .background(Color.cycleSurfaceVariant)
                    .cornerRadius(12)

                    Text(milestone.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(Color.cycleSurface)
                .cornerRadius(20)

                // Interactive Kick Counter Widget
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Fetal Kick Counter", systemImage: "figure.and.child.holdinghands")
                            .font(.headline)
                            .foregroundColor(.cycleLavender)
                        Spacer()

                        if isKickCountingActive {
                            Text(String(format: "%02d:%02d", kickTimerSeconds / 60, kickTimerSeconds % 60))
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                        }
                    }

                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(kickCount)")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Logged kicks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            recordKick()
                        } label: {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.cycleLavender)
                                .clipShape(Circle())
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            toggleKickCountingSession()
                        } label: {
                            Text(isKickCountingActive ? "End Session" : "Start Counting")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(isKickCountingActive ? Color.red.opacity(0.8) : Color.cycleLavender)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button("Reset") {
                            resetKickCount()
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.cycleSurfaceVariant)
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }

                    Text("Tip: Count fetal kicks 2-3 times daily after meals. Aim for at least 4 kicks in 1 hour or 10 kicks within 2 hours.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(Color.cycleSurface)
                .cornerRadius(20)

                // Weekly Doctor's Advice Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .foregroundColor(.cycleRose)
                        Text("Week \(currentWeek) Doctor's Advice")
                            .font(.headline)
                    }

                    Text(milestone.advice)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cycleSurface)
                .cornerRadius(20)
            }
            .padding()
        }
        .background(Color.cycleBackground.ignoresSafeArea())
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack(spacing: 20) {
                    DatePicker(
                        "Last Menstrual Period (LMP)",
                        selection: $lmpDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    Button("Confirm & Save") {
                        showDatePicker = false
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.cycleLavender)
                    .cornerRadius(25)
                    .padding(.horizontal)
                }
                .navigationTitle("Pregnancy Setup")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            showDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func recordKick() {
        if !isKickCountingActive {
            toggleKickCountingSession()
        }
        kickCount += 1
    }

    private func toggleKickCountingSession() {
        if isKickCountingActive {
            isKickCountingActive = false
            timer?.invalidate()
            timer = nil
        } else {
            isKickCountingActive = true
            kickTimerSeconds = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                kickTimerSeconds += 1
            }
        }
    }

    private func resetKickCount() {
        kickCount = 0
        kickTimerSeconds = 0
        if isKickCountingActive {
            toggleKickCountingSession()
        }
    }
}
