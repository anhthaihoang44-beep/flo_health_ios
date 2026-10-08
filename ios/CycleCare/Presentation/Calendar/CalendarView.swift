import SwiftUI

struct CalendarView: View {
    @ObservedObject var repository: CycleCareRepository
    var onOpenLogForDate: (Date) -> Void

    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil
    @State private var showEditSheet = false

    private let calendar = Calendar.current
    private let daysOfWeek = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]

    private var profile: UserProfile {
        repository.currentProfile ?? UserProfile()
    }

    private var daysInCurrentMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        let firstDay = monthInterval.start
        let dayOfWeekOffset = (calendar.component(.weekday, from: firstDay) - 1)
        let totalDays = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30

        var days: [Date?] = Array(repeating: nil, count: dayOfWeekOffset)
        for d in 0..<totalDays {
            if let date = calendar.date(byAdding: .day, value: d, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month Header
                HStack {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text(currentMonth.formatted(.dateTime.year().month(.wide)))
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)

                // Day of Week Header
                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Month Days Grid
                let columns = Array(repeating: GridItem(.flexible()), count: 7)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<daysInCurrentMonth.count, id: \.self) { index in
                        if let date = daysInCurrentMonth[index] {
                            DayCell(
                                date: date,
                                profile: profile,
                                isSelected: selectedDate != nil && calendar.isDate(selectedDate!, inSameDayAs: date),
                                isToday: calendar.isDateInToday(date)
                            ) {
                                selectedDate = date
                                showEditSheet = true
                            }
                        } else {
                            Text("")
                                .frame(width: 36, height: 36)
                        }
                    }
                }
                .padding()
                .background(Color.cycleSurface)
                .cornerRadius(20)

                // Legend
                HStack(spacing: 16) {
                    LegendItem(color: .periodPink, title: "Hành kinh")
                    LegendItem(color: .fertileLight, title: "Thụ thai")
                    LegendItem(color: .ovulationTeal.opacity(0.3), title: "Rụng trứng")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.cycleSurface)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(Color.cycleBackground.ignoresSafeArea())
        .sheet(isPresented: $showEditSheet) {
            if let date = selectedDate {
                VStack(spacing: 16) {
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.title3)
                        .fontWeight(.bold)

                    Button {
                        repository.logPeriodStart(date: date)
                        showEditSheet = false
                    } label: {
                        HStack {
                            Image(systemName: "drop.fill")
                            Text("Bắt đầu kỳ kinh tại ngày này")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.periodRed)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                    }

                    Button {
                        showEditSheet = false
                        onOpenLogForDate(date)
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Ghi nhật ký ngày này")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.clear)
                        .foregroundColor(.primary)
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.gray.opacity(0.3)))
                    }
                }
                .padding(24)
                .presentationDetents([.height(240)])
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = next
        }
    }
}

private struct DayCell: View {
    let date: Date
    let profile: UserProfile
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        let lastPeriod = profile.lastPeriodStartDate ?? Date()
        let diff = calendar.dateComponents([.day], from: lastPeriod, to: date).day ?? 0
        let cycleLen = profile.avgCycleLength
        let periodLen = profile.avgPeriodLength

        let cycleDay = diff >= 0 ? (diff % cycleLen) + 1 : 0
        let isPeriod = cycleDay >= 1 && cycleDay <= periodLen
        let ovulationDay = cycleLen - 14
        let isOvulation = cycleDay == ovulationDay
        let isFertile = cycleDay >= (ovulationDay - 5) && cycleDay <= (ovulationDay + 1)

        let bg: Color = isPeriod ? .periodPink : (isOvulation ? .ovulationTeal.opacity(0.3) : (isFertile ? .fertileLight : .clear))
        let textCol: Color = isPeriod ? .periodRed : (isOvulation ? .ovulationTeal : (isFertile ? .fertilePurple : .primary))

        Button(action: onTap) {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isToday || isSelected ? .bold : .regular)
                .foregroundColor(textCol)
                .frame(width: 36, height: 36)
                .background(bg)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.cycleRose : (isToday ? Color.gray : Color.clear), lineWidth: isSelected ? 2 : 1)
                )
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
