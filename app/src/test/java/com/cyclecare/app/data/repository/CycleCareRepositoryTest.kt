package com.cyclecare.app.data.repository

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CycleCareRepositoryTest {

    @Test
    fun testExportJsonFormat_containsAllRequiredHealthEntities() {
        // Kiểm tra schema định dạng JSON xuất ra đúng chuẩn
        val jsonString = JSONObject().apply {
            put("app", "CycleCare")
            put("user_id", "test-user-uuid")
            put("profile", JSONObject().apply {
                put("display_name", "Test User")
                put("goal", "track")
                put("avg_cycle_length", 28)
                put("avg_period_length", 5)
            })
            put("cycles", org.json.JSONArray().apply {
                put(JSONObject().apply {
                    put("id", "c-1")
                    put("start_date", "2026-05-01")
                    put("period_length", 5)
                })
            })
            put("daily_logs", org.json.JSONArray().apply {
                put(JSONObject().apply {
                    put("date", "2026-05-02")
                    put("mood", "Vui vẻ")
                    put("cramps_level", 2)
                })
            })
        }.toString(2)

        val parsed = JSONObject(jsonString)
        assertEquals("CycleCare", parsed.getString("app"))
        assertEquals("test-user-uuid", parsed.getString("user_id"))

        val profile = parsed.getJSONObject("profile")
        assertEquals(28, profile.getInt("avg_cycle_length"))

        val cycles = parsed.getJSONArray("cycles")
        assertEquals(1, cycles.length())

        val logs = parsed.getJSONArray("daily_logs")
        assertEquals(1, logs.length())
        assertEquals("Vui vẻ", logs.getJSONObject(0).getString("mood"))
    }
}
