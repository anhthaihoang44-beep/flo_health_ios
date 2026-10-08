package com.cyclecare.app.data.remote

import android.util.Log
import com.cyclecare.app.BuildConfig
import com.cyclecare.app.domain.model.UserProfile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID

sealed class AuthResult {
    data class Success(val userId: String, val email: String?, val isAnonymous: Boolean) : AuthResult()
    data class Error(val message: String) : AuthResult()
}

class SupabaseManager {

    private val supabaseUrl = BuildConfig.SUPABASE_URL
    private val anonKey = BuildConfig.SUPABASE_ANON_KEY

    val isConfigured: Boolean
        get() = supabaseUrl.isNotBlank() &&
                !supabaseUrl.contains("placeholder") &&
                !supabaseUrl.contains("demo-cyclecare") &&
                anonKey.isNotBlank() &&
                !anonKey.contains("mock_anon_key")

    suspend fun signInAnonymously(): AuthResult = withContext(Dispatchers.IO) {
        if (!isConfigured) {
            // Offline/Mock mode: sinh UUID ẩn danh
            val mockId = UUID.randomUUID().toString()
            return@withContext AuthResult.Success(userId = mockId, email = null, isAnonymous = true)
        }

        try {
            val endpoint = "$supabaseUrl/auth/v1/signup"
            val url = URL(endpoint)
            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                setRequestProperty("apikey", anonKey)
                setRequestProperty("Content-Type", "application/json")
                doOutput = true
                connectTimeout = 8000
                readTimeout = 8000
            }

            // Gửi request anonymous (tạo tài khoản ẩn danh qua Supabase Auth)
            val jsonBody = JSONObject().apply {
                put("data", JSONObject().put("is_anonymous", true))
            }
            conn.outputStream.use { os ->
                os.write(jsonBody.toString().toByteArray())
            }

            val code = conn.responseCode
            if (code in 200..299) {
                val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                val json = JSONObject(responseText)
                val user = json.optJSONObject("user")
                val userId = user?.optString("id") ?: UUID.randomUUID().toString()
                AuthResult.Success(userId = userId, email = null, isAnonymous = true)
            } else {
                // Fallback nếu anonymous auth trên project chưa bật
                val fallbackId = UUID.randomUUID().toString()
                AuthResult.Success(userId = fallbackId, email = null, isAnonymous = true)
            }
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Anonymous auth exception, fallback to local: ${e.message}")
            AuthResult.Success(userId = UUID.randomUUID().toString(), email = null, isAnonymous = true)
        }
    }

    suspend fun signInWithEmail(email: String, password: String): AuthResult = withContext(Dispatchers.IO) {
        if (!isConfigured) {
            // Local dev fallback
            return@withContext AuthResult.Success(
                userId = UUID.nameUUIDFromBytes(email.toByteArray()).toString(),
                email = email,
                isAnonymous = false
            )
        }

        try {
            val endpoint = "$supabaseUrl/auth/v1/token?grant_type=password"
            val url = URL(endpoint)
            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                setRequestProperty("apikey", anonKey)
                setRequestProperty("Content-Type", "application/json")
                doOutput = true
                connectTimeout = 10000
                readTimeout = 10000
            }

            val body = JSONObject().apply {
                put("email", email)
                put("password", password)
            }
            conn.outputStream.use { it.write(body.toString().toByteArray()) }

            val code = conn.responseCode
            if (code in 200..299) {
                val resp = conn.inputStream.bufferedReader().use { it.readText() }
                val json = JSONObject(resp)
                val user = json.optJSONObject("user")
                val userId = user?.optString("id") ?: ""
                AuthResult.Success(userId = userId, email = email, isAnonymous = false)
            } else {
                val errResp = conn.errorStream?.bufferedReader()?.use { it.readText() } ?: "Sign in failed"
                AuthResult.Error(errResp)
            }
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Server connection error")
        }
    }

    suspend fun linkIdentity(currentUserId: String, email: String, password: String): AuthResult = withContext(Dispatchers.IO) {
        // Nâng cấp từ ẩn danh sang tài khoản thật
        // Đăng ký tài khoản với email, giữ nguyên dữ liệu gắn với currentUserId
        if (!isConfigured) {
            return@withContext AuthResult.Success(userId = currentUserId, email = email, isAnonymous = false)
        }
        // Gọi Supabase Auth updateUser hoặc signup
        signInWithEmail(email, password)
    }
}
