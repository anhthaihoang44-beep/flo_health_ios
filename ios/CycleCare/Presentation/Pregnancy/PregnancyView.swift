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
            return "Tam cá nguyệt 1 (Tuần 1 - 13)"
        } else if currentWeek <= 27 {
            return "Tam cá nguyệt 2 (Tuần 14 - 27)"
        } else {
            return "Tam cá nguyệt 3 (Tuần 28 - 40+)"
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
                        Text("Hành trình Thai kỳ")
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
                            Text("Chỉnh ngày")
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
                        Text("Tuần \(currentWeek)")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.cycleLavender)

                        Text("Ngày thứ \(currentDayOfWeek)")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Còn \(daysRemaining) ngày đến dự sinh")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.cycleSurfaceVariant)
                            .cornerRadius(10)

                        Text("Dự sinh: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 270)

                // Fetal Milestone & Fruit Comparison Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Kích thước bé yêu hôm nay")
                                .font(.headline)
                            Text("Tương đương một \(milestone.fruitComparison)")
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
                            Text("Chiều dài ước tính")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f cm", milestone.lengthCm))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Divider()
                            .frame(height: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cân nặng ước tính")
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
                        Label("Bộ đếm cử động thai (Thai máy)", systemImage: "figure.and.child.holdinghands")
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
                            Text("Lần cử động ghi nhận")
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
                            Text(isKickCountingActive ? "Kết thúc phiên" : "Bắt đầu đếm")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(isKickCountingActive ? Color.red.opacity(0.8) : Color.cycleLavender)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button("Đặt lại") {
                            resetKickCount()
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.cycleSurfaceVariant)
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }

                    Text("Lời khuyên: Mẹ nên đếm cử động thai 2-3 lần/ngày sau bữa ăn. Trung bình có ít nhất 4 cử động trong 1 giờ hoặc 10 cử động trong 2 giờ.")
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
                        Text("Lời khuyên tuần \(currentWeek)")
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
                        "Ngày đầu kỳ kinh cuối (LMP)",
                        selection: $lmpDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    Button("Xác nhận & Cập nhật") {
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
                .navigationTitle("Cài đặt thai kỳ")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Đóng") {
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
