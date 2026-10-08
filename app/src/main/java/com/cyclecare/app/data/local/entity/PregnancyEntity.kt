package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "pregnancies")
data class PregnancyEntity(
    @PrimaryKey val id: String,
    val userId: String,
    val lmpDate: String, // YYYY-MM-DD
    val dueDate: String, // YYYY-MM-DD
    val isActive: Boolean = true,
    val endedAt: String? = null,
    val updatedAt: Long = System.currentTimeMillis()
)
