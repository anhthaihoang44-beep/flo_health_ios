package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "cycles")
data class CycleEntity(
    @PrimaryKey val id: String,
    val userId: String,
    val startDate: String, // YYYY-MM-DD
    val endDate: String?,
    val cycleLength: Int?,
    val periodLength: Int?,
    val isPredicted: Boolean = false,
    val updatedAt: Long = System.currentTimeMillis()
)
