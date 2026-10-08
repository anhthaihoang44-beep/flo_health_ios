package com.cyclecare.app.domain.engine

import com.cyclecare.app.domain.model.Cycle
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.time.LocalDate

class CyclePredictorEngineTest {

    private lateinit var engine: CyclePredictorEngine

    @Before
    fun setUp() {
        engine = CyclePredictorEngine()
    }

    @Test
    fun testFirstCycle_usesProfileFallbackAndLowConfidence() {
        // Người dùng mới, chưa có chu kỳ trong quá khứ
        val recentCycles = emptyList<Cycle>()
        val prediction = engine.predictNextCycle(
            recentCycles = recentCycles,
            profileAvgCycle = 30,
            profileAvgPeriod = 5
        )

        assertEquals(30, prediction.averageCycleLength)
        assertEquals(5, prediction.averagePeriodLength)
        assertEquals(ConfidenceLevel.LOW, prediction.confidence)
        assertEquals(prediction.nextPeriodStartDate.minusDays(14), prediction.ovulationDate)
    }

    @Test
    fun testRegularCycles_calculatesCorrectAverageAndHighConfidence() {
        // Chuỗi 6 chu kỳ đều đặn mỗi chu kỳ cách nhau đúng 28 ngày
        val baseDate = LocalDate.of(2026, 1, 1)
        val cycles = (0..6).map { i ->
            Cycle(
                id = "c-$i",
                userId = "u1",
                startDate = baseDate.plusDays(i * 28L),
                periodLength = 5
            )
        }

        val prediction = engine.predictNextCycle(cycles, profileAvgCycle = 28, profileAvgPeriod = 5)

        assertEquals(28, prediction.averageCycleLength)
        assertEquals(ConfidenceLevel.HIGH, prediction.confidence)

        val latestStartDate = baseDate.plusDays(6 * 28L)
        val expectedNext = latestStartDate.plusDays(28)
        assertEquals(expectedNext, prediction.nextPeriodStartDate)
        assertEquals(expectedNext.minusDays(14), prediction.ovulationDate)
        assertEquals(prediction.ovulationDate.minusDays(5), prediction.fertileWindowStart)
        assertEquals(prediction.ovulationDate.plusDays(1), prediction.fertileWindowEnd)
    }

    @Test
    fun testOutlierCycles_filteredOutProperly() {
        // Chuỗi chu kỳ chứa các giá trị ngoại lai: 14 ngày (< 18) và 50 ngày (> 45)
        val c1 = Cycle("1", "u1", LocalDate.of(2026, 6, 1)) // 30 days
        val c2 = Cycle("2", "u1", LocalDate.of(2026, 5, 2)) // 14 days from c3 (OUTLIER)
        val c3 = Cycle("3", "u1", LocalDate.of(2026, 4, 18)) // 50 days from c4 (OUTLIER)
        val c4 = Cycle("4", "u1", LocalDate.of(2026, 2, 27)) // 30 days from c5
        val c5 = Cycle("5", "u1", LocalDate.of(2026, 1, 28))

        val cycles = listOf(c1, c2, c3, c4, c5)
        val prediction = engine.predictNextCycle(cycles, profileAvgCycle = 28, profileAvgPeriod = 5)

        // Các khoảng cách hợp lệ là giữa c1-c2 (30 ngày) và c4-c5 (30 ngày)
        assertEquals(30, prediction.averageCycleLength)
        assertEquals(ConfidenceLevel.LOW, prediction.confidence) // Chỉ có 2 khoảng cách hợp lệ (< 3)
    }

    @Test
    fun testLeapYear_calculatesCorrectDatesAcrossFebruary29() {
        // Năm nhuận 2024: Tháng 2 có 29 ngày
        val leapYearStart = LocalDate.of(2024, 2, 10)
        val cycles = listOf(
            Cycle("1", "u1", leapYearStart, periodLength = 5)
        )

        val prediction = engine.predictNextCycle(cycles, profileAvgCycle = 28, profileAvgPeriod = 5)

        // 10/02 + 28 ngày trong năm nhuận (29 ngày):
        // 10 + 19 ngày = 29/02, còn lại 9 ngày -> 09/03/2024
        val expectedNext = LocalDate.of(2024, 3, 9)
        assertEquals(expectedNext, prediction.nextPeriodStartDate)
        assertEquals(LocalDate.of(2024, 2, 24), prediction.ovulationDate)
    }

    @Test
    fun testDayStatusDetection() {
        val start = LocalDate.of(2026, 5, 1)
        val cycle = Cycle("1", "u1", startDate = start, periodLength = 5)
        val prediction = engine.predictNextCycle(listOf(cycle), profileAvgCycle = 28, profileAvgPeriod = 5)

        // Trong kỳ kinh thực tế
        assertEquals(DayStatus.PERIOD, engine.getDayStatus(start, listOf(cycle), prediction))
        assertEquals(DayStatus.PERIOD, engine.getDayStatus(start.plusDays(4), listOf(cycle), prediction))

        // Ngày bình thường sau kinh
        assertEquals(DayStatus.NORMAL, engine.getDayStatus(start.plusDays(5), listOf(cycle), prediction))

        // Ngày rụng trứng
        assertEquals(DayStatus.OVULATION, engine.getDayStatus(prediction.ovulationDate, listOf(cycle), prediction))

        // Cửa sổ thụ thai
        assertEquals(DayStatus.FERTILE, engine.getDayStatus(prediction.fertileWindowStart, listOf(cycle), prediction))

        // Kỳ kinh dự đoán tiếp theo
        assertEquals(DayStatus.PREDICTED_PERIOD, engine.getDayStatus(prediction.nextPeriodStartDate, listOf(cycle), prediction))
    }

    @Test
    fun testPregnancyCalculation() {
        val lmp = LocalDate.of(2026, 1, 1)
        val current = LocalDate.of(2026, 3, 26) // 84 ngày = 12 tuần đúng

        val preg = engine.calculatePregnancy(lmpDate = lmp, currentDate = current)

        assertEquals(12, preg.gestationalWeeks)
        assertEquals(0, preg.gestationalDays)
        // Ngày dự sinh = 01/01/2026 + 280 ngày = 08/10/2026
        assertEquals(LocalDate.of(2026, 10, 8), preg.dueDate)
        assertTrue(preg.daysRemaining > 0)
    }
}
