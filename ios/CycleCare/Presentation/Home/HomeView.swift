import SwiftUI

struct HomeView: View {
    @ObservedObject var repository: CycleCareRepository
    @Binding var selectedTab: Int

    @State private var isPregnancyModeActive = false
    @State private var animationProgress: CGFloat = 0.0

    private var profile: UserProfile {
        repository.currentProfile ?? UserProfile()
    }

    private var cycleLength: Int {
        profile.avgCycleLength
    }

    private var lastPeriodDate: Date {
        profile.lastPeriodStartDate ?? Calendar.current.date(byAdding: .day, value: -10, to: Date())!
    }

    private var currentCycleDay: Int {
        let days = Calendar.current.dateComponents([.day], from: lastPeriodDate, to: Date()).day ?? 0
        return (days % cycleLength) + 1
    }

    private var daysUntilNextPeriod: Int {
        max(0, cycleLength - currentCycleDay)
    }

    private var ovulationDay: Int {
        cycleLength - 14
    }

    private var isFertileWindow: Bool {
        currentCycleDay >= (ovulationDay - 5) && currentCycleDay <= (ovulationDay + 1)
    }

    private var isPeriod: Bool {
        currentCycleDay <= profile.avgPeriodLength
    }

    var body: some View {
        if isPregnancyModeActive || profile.goal == .pregnant {
            VStack {
                HStack {
                    Spacer()
                    Button("Quay lại chu kỳ") {
                        isPregnancyModeActive = false
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color.cycleSurfaceVariant)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                PregnancyView(repository: repository)
            }
        } else {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Xin chào, \(profile.displayName)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(Date().formatted(date: .long, time: .omitted))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()

                        Button {
                            isPregnancyModeActive = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "figure.and.child.holdinghands")
                                Text("Thai kỳ")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.cycleLavenderLight)
                            .foregroundColor(.cycleLavender)
                            .cornerRadius(16)
                        }
                    }

                    // Cycle Wheel (Flo inspired)
                    ZStack {
                        // Background Ring
                        Circle()
                            .stroke(Color.cycleRoseLight.opacity(0.4), lineWidth: 22)
                            .frame(width: 260, height: 260)

                        // Progress Ring
                        Circle()
                            .trim(from: 0, to: animationProgress)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.cycleRose, isPeriod ? .periodRed : (isFertileWindow ? .fertilePurple : .cycleRose)]),
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 22, lineCap: .round)
                            )
                            .frame(width: 260, height: 260)
                            .rotationEffect(.degrees(-90))

                        // Center content
                        VStack(spacing: 6) {
                            Text("Ngày thứ \(currentCycleDay)")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(isPeriod ? .periodRed : (isFertileWindow ? .fertilePurple : .cycleRose))

                            Text("của chu kỳ")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(daysUntilNextPeriod > 0 ? "Còn \(daysUntilNextPeriod) ngày đến kỳ kinh" : "Kỳ kinh bắt đầu hôm nay")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.cycleSurfaceVariant)
                                .cornerRadius(10)

                            Text(isFertileWindow ? "Khả năng thụ thai: Cao" : "Khả năng thụ thai: Thấp")
                                .font(.caption2)
                                .foregroundColor(isFertileWindow ? .fertilePurple : .secondary)
                        }
                    }
                    .frame(height: 280)
                    .onAppear {
                        let target = CGFloat(currentCycleDay) / CGFloat(cycleLength)
                        withAnimation(.easeOut(duration: 1.2)) {
                            animationProgress = min(1.0, max(0.05, target))
                        }
                    }

                    // Quick Actions
                    HStack(spacing: 12) {
                        Button {
                            repository.logPeriodStart(date: Date())
                        } label: {
                            HStack {
                                Image(systemName: "drop.fill")
                                Text("Ghi nhận kỳ kinh")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.periodRed)
                            .foregroundColor(.white)
                            .cornerRadius(26)
                        }

                        Button {
                            selectedTab = 2 // Log tab
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Ghi nhật ký")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.cycleLavender)
                            .foregroundColor(.white)
                            .cornerRadius(26)
                        }
                    }

                    // Phase Health Advice Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.cycleRose)
                            Text(isPeriod ? "Pha Hành Kinh: Nghỉ ngơi nhẹ nhàng" : (isFertileWindow ? "Pha Nang Trứng: Năng lượng đạt đỉnh" : "Pha Hoàng Thể: Lắng nghe cảm xúc"))
                                .font(.headline)
                        }

                        Text(isPeriod ?
                             "Nồng độ estrogen và progesterone đang ở mức thấp. Hãy giữ ấm vùng bụng, uống trà gừng và ngủ đủ giấc." :
                             (isFertileWindow ?
                              "Cửa sổ thụ thai đang mở. Nồng độ estrogen tăng cao giúp bạn cảm thấy tự tin, yêu đời và làn da tươi tắn." :
                              "Progesterone tăng cao có thể gây cảm giác mệt mỏi nhẹ. Hãy ưu tiên thực phẩm giàu chất xơ và hạn chế đồ ngọt."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cycleSurface)
                    .cornerRadius(20)
                }
                .padding(20)
            }
            .background(Color.cycleBackground.ignoresSafeArea())
        }
    }
}
