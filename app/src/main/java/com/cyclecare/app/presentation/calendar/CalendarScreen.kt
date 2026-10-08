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
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cyclecare.app.R
import com.cyclecare.app.core.theme.FertileLight
import com.cyclecare.app.core.theme.FertilePurple
import com.cyclecare.app.core.theme.OvulationTeal
import com.cyclecare.app.core.theme.PeriodLightPink
import com.cyclecare.app.core.theme.PeriodRed
import com.cyclecare.app.data.repository.CycleCareRepository
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.TextStyle
import java.util.Locale

@Composable
fun CalendarScreen(
    repository: CycleCareRepository,
    modifier: Modifier = Modifier,
    onOpenLogForDate: (LocalDate) -> Unit
) {
    val profile by repository.getProfileFlow().collectAsState(initial = null)
    var currentYearMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDate by remember { mutableStateOf(LocalDate.now()) }

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
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Tháng trước")
            }

            Text(
                text = "${currentYearMonth.month.getDisplayName(TextStyle.FULL, Locale("vi"))} ${currentYearMonth.year}",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )

            IconButton(onClick = { currentYearMonth = currentYearMonth.plusMonths(1) }) {
                Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Tháng sau")
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Weekday Headers
        Row(modifier = Modifier.fillMaxWidth()) {
            val weekdays = listOf("CN", "T2", "T3", "T4", "T5", "T6", "T7")
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

                    // Mock logic chu kỳ hiển thị màu
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
                                onOpenLogForDate(date)
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
                    text = "Chú thích màu sắc",
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
