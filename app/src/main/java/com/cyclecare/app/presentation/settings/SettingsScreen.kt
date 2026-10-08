package com.cyclecare.app.presentation.settings

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DeleteForever
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.cyclecare.app.R
import com.cyclecare.app.core.security.SessionManager
import com.cyclecare.app.data.remote.AuthResult
import com.cyclecare.app.data.repository.CycleCareRepository
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(
    repository: CycleCareRepository,
    sessionManager: SessionManager,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val profile by repository.getProfileFlow().collectAsState(initial = null)
    val isBiometricEnabled by sessionManager.isBiometricEnabledFlow.collectAsState(initial = false)

    var showDeleteConfirmDialog by remember { mutableStateOf(false) }
    var showLinkIdentityDialog by remember { mutableStateOf(false) }
    var showExportDialog by remember { mutableStateOf(false) }
    var exportedJsonText by remember { mutableStateOf("") }

    var linkEmail by remember { mutableStateOf("") }
    var linkPassword by remember { mutableStateOf("") }
    var linkErrorMessage by remember { mutableStateOf("") }

    var periodReminderEnabled by remember { mutableStateOf(true) }
    var ovulationReminderEnabled by remember { mutableStateOf(true) }
    var dailyLogReminderEnabled by remember { mutableStateOf(true) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp)
    ) {
        Text(
            text = stringResource(R.string.settings_title),
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(20.dp))

        // Account status card
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(18.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.size(10.dp))
                    Text(
                        text = if (profile?.isAnonymous == true) "Anonymous Mode" else "Registered Account",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }

                if (profile?.isAnonymous == true) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = stringResource(R.string.settings_anonymous_notice),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(14.dp))
                    Button(
                        onClick = {
                            linkErrorMessage = ""
                            showLinkIdentityDialog = true
                        },
                        shape = RoundedCornerShape(20.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Text(stringResource(R.string.settings_link_account))
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(18.dp))

        // Notifications Settings Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(18.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.NotificationsActive,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.size(10.dp))
                    Text(
                        text = "Reminder Settings",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(modifier = Modifier.height(14.dp))

                ReminderSwitchItem(
                    title = "Period reminder (1 day before)",
                    checked = periodReminderEnabled,
                    onCheckedChange = { periodReminderEnabled = it }
                )
                ReminderSwitchItem(
                    title = "Ovulation day reminder",
                    checked = ovulationReminderEnabled,
                    onCheckedChange = { ovulationReminderEnabled = it }
                )
                ReminderSwitchItem(
                    title = "Daily log reminder (8:00 PM)",
                    checked = dailyLogReminderEnabled,
                    onCheckedChange = { dailyLogReminderEnabled = it }
                )
            }
        }

        Spacer(modifier = Modifier.height(18.dp))

        // Security Card: Biometric Lock
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Row(
                modifier = Modifier
                    .padding(18.dp)
                    .fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Fingerprint,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.secondary,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.size(12.dp))
                    Text(
                        text = stringResource(R.string.settings_biometric_lock),
                        style = MaterialTheme.typography.titleMedium
                    )
                }
                Switch(
                    checked = isBiometricEnabled,
                    onCheckedChange = { enabled ->
                        coroutineScope.launch {
                            sessionManager.setBiometricEnabled(enabled)
                            Toast.makeText(context, if (enabled) "Biometric / PIN lock enabled" else "App lock disabled", Toast.LENGTH_SHORT).show()
                        }
                    },
                    colors = SwitchDefaults.colors(checkedThumbColor = MaterialTheme.colorScheme.secondary)
                )
            }
        }

        Spacer(modifier = Modifier.height(18.dp))

        // Export Data
        OutlinedButton(
            onClick = {
                coroutineScope.launch {
                    val uid = repository.getActiveUserId()
                    val json = repository.exportAllUserDataJson(uid)
                    exportedJsonText = json
                    showExportDialog = true
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            shape = RoundedCornerShape(26.dp)
        ) {
            Icon(Icons.Default.Download, contentDescription = null)
            Spacer(modifier = Modifier.size(8.dp))
            Text(stringResource(R.string.settings_export_data))
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Delete Data Button
        Button(
            onClick = { showDeleteConfirmDialog = true },
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            shape = RoundedCornerShape(26.dp),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
        ) {
            Icon(Icons.Default.DeleteForever, contentDescription = null)
            Spacer(modifier = Modifier.size(8.dp))
            Text(stringResource(R.string.settings_delete_all_data))
        }

        Spacer(modifier = Modifier.height(28.dp))

        // Medical Disclaimer
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.size(6.dp))
                    Text(
                        text = stringResource(R.string.settings_medical_disclaimer),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = stringResource(R.string.medical_disclaimer_text),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }

    // Link Identity Dialog
    if (showLinkIdentityDialog) {
        AlertDialog(
            onDismissRequest = { showLinkIdentityDialog = false },
            title = { Text("Link Account (Upgrade Identity)") },
            text = {
                Column {
                    Text("Enter email and password to link your account. All your cycle and log data will be securely preserved.")
                    Spacer(modifier = Modifier.height(14.dp))
                    OutlinedTextField(
                        value = linkEmail,
                        onValueChange = { linkEmail = it },
                        label = { Text("Email") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    OutlinedTextField(
                        value = linkPassword,
                        onValueChange = { linkPassword = it },
                        label = { Text("Password") },
                        visualTransformation = PasswordVisualTransformation(),
                        modifier = Modifier.fillMaxWidth()
                    )
                    if (linkErrorMessage.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(linkErrorMessage, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (linkEmail.isBlank() || linkPassword.length < 6) {
                            linkErrorMessage = "Please enter a valid email and password with at least 6 characters."
                            return@Button
                        }
                        coroutineScope.launch {
                            val res = repository.linkIdentity(linkEmail, linkPassword)
                            if (res is AuthResult.Success) {
                                showLinkIdentityDialog = false
                                Toast.makeText(context, "Account linked successfully!", Toast.LENGTH_SHORT).show()
                            } else if (res is AuthResult.Error) {
                                linkErrorMessage = res.message
                            }
                        }
                    }
                ) {
                    Text("Confirm")
                }
            },
            dismissButton = {
                TextButton(onClick = { showLinkIdentityDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Export JSON Dialog
    if (showExportDialog) {
        AlertDialog(
            onDismissRequest = { showExportDialog = false },
            title = { Text("Personal Data (JSON Export)") },
            text = {
                Column {
                    Text("Your cycle and health log data has been exported into secure JSON format:")
                    Spacer(modifier = Modifier.height(10.dp))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(MaterialTheme.colorScheme.surfaceVariant)
                            .padding(10.dp)
                    ) {
                        Text(
                            text = exportedJsonText,
                            style = MaterialTheme.typography.bodySmall,
                            modifier = Modifier.verticalScroll(rememberScrollState())
                        )
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        val clip = ClipData.newPlainText("CycleCare_Data_Export", exportedJsonText)
                        clipboard.setPrimaryClip(clip)
                        Toast.makeText(context, "Copied JSON to clipboard!", Toast.LENGTH_SHORT).show()
                        showExportDialog = false
                    }
                ) {
                    Text("Copy to Clipboard")
                }
            },
            dismissButton = {
                TextButton(onClick = { showExportDialog = false }) {
                    Text("Close")
                }
            }
        )
    }

    // Delete Confirm Dialog
    if (showDeleteConfirmDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirmDialog = false },
            title = { Text("Confirm Data Deletion") },
            text = { Text("All your cycle and health log data will be permanently deleted from this device and cannot be recovered.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        coroutineScope.launch {
                            profile?.let { repository.clearAllData(it.id) }
                            showDeleteConfirmDialog = false
                            Toast.makeText(context, "All data has been wiped.", Toast.LENGTH_SHORT).show()
                        }
                    }
                ) {
                    Text("Delete Permanently", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirmDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun ReminderSwitchItem(
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = title, style = MaterialTheme.typography.bodyMedium)
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(checkedThumbColor = MaterialTheme.colorScheme.primary)
        )
    }
}
