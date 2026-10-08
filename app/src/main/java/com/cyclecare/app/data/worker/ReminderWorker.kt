package com.cyclecare.app.data.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.cyclecare.app.CycleCareApp
import com.cyclecare.app.core.notification.NotificationHelper
import com.cyclecare.app.domain.engine.CyclePredictorEngine
import com.cyclecare.app.domain.model.Cycle
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.concurrent.TimeUnit

class ReminderWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    private val notificationHelper = NotificationHelper(appContext)
    private val predictorEngine = CyclePredictorEngine()
    private val dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE

    override suspend fun doWork(): Result {
        return try {
            val app = applicationContext as? CycleCareApp ?: return Result.success()
            val db = app.database
            val profile = db.profileDao().getProfile() ?: return Result.success()

            val cyclesEntities = db.cycleDao().getCycles(profile.id)
            val cycles = cyclesEntities.map {
                Cycle(
                    id = it.id,
                    userId = it.userId,
                    startDate = LocalDate.parse(it.startDate, dateFormatter),
                    endDate = it.endDate?.let { d -> LocalDate.parse(d, dateFormatter) },
                    cycleLength = it.cycleLength,
                    periodLength = it.periodLength
                )
            }

            val prediction = predictorEngine.predictNextCycle(
                recentCycles = cycles,
                profileAvgCycle = profile.avgCycleLength,
                profileAvgPeriod = profile.avgPeriodLength
            )

            val today = LocalDate.now()
            val daysUntilPeriod = ChronoUnit.DAYS.between(today, prediction.nextPeriodStartDate)

            // Kiểm tra nhắc nhở kỳ kinh (trước 1 ngày)
            if (daysUntilPeriod == 1L) {
                notificationHelper.showNotification(
                    NotificationHelper.NOTIFICATION_ID_PERIOD,
                    "Nhắc nhở kỳ kinh - CycleCare",
                    "Kỳ kinh nguyệt tiếp theo của bạn dự kiến sẽ bắt đầu vào ngày mai. Hãy lắng nghe cơ thể và chuẩn bị sẵn sàng nhé!"
                )
            }

            // Kiểm tra nhắc nhở rụng trứng
            if (today.isEqual(prediction.ovulationDate)) {
                notificationHelper.showNotification(
                    NotificationHelper.NOTIFICATION_ID_OVULATION,
                    "Ngày rụng trứng hôm nay",
                    "Hôm nay là ngày rụng trứng dự đoán của chu kỳ. Khả năng thụ thai đang ở mức cao nhất!"
                )
            }

            // Nhắc nhở ghi nhật ký mỗi ngày
            notificationHelper.showNotification(
                NotificationHelper.NOTIFICATION_ID_LOG,
                "Dành 1 phút cho bản thân",
                "Hôm nay bạn cảm thấy thế nào? Hãy ghi lại tâm trạng và các triệu chứng trong CycleCare để theo dõi sức khỏe nhé."
            )

            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    companion object {
        private const val WORK_NAME = "cyclecare_daily_reminder_work"

        fun scheduleDailyReminders(context: Context) {
            val request = PeriodicWorkRequestBuilder<ReminderWorker>(24, TimeUnit.HOURS)
                .setInitialDelay(1, TimeUnit.HOURS)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }
    }
}
