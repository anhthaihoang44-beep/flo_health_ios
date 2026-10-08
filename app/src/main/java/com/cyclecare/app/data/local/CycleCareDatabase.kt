package com.cyclecare.app.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.cyclecare.app.data.local.dao.ArticleDao
import com.cyclecare.app.data.local.dao.CycleDao
import com.cyclecare.app.data.local.dao.DailyLogDao
import com.cyclecare.app.data.local.dao.ProfileDao
import com.cyclecare.app.data.local.entity.ArticleEntity
import com.cyclecare.app.data.local.entity.CycleEntity
import com.cyclecare.app.data.local.entity.DailyLogEntity
import com.cyclecare.app.data.local.entity.ProfileEntity

@Database(
    entities = [
        ProfileEntity::class,
        CycleEntity::class,
        DailyLogEntity::class,
        ArticleEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class CycleCareDatabase : RoomDatabase() {
    abstract fun profileDao(): ProfileDao
    abstract fun cycleDao(): CycleDao
    abstract fun dailyLogDao(): DailyLogDao
    abstract fun articleDao(): ArticleDao

    companion object {
        @Volatile
        private var INSTANCE: CycleCareDatabase? = null

        fun getInstance(context: Context): CycleCareDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    CycleCareDatabase::class.java,
                    "cyclecare_database.db"
                ).fallbackToDestructiveMigration().build()
                INSTANCE = instance
                instance
            }
        }
    }
}
