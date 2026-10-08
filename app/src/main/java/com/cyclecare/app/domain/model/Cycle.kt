package com.cyclecare.app.domain.model

import java.time.LocalDate

data class Cycle(
    val id: String,
    val userId: String,
    val startDate: LocalDate,
    val endDate: LocalDate? = null,
    val cycleLength: Int? = null,
    val periodLength: Int? = null,
    val isPredicted: Boolean = false
)
