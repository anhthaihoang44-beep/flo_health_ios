package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "reminders")
data class ReminderEntity(
    @PrimaryKey val id: String,
    val userId: String,
    val type: String, // period, ovulation, pill, log
    val time: String, // HH:mm
    val enabled: Boolean = true,
    val daysBefore: Int = 1
)
