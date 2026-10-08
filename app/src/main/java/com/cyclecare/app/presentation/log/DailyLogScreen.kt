package com.cyclecare.app.presentation.log

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cyclecare.app.R
import com.cyclecare.app.data.repository.CycleCareRepository
import com.cyclecare.app.domain.model.DailyLog
import kotlinx.coroutines.launch
import java.time.LocalDate

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun DailyLogScreen(
    repository: CycleCareRepository,
    modifier: Modifier = Modifier
) {
    val coroutineScope = rememberCoroutineScope()
    var selectedDate by remember { mutableStateOf(LocalDate.now()) }

    var activeUserId by remember { mutableStateOf("") }
    LaunchedEffect(Unit) {
        activeUserId = repository.getActiveUserId()
    }

    val existingLog by repository.getDailyLogFlow(activeUserId, selectedDate).collectAsState(initial = null)

    var mood by remember { mutableStateOf("Bình thường") }
    var discharge by remember { mutableStateOf("Khô ráo") }
    var crampsLevel by remember { mutableFloatStateOf(1f) }
    var libido by remember { mutableFloatStateOf(2f) }
    var sleepHours by remember { mutableFloatStateOf(7.5f) }
    var activity by remember { mutableStateOf("Đi bộ nhẹ") }
    var symptoms by remember { mutableStateOf(setOf<String>()) }
    var note by remember { mutableStateOf("") }
    var isSaved by remember { mutableStateOf(false) }

    LaunchedEffect(existingLog) {
        existingLog?.let {
            mood = it.mood ?: "Bình thường"
            discharge = it.discharge ?: "Khô ráo"
            crampsLevel = (it.crampsLevel ?: 1).toFloat()
            libido = (it.libido ?: 2).toFloat()
            sleepHours = (it.sleepHours ?: 7.5).toFloat()
            activity = it.activity ?: "Đi bộ nhẹ"
            symptoms = it.symptoms.toSet()
            note = it.note ?: ""
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp)
    ) {
        Text(
            text = stringResource(R.string.daily_log_title),
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = "Hôm nay, ngày ${selectedDate.dayOfMonth} tháng ${selectedDate.monthValue}",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(20.dp))

        // Mood Section
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = stringResource(R.string.section_mood), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(12.dp))
                val moods = listOf("Vui vẻ", "Nhạy cảm", "Lo lắng", "Mệt mỏi", "Bình thường", "Cáu kỉnh")
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    moods.forEach { item ->
                        ChipItem(text = item, isSelected = mood == item) {
                            mood = item
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Discharge Section
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = "Dịch âm đạo & Dấu hiệu", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(12.dp))
                val discharges = listOf("Khô ráo", "Dính", "Dạng kem", "Lòng trắng trứng", "Ra máu nhẹ")
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    discharges.forEach { item ->
                        ChipItem(text = item, isSelected = discharge == item) {
                            discharge = item
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Cramps & Libido Section
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "Đau bụng kinh (Mức ${crampsLevel.toInt()}/5)",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Slider(
                    value = crampsLevel,
                    onValueChange = { crampsLevel = it },
                    valueRange = 0f..5f,
                    steps = 4,
                    colors = SliderDefaults.colors(thumbColor = MaterialTheme.colorScheme.primary, activeTrackColor = MaterialTheme.colorScheme.primary)
                )

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "Ham muốn tình dục (Mức ${libido.toInt()}/5)",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Slider(
                    value = libido,
                    onValueChange = { libido = it },
                    valueRange = 0f..5f,
                    steps = 4,
                    colors = SliderDefaults.colors(thumbColor = MaterialTheme.colorScheme.secondary, activeTrackColor = MaterialTheme.colorScheme.secondary)
                )

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "Thời gian ngủ: ${String.format("%.1f", sleepHours)} giờ",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Slider(
                    value = sleepHours,
                    onValueChange = { sleepHours = it },
                    valueRange = 3f..12f,
                    steps = 17,
                    colors = SliderDefaults.colors(thumbColor = MaterialTheme.colorScheme.tertiary, activeTrackColor = MaterialTheme.colorScheme.tertiary)
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Physical Activity Section
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = "Hoạt động thể chất", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(12.dp))
                val activities = listOf("Nghỉ ngơi", "Yoga", "Đi bộ nhẹ", "Chạy bộ", "Gym / Thể lực", "Bơi lội")
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    activities.forEach { item ->
                        ChipItem(text = item, isSelected = activity == item) {
                            activity = item
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Symptoms Multi-Select Section
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = stringResource(R.string.section_symptoms), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(12.dp))
                val symptomOptions = listOf("Đau đầu", "Đầy hơi", "Căng tức ngực", "Nổi mụn", "Đau thắt lưng", "Thèm ngọt", "Mất ngủ", "Bốc hỏa")
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    symptomOptions.forEach { item ->
                        val isSelected = symptoms.contains(item)
                        ChipItem(text = item, isSelected = isSelected) {
                            symptoms = if (isSelected) symptoms - item else symptoms + item
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Note Section
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = stringResource(R.string.section_note), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = note,
                    onValueChange = { note = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Ghi lại cảm xúc hoặc sự kiện hôm nay…") },
                    shape = RoundedCornerShape(12.dp),
                    maxLines = 4
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Save Button
        Button(
            onClick = {
                coroutineScope.launch {
                    val log = DailyLog(
                        id = existingLog?.id ?: "",
                        userId = activeUserId,
                        logDate = selectedDate,
                        mood = mood,
                        discharge = discharge,
                        crampsLevel = crampsLevel.toInt(),
                        libido = libido.toInt(),
                        sleepHours = sleepHours.toDouble(),
                        activity = activity,
                        symptoms = symptoms.toList(),
                        note = note
                    )
                    repository.saveDailyLog(log)
                    isSaved = true
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(54.dp),
            shape = RoundedCornerShape(27.dp),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
        ) {
            Text(if (isSaved) "Đã lưu thành công!" else stringResource(R.string.btn_save_log), style = MaterialTheme.typography.labelLarge)
        }
    }
}

@Composable
private fun ChipItem(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(16.dp))
            .background(
                if (isSelected) MaterialTheme.colorScheme.primary
                else MaterialTheme.colorScheme.surfaceVariant
            )
            .clickable { onClick() }
            .padding(horizontal = 14.dp, vertical = 8.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (isSelected) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimary,
                    modifier = Modifier.size(14.dp)
                )
                Spacer(modifier = Modifier.size(4.dp))
            }
            Text(
                text = text,
                style = MaterialTheme.typography.bodyMedium,
                color = if (isSelected) MaterialTheme.colorScheme.onPrimary
                else MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
