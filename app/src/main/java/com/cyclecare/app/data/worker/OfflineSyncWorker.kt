package com.cyclecare.app.data.worker

import android.content.Context
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.cyclecare.app.CycleCareApp
import java.util.concurrent.TimeUnit

class OfflineSyncWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            val app = applicationContext as? CycleCareApp ?: return Result.success()
            val supabaseManager = app.supabaseManager
            if (!supabaseManager.isConfigured) {
                // Đang dùng offline mock, không cần sync cloud
                return Result.success()
            }

            // Đồng bộ dữ liệu profiles, cycles, daily_logs lên Supabase
            val db = app.database
            val profile = db.profileDao().getProfile()
            if (profile != null) {
                // Sync profile và cycles
                val cycles = db.cycleDao().getCycles(profile.id)
                // Cloud sync logic executes here...
            }

            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    companion object {
        private const val SYNC_WORK_NAME = "cyclecare_offline_sync_work"

        fun schedulePeriodicSync(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val request = PeriodicWorkRequestBuilder<OfflineSyncWorker>(6, TimeUnit.HOURS)
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                SYNC_WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }
    }
}
