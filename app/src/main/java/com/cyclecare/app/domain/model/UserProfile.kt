package com.cyclecare.app.domain.model

import java.time.LocalDate

enum class HealthGoal(val key: String) {
    TRACK("track"),
    CONCEIVE("conceive"),
    PREGNANT("pregnant"),
    PERIMENOPAUSE("perimenopause");

    companion object {
        fun fromKey(key: String): HealthGoal = entries.find { it.key == key } ?: TRACK
    }
}

data class UserProfile(
    val id: String,
    val displayName: String = "",
    val birthYear: Int? = null,
    val goal: HealthGoal = HealthGoal.TRACK,
    val avgCycleLength: Int = 28,
    val avgPeriodLength: Int = 5,
    val isAnonymous: Boolean = true,
    val lastPeriodStartDate: LocalDate? = null
)
