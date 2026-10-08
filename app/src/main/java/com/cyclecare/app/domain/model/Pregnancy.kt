package com.cyclecare.app.domain.model

import java.time.LocalDate

data class Pregnancy(
    val id: String,
    val userId: String,
    val lmpDate: LocalDate,
    val dueDate: LocalDate,
    val isActive: Boolean = true,
    val endedAt: LocalDate? = null
)

data class FetalDevelopmentWeek(
    val week: Int,
    val fruitComparison: String,
    val lengthCm: Double,
    val weightGrams: Double,
    val highlights: String,
    val motherTips: String
)

object PregnancyMilestones {
    fun getWeekInfo(week: Int): FetalDevelopmentWeek {
        val clampedWeek = week.coerceIn(4, 40)
        return when (clampedWeek) {
            in 4..6 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Sesame Seed",
                lengthCm = 0.2,
                weightGrams = 0.5,
                highlights = "The neural tube is developing, and the baby's tiny heart begins its first beats.",
                motherTips = "Take 400-600 mcg of Folic Acid daily, stay well-hydrated, and prioritize rest."
            )
            in 7..10 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Raspberry",
                lengthCm = 2.3,
                weightGrams = 2.0,
                highlights = "Tiny webbed fingers and toes are forming, along with facial features.",
                motherTips = "If experiencing morning sickness, eat small frequent meals and sip warm ginger tea."
            )
            in 11..14 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Lemon",
                lengthCm = 7.4,
                weightGrams = 23.0,
                highlights = "End of 1st Trimester! Baby has unique fingerprints and begins gentle spontaneous movements.",
                motherTips = "Ideal time for your nuchal translucency scan and first-trimester prenatal screenings."
            )
            in 15..19 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Avocado",
                lengthCm = 12.0,
                weightGrams = 100.0,
                highlights = "Baby can now hear the rhythm of your heartbeat and the soothing sound of your voice.",
                motherTips = "Talk and sing gently to baby every day. Practice sleeping on your left side."
            )
            in 20..24 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Sweet Corn",
                lengthCm = 28.0,
                weightGrams = 450.0,
                highlights = "You may feel distinct baby kicks (quickening). Eyebrows and eyelids are fully formed.",
                motherTips = "Maintain iron and calcium intake as advised by your OB-GYN, and complete gestational glucose testing."
            )
            in 25..29 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Eggplant",
                lengthCm = 36.0,
                weightGrams = 1000.0,
                highlights = "Entering the 3rd Trimester! Rapid brain development and baby can open their eyes to perceive light.",
                motherTips = "Count fetal movements (kicks) after meals and start preparing your hospital delivery bag."
            )
            in 30..35 -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Cantaloupe",
                lengthCm = 44.0,
                weightGrams = 1900.0,
                highlights = "Immune and respiratory systems are maturing rapidly in preparation for birth.",
                motherTips = "Attend prenatal breathing classes and practice relaxation exercises."
            )
            else -> FetalDevelopmentWeek(
                week = clampedWeek,
                fruitComparison = "Watermelon",
                lengthCm = 50.0,
                weightGrams = 3200.0,
                highlights = "Baby is ready for the world! Plump with healthy body fat and settled in head-down position.",
                motherTips = "Monitor labor signs: regular rhythmic contractions, water breaking, or bloody show."
            )
        }
    }
}
