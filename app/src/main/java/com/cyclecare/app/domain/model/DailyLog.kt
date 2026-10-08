package com.cyclecare.app.domain.model

import java.time.LocalDate

data class DailyLog(
    val id: String,
    val userId: String,
    val logDate: LocalDate,
    val mood: String? = null,
    val discharge: String? = null,
    val crampsLevel: Int? = null, // 0 - 5
    val libido: Int? = null,      // 0 - 5
    val sleepHours: Double? = null,
    val sleepQuality: Int? = null, // 1 - 5
    val activity: String? = null,
    val symptoms: List<String> = emptyList(),
    val note: String? = null
)
