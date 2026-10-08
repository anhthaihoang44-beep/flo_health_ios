package com.cyclecare.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.cyclecare.app.data.local.entity.CycleEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface CycleDao {
    @Query("SELECT * FROM cycles WHERE userId = :userId ORDER BY startDate DESC")
    fun getCyclesFlow(userId: String): Flow<List<CycleEntity>>

    @Query("SELECT * FROM cycles WHERE userId = :userId ORDER BY startDate DESC")
    suspend fun getCycles(userId: String): List<CycleEntity>

    @Query("SELECT * FROM cycles WHERE userId = :userId ORDER BY startDate DESC LIMIT 1")
    suspend fun getLatestCycle(userId: String): CycleEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCycle(cycle: CycleEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCycles(cycles: List<CycleEntity>)

    @Update
    suspend fun updateCycle(cycle: CycleEntity)

    @Query("DELETE FROM cycles WHERE id = :id")
    suspend fun deleteCycleById(id: String)

    @Query("DELETE FROM cycles WHERE userId = :userId")
    suspend fun clearUserCycles(userId: String)
}
