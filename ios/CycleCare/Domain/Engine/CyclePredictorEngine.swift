import Foundation

enum DayStatus: String {
    case period = "period"
    case predictedPeriod = "predicted_period"
    case fertile = "fertile"
    case ovulation = "ovulation"
    case normal = "normal"
}

enum ConfidenceLevel: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

struct PredictionResult {
    let nextPeriodStartDate: Date
    let ovulationDate: Date
    let fertileWindowStart: Date
    let fertileWindowEnd: Date
    let averageCycleLength: Int
    let averagePeriodLength: Int
    let confidence: ConfidenceLevel
}

struct PregnancyProgress {
    let gestationalWeeks: Int
    let gestationalDays: Int
    let dueDate: Date
    let daysRemaining: Int
}

class CyclePredictorEngine {
    static let minCycleLength = 18
    static let maxCycleLength = 45
    static let lutealPhaseDays = 14
    static let pregnancyDurationDays = 280

    private let calendar = Calendar.current

    func calculateWeightedAverage(
        recentCycles: [Cycle],
        fallbackCycle: Int = 28,
        fallbackPeriod: Int = 5
    ) -> (avgCycle: Int, confidence: ConfidenceLevel) {
        let sorted = recentCycles.sorted { $0.startDate > $1.startDate }
        var validLengths: [Int] = []

        if sorted.count > 1 {
            for i in 0..<(sorted.count - 1) {
                let current = sorted[i].startDate
                let prev = sorted[i + 1].startDate
                let diff = calendar.dateComponents([.day], from: prev, to: current).day ?? 0
                if diff >= Self.minCycleLength && diff <= Self.maxCycleLength {
                    validLengths.append(diff)
                }
                if validLengths.count == 6 { break }
            }
        }

        if validLengths.isEmpty {
            for c in sorted {
                if let len = c.cycleLength, len >= Self.minCycleLength && len <= Self.maxCycleLength {
                    validLengths.append(len)
                }
            }
        }

        guard !validLengths.isEmpty else {
            return (max(Self.minCycleLength, min(Self.maxCycleLength, fallbackCycle)), .low)
        }

        let takeCount = Array(validLengths.prefix(6))
        let n = takeCount.count
        var weightedSum = 0.0
        var totalWeight = 0.0

        for i in 0..<n {
            let weight = Double(n - i)
            weightedSum += Double(takeCount[i]) * weight
            totalWeight += weight
        }

        let calculatedAvg = Int(round(weightedSum / totalWeight))
        let confidence: ConfidenceLevel
        if n < 3 {
            confidence = .low
        } else if n <= 5 {
            confidence = .medium
        } else {
            confidence = .high
        }

        return (calculatedAvg, confidence)
    }

    func predictNextCycle(
        recentCycles: [Cycle],
        profileAvgCycle: Int = 28,
        profileAvgPeriod: Int = 5
    ) -> PredictionResult {
        let sorted = recentCycles.sorted { $0.startDate > $1.startDate }
        let latestCycle = sorted.first
        let latestStartDate = latestCycle?.startDate ?? Date()

        let (avgCycle, confidence) = calculateWeightedAverage(
            recentCycles: sorted,
            fallbackCycle: profileAvgCycle,
            fallbackPeriod: profileAvgPeriod
        )
        let periodLen = latestCycle?.periodLength ?? profileAvgPeriod

        guard let nextPeriodStart = calendar.date(byAdding: .day, value: avgCycle, to: latestStartDate),
              let ovulation = calendar.date(byAdding: .day, value: -Self.lutealPhaseDays, to: nextPeriodStart),
              let fertileStart = calendar.date(byAdding: .day, value: -5, to: ovulation),
              let fertileEnd = calendar.date(byAdding: .day, value: 1, to: ovulation) else {
            return PredictionResult(
                nextPeriodStartDate: latestStartDate,
                ovulationDate: latestStartDate,
                fertileWindowStart: latestStartDate,
                fertileWindowEnd: latestStartDate,
                averageCycleLength: avgCycle,
                averagePeriodLength: periodLen,
                confidence: confidence
            )
        }

        return PredictionResult(
            nextPeriodStartDate: nextPeriodStart,
            ovulationDate: ovulation,
            fertileWindowStart: fertileStart,
            fertileWindowEnd: fertileEnd,
            averageCycleLength: avgCycle,
            averagePeriodLength: periodLen,
            confidence: confidence
        )
    }

    func getDayStatus(
        targetDate: Date,
        recentCycles: [Cycle],
        prediction: PredictionResult
    ) -> DayStatus {
        let targetCal = calendar.startOfDay(for: targetDate)

        // Actual logged period
        for cycle in recentCycles {
            let start = calendar.startOfDay(for: cycle.startDate)
            let periodLen = cycle.periodLength ?? prediction.averagePeriodLength
            let end = cycle.endDate != nil ? calendar.startOfDay(for: cycle.endDate!) : (calendar.date(byAdding: .day, value: periodLen - 1, to: start) ?? start)
            if targetCal >= start && targetCal <= end {
                return .period
            }
        }

        // Ovulation day
        let ovDay = calendar.startOfDay(for: prediction.ovulationDate)
        if targetCal == ovDay {
            return .ovulation
        }

        // Fertile window
        let fStart = calendar.startOfDay(for: prediction.fertileWindowStart)
        let fEnd = calendar.startOfDay(for: prediction.fertileWindowEnd)
        if targetCal >= fStart && targetCal <= fEnd {
            return .fertile
        }

        // Predicted period
        let pStart = calendar.startOfDay(for: prediction.nextPeriodStartDate)
        let pEnd = calendar.date(byAdding: .day, value: prediction.averagePeriodLength - 1, to: pStart) ?? pStart
        if targetCal >= pStart && targetCal <= pEnd {
            return .predictedPeriod
        }

        return .normal
    }

    func calculatePregnancy(lmpDate: Date, currentDate: Date = Date()) -> PregnancyProgress {
        let lmpStart = calendar.startOfDay(for: lmpDate)
        let curStart = calendar.startOfDay(for: currentDate)
        let daysPassed = max(0, calendar.dateComponents([.day], from: lmpStart, to: curStart).day ?? 0)

        let weeks = daysPassed / 7
        let days = daysPassed % 7
        let dueDate = calendar.date(byAdding: .day, value: Self.pregnancyDurationDays, to: lmpStart) ?? curStart
        let remaining = max(0, calendar.dateComponents([.day], from: curStart, to: dueDate).day ?? 0)

        return PregnancyProgress(
            gestationalWeeks: weeks,
            gestationalDays: days,
            dueDate: dueDate,
            daysRemaining: remaining
        )
    }
}
