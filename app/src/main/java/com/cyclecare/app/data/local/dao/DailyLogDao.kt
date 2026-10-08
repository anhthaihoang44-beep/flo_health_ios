package com.cyclecare.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.cyclecare.app.data.local.entity.DailyLogEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface DailyLogDao {
    @Query("SELECT * FROM daily_logs WHERE userId = :userId AND logDate = :date LIMIT 1")
    fun getLogByDateFlow(userId: String, date: String): Flow<DailyLogEntity?>

    @Query("SELECT * FROM daily_logs WHERE userId = :userId AND logDate = :date LIMIT 1")
    suspend fun getLogByDate(userId: String, date: String): DailyLogEntity?

    @Query("SELECT * FROM daily_logs WHERE userId = :userId ORDER BY logDate DESC")
    fun getAllLogsFlow(userId: String): Flow<List<DailyLogEntity>>

    @Query("SELECT * FROM daily_logs WHERE userId = :userId AND logDate BETWEEN :startDate AND :endDate ORDER BY logDate ASC")
    suspend fun getLogsBetween(userId: String, startDate: String, endDate: String): List<DailyLogEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLog(log: DailyLogEntity)

    @Update
    suspend fun updateLog(log: DailyLogEntity)

    @Query("DELETE FROM daily_logs WHERE id = :id")
    suspend fun deleteLogById(id: String)

    @Query("DELETE FROM daily_logs WHERE userId = :userId")
    suspend fun clearUserLogs(userId: String)
}
