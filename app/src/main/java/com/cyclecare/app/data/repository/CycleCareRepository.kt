package com.cyclecare.app.data.repository

import com.cyclecare.app.core.security.SessionManager
import com.cyclecare.app.data.local.CycleCareDatabase
import com.cyclecare.app.data.local.entity.ArticleEntity
import com.cyclecare.app.data.local.entity.CycleEntity
import com.cyclecare.app.data.local.entity.DailyLogEntity
import com.cyclecare.app.data.local.entity.ProfileEntity
import com.cyclecare.app.data.remote.AuthResult
import com.cyclecare.app.data.remote.SupabaseManager
import com.cyclecare.app.domain.model.Article
import com.cyclecare.app.domain.model.Cycle
import com.cyclecare.app.domain.model.DailyLog
import com.cyclecare.app.domain.model.HealthGoal
import com.cyclecare.app.domain.model.UserProfile
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.UUID

class CycleCareRepository(
    private val database: CycleCareDatabase,
    private val sessionManager: SessionManager,
    private val supabaseManager: SupabaseManager
) {
    private val dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE

    // --------------------------------------------------------------------------
    // AUTHENTICATION & PROFILE
    // --------------------------------------------------------------------------
    suspend fun getActiveUserId(): String {
        return sessionManager.getOrCreateUserId()
    }

    suspend fun signInAnonymously(): AuthResult {
        val result = supabaseManager.signInAnonymously()
        if (result is AuthResult.Success) {
            sessionManager.saveSession(userId = result.userId, isAnonymous = true)
        }
        return result
    }

    suspend fun signInWithEmail(email: String, pass: String): AuthResult {
        val result = supabaseManager.signInWithEmail(email, pass)
        if (result is AuthResult.Success) {
            sessionManager.saveSession(userId = result.userId, isAnonymous = false, email = email)
        }
        return result
    }

    suspend fun linkIdentity(email: String, pass: String): AuthResult {
        val currentUserId = getActiveUserId()
        val result = supabaseManager.linkIdentity(currentUserId, email, pass)
        if (result is AuthResult.Success) {
            sessionManager.saveSession(userId = currentUserId, isAnonymous = false, email = email)
            // Cập nhật profile isAnonymous = false
            val currentProfile = database.profileDao().getProfile()
            if (currentProfile != null) {
                database.profileDao().updateProfile(currentProfile.copy(isAnonymous = false))
            }
        }
        return result
    }

    fun getProfileFlow(): Flow<UserProfile?> {
        return database.profileDao().getProfileFlow().map { entity ->
            entity?.let {
                UserProfile(
                    id = it.id,
                    displayName = it.displayName,
                    birthYear = it.birthYear,
                    goal = HealthGoal.fromKey(it.goal),
                    avgCycleLength = it.avgCycleLength,
                    avgPeriodLength = it.avgPeriodLength,
                    isAnonymous = it.isAnonymous,
                    lastPeriodStartDate = it.lastPeriodStartDate?.let { d -> LocalDate.parse(d, dateFormatter) }
                )
            }
        }
    }

    suspend fun saveProfile(profile: UserProfile) {
        val entity = ProfileEntity(
            id = profile.id,
            displayName = profile.displayName,
            birthYear = profile.birthYear,
            goal = profile.goal.key,
            avgCycleLength = profile.avgCycleLength,
            avgPeriodLength = profile.avgPeriodLength,
            isAnonymous = profile.isAnonymous,
            lastPeriodStartDate = profile.lastPeriodStartDate?.format(dateFormatter)
        )
        database.profileDao().insertProfile(entity)
    }

    // --------------------------------------------------------------------------
    // CYCLES
    // --------------------------------------------------------------------------
    fun getCyclesFlow(userId: String): Flow<List<Cycle>> {
        return database.cycleDao().getCyclesFlow(userId).map { list ->
            list.map { entity ->
                Cycle(
                    id = entity.id,
                    userId = entity.userId,
                    startDate = LocalDate.parse(entity.startDate, dateFormatter),
                    endDate = entity.endDate?.let { LocalDate.parse(it, dateFormatter) },
                    cycleLength = entity.cycleLength,
                    periodLength = entity.periodLength,
                    isPredicted = entity.isPredicted
                )
            }
        }
    }

    suspend fun saveCycle(cycle: Cycle) {
        val entity = CycleEntity(
            id = cycle.id.ifEmpty { UUID.randomUUID().toString() },
            userId = cycle.userId,
            startDate = cycle.startDate.format(dateFormatter),
            endDate = cycle.endDate?.format(dateFormatter),
            cycleLength = cycle.cycleLength,
            periodLength = cycle.periodLength,
            isPredicted = cycle.isPredicted
        )
        database.cycleDao().insertCycle(entity)
    }

    suspend fun deleteCycle(cycleId: String) {
        database.cycleDao().deleteCycleById(cycleId)
    }

    // --------------------------------------------------------------------------
    // DAILY LOGS
    // --------------------------------------------------------------------------
    fun getDailyLogFlow(userId: String, date: LocalDate): Flow<DailyLog?> {
        return database.dailyLogDao().getLogByDateFlow(userId, date.format(dateFormatter)).map { entity ->
            entity?.let {
                DailyLog(
                    id = it.id,
                    userId = it.userId,
                    logDate = LocalDate.parse(it.logDate, dateFormatter),
                    mood = it.mood,
                    discharge = it.discharge,
                    crampsLevel = it.crampsLevel,
                    libido = it.libido,
                    sleepHours = it.sleepHours,
                    sleepQuality = it.sleepQuality,
                    activity = it.activity,
                    symptoms = if (it.symptoms.isBlank()) emptyList() else it.symptoms.split(",").filter { s -> s.isNotBlank() },
                    note = it.note
                )
            }
        }
    }

    suspend fun saveDailyLog(log: DailyLog) {
        val entity = DailyLogEntity(
            id = log.id.ifEmpty { UUID.randomUUID().toString() },
            userId = log.userId,
            logDate = log.logDate.format(dateFormatter),
            mood = log.mood,
            discharge = log.discharge,
            crampsLevel = log.crampsLevel,
            libido = log.libido,
            sleepHours = log.sleepHours,
            sleepQuality = log.sleepQuality,
            activity = log.activity,
            symptoms = log.symptoms.joinToString(","),
            note = log.note
        )
        database.dailyLogDao().insertLog(entity)
    }

    // --------------------------------------------------------------------------
    // ARTICLES & SEEDING
    // --------------------------------------------------------------------------
    fun getArticlesFlow(locale: String = "vi"): Flow<List<Article>> {
        return database.articleDao().getArticlesByLocaleFlow(locale).map { list ->
            list.map {
                Article(
                    id = it.id,
                    title = it.title,
                    body = it.body,
                    category = it.category,
                    locale = it.locale,
                    isPremium = it.isPremium
                )
            }
        }
    }

    suspend fun seedSampleArticlesIfEmpty() {
        val existing = database.articleDao().getArticlesByLocaleFlow("vi").first()
        if (existing.isEmpty()) {
            val samples = listOf(
                ArticleEntity(
                    id = "art-1",
                    title = "Hiểu Rõ 4 Pha Của Chu Kỳ Kinh Nguyệt",
                    body = "Chu kỳ kinh nguyệt trung bình kéo dài 28 ngày và được chia thành 4 pha chính: Pha hành kinh, Pha nang trứng, Pha rụng trứng và Pha hoàng thể. Việc theo dõi từng pha giúp bạn tối ưu hóa chế độ dinh dưỡng và kiểm soát năng lượng.",
                    category = "cycle",
                    locale = "vi",
                    isPremium = false
                ),
                ArticleEntity(
                    id = "art-2",
                    title = "Cửa Sổ Thụ Thai & Cách Nhận Biết Thời Điểm Vàng",
                    body = "Cửa sổ thụ thai bao gồm 5 ngày trước khi rụng trứng và ngày rụng trứng. Dấu hiệu nhận biết: dịch âm đạo dạng lòng trắng trứng sống và nhiệt độ cơ thể cơ bản tăng nhẹ.",
                    category = "fertility",
                    locale = "vi",
                    isPremium = false
                ),
                ArticleEntity(
                    id = "art-3",
                    title = "Giảm Đau Bụng Kinh Tự Nhiên Không Cần Thuốc",
                    body = "Chườm ấm vùng bụng dưới bằng túi chườm (40°C), uống trà gừng ấm, tập yoga nhẹ nhàng và bổ sung magie trong chế độ ăn hàng ngày.",
                    category = "wellness",
                    locale = "vi",
                    isPremium = false
                )
            )
            database.articleDao().insertArticles(samples)
        }
    }

    // --------------------------------------------------------------------------
    // PREGNANCY
    // --------------------------------------------------------------------------
    fun getActivePregnancyFlow(userId: String): Flow<com.cyclecare.app.domain.model.Pregnancy?> {
        return database.pregnancyDao().getActivePregnancyFlow(userId).map { entity ->
            entity?.let {
                com.cyclecare.app.domain.model.Pregnancy(
                    id = it.id,
                    userId = it.userId,
                    lmpDate = LocalDate.parse(it.lmpDate, dateFormatter),
                    dueDate = LocalDate.parse(it.dueDate, dateFormatter),
                    isActive = it.isActive,
                    endedAt = it.endedAt?.let { d -> LocalDate.parse(d, dateFormatter) }
                )
            }
        }
    }

    suspend fun savePregnancy(pregnancy: com.cyclecare.app.domain.model.Pregnancy) {
        val entity = com.cyclecare.app.data.local.entity.PregnancyEntity(
            id = pregnancy.id.ifEmpty { UUID.randomUUID().toString() },
            userId = pregnancy.userId,
            lmpDate = pregnancy.lmpDate.format(dateFormatter),
            dueDate = pregnancy.dueDate.format(dateFormatter),
            isActive = pregnancy.isActive,
            endedAt = pregnancy.endedAt?.format(dateFormatter)
        )
        database.pregnancyDao().insertOrUpdate(entity)
    }

    // --------------------------------------------------------------------------
    // REMINDERS
    // --------------------------------------------------------------------------
    fun getRemindersFlow(userId: String): Flow<List<com.cyclecare.app.data.local.entity.ReminderEntity>> {
        return database.reminderDao().getRemindersFlow(userId)
    }

    suspend fun saveReminder(reminder: com.cyclecare.app.data.local.entity.ReminderEntity) {
        database.reminderDao().insertOrUpdate(reminder)
    }

    // --------------------------------------------------------------------------
    // PRIVACY: EXPORT & DELETE
    // --------------------------------------------------------------------------
    suspend fun exportAllUserDataJson(userId: String): String {
        val profile = database.profileDao().getProfile()
        val cycles = database.cycleDao().getCycles(userId)
        val logs = database.dailyLogDao().getLogsBetween(userId, "2000-01-01", "2099-12-31")

        val json = org.json.JSONObject().apply {
            put("exported_at", java.time.Instant.now().toString())
            put("app", "CycleCare")
            put("user_id", userId)
            put("profile", org.json.JSONObject().apply {
                put("display_name", profile?.displayName ?: "")
                put("goal", profile?.goal ?: "track")
                put("avg_cycle_length", profile?.avgCycleLength ?: 28)
                put("avg_period_length", profile?.avgPeriodLength ?: 5)
                put("is_anonymous", profile?.isAnonymous ?: true)
            })
            val cyclesArray = org.json.JSONArray()
            cycles.forEach { c ->
                cyclesArray.put(org.json.JSONObject().apply {
                    put("id", c.id)
                    put("start_date", c.startDate)
                    put("end_date", c.endDate ?: "")
                    put("cycle_length", c.cycleLength ?: 0)
                    put("period_length", c.periodLength ?: 0)
                })
            }
            put("cycles", cyclesArray)

            val logsArray = org.json.JSONArray()
            logs.forEach { l ->
                logsArray.put(org.json.JSONObject().apply {
                    put("date", l.logDate)
                    put("mood", l.mood ?: "")
                    put("cramps_level", l.crampsLevel ?: 0)
                    put("libido", l.libido ?: 0)
                    put("symptoms", l.symptoms)
                    put("note", l.note ?: "")
                })
            }
            put("daily_logs", logsArray)
        }
        return json.toString(2)
    }

    suspend fun clearAllData(userId: String) {
        database.cycleDao().clearUserCycles(userId)
        database.dailyLogDao().clearUserLogs(userId)
        database.pregnancyDao().clearUserPregnancies(userId)
        database.reminderDao().clearUserReminders(userId)
        database.profileDao().clearProfile()
        sessionManager.clearSession()
    }
}
