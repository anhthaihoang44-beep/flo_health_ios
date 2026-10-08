package com.cyclecare.app.core.security

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.util.UUID

private val Context.dataStore by preferencesDataStore(name = "cyclecare_secure_prefs")

class SessionManager(private val context: Context) {

    companion object {
        private val KEY_USER_ID = stringPreferencesKey("user_id")
        private val KEY_IS_ANONYMOUS = booleanPreferencesKey("is_anonymous")
        private val KEY_ONBOARDING_COMPLETED = booleanPreferencesKey("onboarding_completed")
        private val KEY_BIOMETRIC_ENABLED = booleanPreferencesKey("biometric_enabled")
        private val KEY_APP_PIN = stringPreferencesKey("app_pin")
        private val KEY_USER_EMAIL = stringPreferencesKey("user_email")
    }

    val userIdFlow: Flow<String?> = context.dataStore.data.map { it[KEY_USER_ID] }
    val isAnonymousFlow: Flow<Boolean> = context.dataStore.data.map { it[KEY_IS_ANONYMOUS] ?: true }
    val isOnboardingCompletedFlow: Flow<Boolean> = context.dataStore.data.map { it[KEY_ONBOARDING_COMPLETED] ?: false }
    val isBiometricEnabledFlow: Flow<Boolean> = context.dataStore.data.map { it[KEY_BIOMETRIC_ENABLED] ?: false }
    val userEmailFlow: Flow<String?> = context.dataStore.data.map { it[KEY_USER_EMAIL] }

    suspend fun getOrCreateUserId(): String {
        val currentId = context.dataStore.data.first()[KEY_USER_ID]
        if (!currentId.isNullOrEmpty()) {
            return currentId
        }
        val newAnonymousId = UUID.randomUUID().toString()
        saveSession(userId = newAnonymousId, isAnonymous = true)
        return newAnonymousId
    }

    suspend fun saveSession(userId: String, isAnonymous: Boolean, email: String? = null) {
        context.dataStore.edit { prefs ->
            prefs[KEY_USER_ID] = userId
            prefs[KEY_IS_ANONYMOUS] = isAnonymous
            if (email != null) {
                prefs[KEY_USER_EMAIL] = email
            }
        }
    }

    suspend fun setOnboardingCompleted(completed: Boolean) {
        context.dataStore.edit { prefs ->
            prefs[KEY_ONBOARDING_COMPLETED] = completed
        }
    }

    suspend fun setBiometricEnabled(enabled: Boolean) {
        context.dataStore.edit { prefs ->
            prefs[KEY_BIOMETRIC_ENABLED] = enabled
        }
    }

    suspend fun setAppPin(pin: String?) {
        context.dataStore.edit { prefs ->
            if (pin != null) {
                prefs[KEY_APP_PIN] = pin
            } else {
                prefs.remove(KEY_APP_PIN)
            }
        }
    }

    suspend fun clearSession() {
        context.dataStore.edit { prefs ->
            prefs.clear()
        }
    }
}
