package com.cyclecare.app.presentation.calendar

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.cyclecare.app.R
import com.cyclecare.app.core.theme.FertileLight
import com.cyclecare.app.core.theme.FertilePurple
import com.cyclecare.app.core.theme.OvulationTeal
import com.cyclecare.app.core.theme.PeriodLightPink
import com.cyclecare.app.core.theme.PeriodRed
import com.cyclecare.app.data.repository.CycleCareRepository
import com.cyclecare.app.domain.model.Cycle
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.TextStyle
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarScreen(
    repository: CycleCareRepository,
    modifier: Modifier = Modifier,
    onOpenLogForDate: (LocalDate) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val profile by repository.getProfileFlow().collectAsState(initial = null)
    var currentYearMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDate by remember { mutableStateOf<LocalDate?>(null) }
    var showEditSheet by remember { mutableStateOf(false) }

    val daysInMonth = remember(currentYearMonth) {
        val firstDay = currentYearMonth.atDay(1)
        val dayOfWeekOffset = (firstDay.dayOfWeek.value % 7) // Sunday = 0
        val totalDays = currentYearMonth.lengthOfMonth()

        val list = mutableListOf<LocalDate?>()
        for (i in 0 until dayOfWeekOffset) {
            list.add(null)
        }
        for (day in 1..totalDays) {
            list.add(currentYearMonth.atDay(day))
        }
        list
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Month Navigation Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = { currentYearMonth = currentYearMonth.minusMonths(1) }) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Previous Month")
            }

            Text(
                text = "${currentYearMonth.month.getDisplayName(TextStyle.FULL, Locale.ENGLISH)} ${currentYearMonth.year}",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )

            IconButton(onClick = { currentYearMonth = currentYearMonth.plusMonths(1) }) {
                Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Next Month")
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Weekday Headers
        Row(modifier = Modifier.fillMaxWidth()) {
            val weekdays = listOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
            weekdays.forEach { day ->
                Text(
                    text = day,
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Calendar Grid
        LazyVerticalGrid(
            columns = GridCells.Fixed(7),
            modifier = Modifier.fillMaxWidth()
        ) {
            items(daysInMonth) { date ->
                if (date == null) {
                    Box(modifier = Modifier.aspectRatio(1f))
                } else {
                    val isToday = date == LocalDate.now()
                    val isSelected = date == selectedDate

                    val lastPeriod = profile?.lastPeriodStartDate ?: LocalDate.now().minusDays(10)
                    val daysDiff = java.time.temporal.ChronoUnit.DAYS.between(lastPeriod, date).toInt()
                    val cycleLength = profile?.avgCycleLength ?: 28
                    val periodLength = profile?.avgPeriodLength ?: 5

                    val cycleDay = if (daysDiff >= 0) (daysDiff % cycleLength) + 1 else 0
                    val isPeriod = cycleDay in 1..periodLength
                    val ovulationDay = cycleLength - 14
                    val isOvulation = cycleDay == ovulationDay
                    val isFertile = cycleDay in (ovulationDay - 5)..(ovulationDay + 1)

                    val bgColor = when {
                        isPeriod -> PeriodLightPink
                        isOvulation -> OvulationTeal.copy(alpha = 0.3f)
                        isFertile -> FertileLight
                        else -> Color.Transparent
                    }

                    val textColor = when {
                        isPeriod -> PeriodRed
                        isOvulation -> OvulationTeal
                        isFertile -> FertilePurple
                        else -> MaterialTheme.colorScheme.onSurface
                    }

                    Box(
                        modifier = Modifier
                            .aspectRatio(1f)
                            .padding(2.dp)
                            .clip(CircleShape)
                            .background(bgColor)
                            .border(
                                width = if (isSelected) 2.dp else if (isToday) 1.dp else 0.dp,
                                color = if (isSelected) MaterialTheme.colorScheme.primary else if (isToday) MaterialTheme.colorScheme.outline else Color.Transparent,
                                shape = CircleShape
                            )
                            .clickable {
                                selectedDate = date
                                showEditSheet = true
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = date.dayOfMonth.toString(),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = if (isToday || isSelected) FontWeight.Bold else FontWeight.Normal,
                            color = textColor
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Legends
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(14.dp)) {
                Text(
                    text = "Color Legend (Tap any date to adjust your period)",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    LegendItem(color = PeriodLightPink, text = stringResource(R.string.calendar_legend_period))
                    LegendItem(color = FertileLight, text = stringResource(R.string.calendar_legend_fertile))
                    LegendItem(color = OvulationTeal.copy(alpha = 0.4f), text = stringResource(R.string.calendar_legend_ovulation))
                }
            }
        }
    }

    // Period Editing BottomSheet
    if (showEditSheet && selectedDate != null) {
        val targetDate = selectedDate!!
        ModalBottomSheet(
            onDismissRequest = { showEditSheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp)
            ) {
                Text(
                    text = "${targetDate.month.getDisplayName(TextStyle.FULL, Locale.ENGLISH)} ${targetDate.dayOfMonth}, ${targetDate.year}",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = {
                        coroutineScope.launch {
                            profile?.let { p ->
                                val updated = p.copy(lastPeriodStartDate = targetDate)
                                repository.saveProfile(updated)
                                repository.saveCycle(
                                    Cycle(
                                        id = "",
                                        userId = p.id,
                                        startDate = targetDate,
                                        periodLength = p.avgPeriodLength
                                    )
                                )
                            }
                            showEditSheet = false
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    shape = RoundedCornerShape(25.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = PeriodRed)
                ) {
                    Icon(Icons.Default.WaterDrop, contentDescription = null)
                    Spacer(modifier = Modifier.size(8.dp))
                    Text("Start Period on this Date")
                }

                Spacer(modifier = Modifier.height(10.dp))

                OutlinedButton(
                    onClick = {
                        showEditSheet = false
                        onOpenLogForDate(targetDate)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    shape = RoundedCornerShape(25.dp)
                ) {
                    Icon(Icons.Default.Edit, contentDescription = null)
                    Spacer(modifier = Modifier.size(8.dp))
                    Text("Log Symptoms for this Day")
                }

                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

@Composable
private fun LegendItem(color: Color, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .clip(CircleShape)
                .background(color)
        )
        Text(
            text = " $text",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}
