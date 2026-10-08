package com.cyclecare.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.cyclecare.app.data.local.entity.PregnancyEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface PregnancyDao {
    @Query("SELECT * FROM pregnancies WHERE userId = :userId AND isActive = 1 LIMIT 1")
    fun getActivePregnancyFlow(userId: String): Flow<PregnancyEntity?>

    @Query("SELECT * FROM pregnancies WHERE userId = :userId AND isActive = 1 LIMIT 1")
    suspend fun getActivePregnancy(userId: String): PregnancyEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(pregnancy: PregnancyEntity)

    @Update
    suspend fun updatePregnancy(pregnancy: PregnancyEntity)

    @Query("DELETE FROM pregnancies WHERE userId = :userId")
    suspend fun clearUserPregnancies(userId: String)
}
