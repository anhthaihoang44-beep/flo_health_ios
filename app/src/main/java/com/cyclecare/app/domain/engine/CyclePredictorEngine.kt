package com.cyclecare.app.domain.engine

import com.cyclecare.app.domain.model.Cycle
import java.time.LocalDate
import java.time.temporal.ChronoUnit

enum class DayStatus {
    PERIOD,
    PREDICTED_PERIOD,
    FERTILE,
    OVULATION,
    NORMAL
}

enum class ConfidenceLevel {
    LOW,
    MEDIUM,
    HIGH
}

data class PredictionResult(
    val nextPeriodStartDate: LocalDate,
    val ovulationDate: LocalDate,
    val fertileWindowStart: LocalDate,
    val fertileWindowEnd: LocalDate,
    val averageCycleLength: Int,
    val averagePeriodLength: Int,
    val confidence: ConfidenceLevel
)

data class PregnancyInfo(
    val gestationalWeeks: Int,
    val gestationalDays: Int,
    val dueDate: LocalDate,
    val daysRemaining: Long
)

class CyclePredictorEngine {

    companion object {
        const val MIN_CYCLE_LENGTH = 18
        const val MAX_CYCLE_LENGTH = 45
        const val LUTEAL_PHASE_DAYS = 14
        const val PREGNANCY_DURATION_DAYS = 280L
    }

    /**
     * Tính toán chu kỳ trung bình có trọng số từ tối đa 6 chu kỳ gần nhất
     * Loại bỏ các ngoại lai < 18 ngày hoặc > 45 ngày.
     */
    fun calculateWeightedAverage(
        recentCycles: List<Cycle>,
        fallbackCycleLength: Int = 28,
        fallbackPeriodLength: Int = 5
    ): Pair<Int, ConfidenceLevel> {
        // Lấy các chu kỳ đã kết thúc và có cycleLength hợp lệ (hoặc tính từ start_date kế tiếp)
        val sortedCycles = recentCycles.sortedByDescending { it.startDate }
        val validLengths = mutableListOf<Int>()

        for (i in 0 until sortedCycles.size - 1) {
            val current = sortedCycles[i]
            val previous = sortedCycles[i + 1]
            val length = ChronoUnit.DAYS.between(previous.startDate, current.startDate).toInt()
            if (length in MIN_CYCLE_LENGTH..MAX_CYCLE_LENGTH) {
                validLengths.add(length)
            }
            if (validLengths.size == 6) break
        }

        // Nếu chu kỳ gần nhất có trường cycleLength được gán trực tiếp
        if (validLengths.isEmpty()) {
            sortedCycles.forEach { c ->
                val len = c.cycleLength
                if (len != null && len in MIN_CYCLE_LENGTH..MAX_CYCLE_LENGTH) {
                    validLengths.add(len)
                }
            }
        }

        if (validLengths.isEmpty()) {
            return Pair(fallbackCycleLength.coerceIn(MIN_CYCLE_LENGTH, MAX_CYCLE_LENGTH), ConfidenceLevel.LOW)
        }

        val takeCount = validLengths.take(6)
        // Trọng số tăng dần cho chu kỳ mới hơn (đầu danh sách có trọng số cao hơn)
        // Ví dụ takeCount có size N: phần tử 0 có trọng số N, phần tử 1 có trọng số N-1, ...
        var weightedSum = 0.0
        var totalWeights = 0.0
        val n = takeCount.size
        for (idx in 0 until n) {
            val weight = (n - idx).toDouble()
            weightedSum += takeCount[idx] * weight
            totalWeights += weight
        }

        val calculatedAvg = Math.round(weightedSum / totalWeights).toInt()

        val confidence = when {
            n < 3 -> ConfidenceLevel.LOW
            n in 3..5 -> ConfidenceLevel.MEDIUM
            else -> ConfidenceLevel.HIGH
        }

        return Pair(calculatedAvg, confidence)
    }

    /**
     * Dự đoán kỳ kinh tiếp theo, rụng trứng và cửa sổ thụ thai
     */
    fun predictNextCycle(
        recentCycles: List<Cycle>,
        profileAvgCycle: Int = 28,
        profileAvgPeriod: Int = 5
    ): PredictionResult {
        val sorted = recentCycles.sortedByDescending { it.startDate }
        val latestCycle = sorted.firstOrNull()
        val latestStartDate = latestCycle?.startDate ?: LocalDate.now()

        val (avgCycle, confidence) = calculateWeightedAverage(sorted, profileAvgCycle, profileAvgPeriod)
        val periodLength = latestCycle?.periodLength ?: profileAvgPeriod

        val nextPeriodStart = latestStartDate.plusDays(avgCycle.toLong())
        val ovulation = nextPeriodStart.minusDays(LUTEAL_PHASE_DAYS.toLong())
        val fertileStart = ovulation.minusDays(5)
        val fertileEnd = ovulation.plusDays(1)

        return PredictionResult(
            nextPeriodStartDate = nextPeriodStart,
            ovulationDate = ovulation,
            fertileWindowStart = fertileStart,
            fertileWindowEnd = fertileEnd,
            averageCycleLength = avgCycle,
            averagePeriodLength = periodLength,
            confidence = confidence
        )
    }

    /**
     * Xác định trạng thái của một ngày cụ thể (Dùng để tô màu lịch)
     */
    fun getDayStatus(
        targetDate: LocalDate,
        recentCycles: List<Cycle>,
        prediction: PredictionResult
    ): DayStatus {
        // Kiểm tra xem có thuộc kỳ kinh thực tế nào đã ghi nhận không
        for (cycle in recentCycles) {
            val periodLen = cycle.periodLength ?: prediction.averagePeriodLength
            val cycleEnd = cycle.endDate ?: cycle.startDate.plusDays(periodLen.toLong() - 1)
            if (!targetDate.isBefore(cycle.startDate) && !targetDate.isAfter(cycleEnd)) {
                return DayStatus.PERIOD
            }
        }

        // Kiểm tra dự đoán rụng trứng
        if (targetDate.isEqual(prediction.ovulationDate)) {
            return DayStatus.OVULATION
        }

        // Kiểm tra cửa sổ thụ thai
        if (!targetDate.isBefore(prediction.fertileWindowStart) && !targetDate.isAfter(prediction.fertileWindowEnd)) {
            return DayStatus.FERTILE
        }

        // Kiểm tra kỳ kinh dự đoán
        val predictedEnd = prediction.nextPeriodStartDate.plusDays(prediction.averagePeriodLength.toLong() - 1)
        if (!targetDate.isBefore(prediction.nextPeriodStartDate) && !targetDate.isAfter(predictedEnd)) {
            return DayStatus.PREDICTED_PERIOD
        }

        return DayStatus.NORMAL
    }

    /**
     * Tính toán tiến trình thai kỳ
     * Tuần thai = (hôm nay - LMP) / 7
     * Ngày dự sinh = LMP + 280 ngày
     */
    fun calculatePregnancy(lmpDate: LocalDate, currentDate: LocalDate = LocalDate.now()): PregnancyInfo {
        val daysPassed = ChronoUnit.DAYS.between(lmpDate, currentDate).coerceAtLeast(0)
        val weeks = (daysPassed / 7).toInt()
        val days = (daysPassed % 7).toInt()
        val dueDate = lmpDate.plusDays(PREGNANCY_DURATION_DAYS)
        val remaining = ChronoUnit.DAYS.between(currentDate, dueDate).coerceAtLeast(0)

        return PregnancyInfo(
            gestationalWeeks = weeks,
            gestationalDays = days,
            dueDate = dueDate,
            daysRemaining = remaining
        )
    }
}
