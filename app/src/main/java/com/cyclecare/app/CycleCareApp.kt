package com.cyclecare.app

import android.app.Application
import com.cyclecare.app.core.security.SessionManager
import com.cyclecare.app.data.local.CycleCareDatabase
import com.cyclecare.app.data.remote.SupabaseManager
import com.cyclecare.app.data.repository.CycleCareRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class CycleCareApp : Application() {

    lateinit var database: CycleCareDatabase private set
    lateinit var sessionManager: SessionManager private set
    lateinit var supabaseManager: SupabaseManager private set
    lateinit var repository: CycleCareRepository private set

    override fun onCreate() {
        super.onCreate()
        instance = this

        database = CycleCareDatabase.getInstance(this)
        sessionManager = SessionManager(this)
        supabaseManager = SupabaseManager()
        repository = CycleCareRepository(database, sessionManager, supabaseManager)

        // Seed sample articles in background
        CoroutineScope(Dispatchers.IO).launch {
            repository.seedSampleArticlesIfEmpty()
        }

        // Schedule daily reminders and background sync
        com.cyclecare.app.data.worker.ReminderWorker.scheduleDailyReminders(this)
        com.cyclecare.app.data.worker.OfflineSyncWorker.schedulePeriodicSync(this)
    }

    companion object {
        lateinit var instance: CycleCareApp private set
    }
}
