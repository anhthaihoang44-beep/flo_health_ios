package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "daily_logs",
    indices = [Index(value = ["userId", "logDate"], unique = true)]
)
data class DailyLogEntity(
    @PrimaryKey val id: String,
    val userId: String,
    val logDate: String, // YYYY-MM-DD
    val mood: String?,
    val discharge: String?,
    val crampsLevel: Int?,
    val libido: Int?,
    val sleepHours: Double?,
    val sleepQuality: Int?,
    val activity: String?,
    val symptoms: String, // Comma-separated or JSON
    val note: String?,
    val updatedAt: Long = System.currentTimeMillis()
)
