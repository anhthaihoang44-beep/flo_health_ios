package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "profiles")
data class ProfileEntity(
    @PrimaryKey val id: String,
    val displayName: String = "",
    val birthYear: Int? = null,
    val goal: String = "track",
    val avgCycleLength: Int = 28,
    val avgPeriodLength: Int = 5,
    val isAnonymous: Boolean = true,
    val lastPeriodStartDate: String? = null,
    val updatedAt: Long = System.currentTimeMillis()
)
