import XCTest
@testable import CycleCare

final class CyclePredictorEngineTests: XCTestCase {
    var engine: CyclePredictorEngine!
    let calendar = Calendar.current

    override func setUp() {
        super.setUp()
        engine = CyclePredictorEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // 1. Regular 28-day cycle test
    func testRegularCyclesPrediction() {
        let now = Date()
        var cycles: [Cycle] = []
        for i in 0..<6 {
            let start = calendar.date(byAdding: .day, value: -(i * 28), to: now)!
            cycles.append(Cycle(userId: "u1", startDate: start, periodLength: 5))
        }

        let result = engine.predictNextCycle(recentCycles: cycles, profileAvgCycle: 28, profileAvgPeriod: 5)

        XCTAssertEqual(result.averageCycleLength, 28)
        XCTAssertEqual(result.confidence, .high)

        // Ovulation must be 14 days before next period start
        let daysBetweenOvAndNext = calendar.dateComponents([.day], from: result.ovulationDate, to: result.nextPeriodStartDate).day
        XCTAssertEqual(daysBetweenOvAndNext, 14)

        // Fertile window must start 5 days before ovulation
        let daysBeforeOv = calendar.dateComponents([.day], from: result.fertileWindowStart, to: result.ovulationDate).day
        XCTAssertEqual(daysBeforeOv, 5)

        // Fertile window must end 1 day after ovulation
        let daysAfterOv = calendar.dateComponents([.day], from: result.ovulationDate, to: result.fertileWindowEnd).day
        XCTAssertEqual(daysAfterOv, 1)
    }

    // 2. Outlier rejection test (< 18 days or > 45 days)
    func testOutlierRejection() {
        let base = Date()
        let cycles = [
            Cycle(userId: "u1", startDate: base, periodLength: 5), // current
            Cycle(userId: "u1", startDate: calendar.date(byAdding: .day, value: -12, to: base)!, periodLength: 5), // 12 days (outlier < 18)
            Cycle(userId: "u1", startDate: calendar.date(byAdding: .day, value: -42, to: base)!, periodLength: 5), // 30 days diff from previous
            Cycle(userId: "u1", startDate: calendar.date(byAdding: .day, value: -102, to: base)!, periodLength: 5) // 60 days diff (outlier > 45)
        ]

        let (avg, confidence) = engine.calculateWeightedAverage(recentCycles: cycles, fallbackCycle: 28, fallbackPeriod: 5)

        // Only the 30-day interval should be accepted
        XCTAssertEqual(avg, 30)
        XCTAssertEqual(confidence, .low) // only 1 valid cycle
    }

    // 3. Fallback when no cycle history
    func testFallbackWhenNoCycles() {
        let (avg, confidence) = engine.calculateWeightedAverage(recentCycles: [], fallbackCycle: 32, fallbackPeriod: 6)

        XCTAssertEqual(avg, 32)
        XCTAssertEqual(confidence, .low)
    }

    // 4. Pregnancy Calculation (Naegele's rule: 280 days)
    func testPregnancyCalculation() {
        let lmp = calendar.date(byAdding: .day, value: -70, to: Date())! // 10 weeks ago (70 days)
        let progress = engine.calculatePregnancy(lmpDate: lmp, currentDate: Date())

        XCTAssertEqual(progress.gestationalWeeks, 10)
        XCTAssertEqual(progress.gestationalDays, 0)
        XCTAssertEqual(progress.daysRemaining, 210) // 280 - 70 = 210 days

        let totalDays = calendar.dateComponents([.day], from: lmp, to: progress.dueDate).day
        XCTAssertEqual(totalDays, 280)
    }

    // 5. Day Status Identification
    func testGetDayStatus() {
        let base = calendar.startOfDay(for: Date())
        let cycle = Cycle(userId: "u1", startDate: base, periodLength: 5)
        let prediction = engine.predictNextCycle(recentCycles: [cycle], profileAvgCycle: 28, profileAvgPeriod: 5)

        // Day of period
        let periodStatus = engine.getDayStatus(targetDate: base, recentCycles: [cycle], prediction: prediction)
        XCTAssertEqual(periodStatus, .period)

        // Day of ovulation
        let ovStatus = engine.getDayStatus(targetDate: prediction.ovulationDate, recentCycles: [cycle], prediction: prediction)
        XCTAssertEqual(ovStatus, .ovulation)

        // Day in fertile window (1 day before ovulation)
        let fertileDay = calendar.date(byAdding: .day, value: -1, to: prediction.ovulationDate)!
        let fertileStatus = engine.getDayStatus(targetDate: fertileDay, recentCycles: [cycle], prediction: prediction)
        XCTAssertEqual(fertileStatus, .fertile)

        // Day of next predicted period
        let predPeriodStatus = engine.getDayStatus(targetDate: prediction.nextPeriodStartDate, recentCycles: [cycle], prediction: prediction)
        XCTAssertEqual(predPeriodStatus, .predictedPeriod)
    }
}
