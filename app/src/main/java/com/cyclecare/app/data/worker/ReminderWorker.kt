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

            // Check period reminder (1 day before)
            if (daysUntilPeriod == 1L) {
                notificationHelper.showNotification(
                    NotificationHelper.NOTIFICATION_ID_PERIOD,
                    "Period Reminder - CycleCare",
                    "Your next period is predicted to start tomorrow. Listen to your body and be prepared!"
                )
            }

            // Check ovulation reminder
            if (today.isEqual(prediction.ovulationDate)) {
                notificationHelper.showNotification(
                    NotificationHelper.NOTIFICATION_ID_OVULATION,
                    "Ovulation Day Today",
                    "Today is your predicted ovulation day. Conception chances are at their peak!"
                )
            }

            // Daily log reminder
            notificationHelper.showNotification(
                NotificationHelper.NOTIFICATION_ID_LOG,
                "Take a moment for yourself",
                "How are you feeling today? Take a quick second to log your symptoms and mood in CycleCare."
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
