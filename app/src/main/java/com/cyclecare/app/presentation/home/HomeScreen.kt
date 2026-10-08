package com.cyclecare.app.presentation.home

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cyclecare.app.R
import com.cyclecare.app.core.theme.FertilePurple
import com.cyclecare.app.core.theme.PeriodRed
import com.cyclecare.app.data.repository.CycleCareRepository
import com.cyclecare.app.domain.model.Cycle
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.temporal.ChronoUnit

@Composable
fun HomeScreen(
    repository: CycleCareRepository,
    modifier: Modifier = Modifier,
    onNavigateToLog: () -> Unit
) {
    val profile by repository.getProfileFlow().collectAsState(initial = null)
    val coroutineScope = rememberCoroutineScope()

    val cycleLength = profile?.avgCycleLength ?: 28
    val periodLength = profile?.avgPeriodLength ?: 5
    val lastPeriodDate = profile?.lastPeriodStartDate ?: LocalDate.now().minusDays(10)

    val daysSinceLastPeriod = ChronoUnit.DAYS.between(lastPeriodDate, LocalDate.now()).toInt()
    val currentCycleDay = (daysSinceLastPeriod % cycleLength) + 1
    val daysUntilNextPeriod = cycleLength - currentCycleDay

    // Fertility calculation
    val ovulationDay = cycleLength - 14
    val isFertileWindow = currentCycleDay in (ovulationDay - 5)..(ovulationDay + 1)
    val isOvulation = currentCycleDay == ovulationDay
    val isPeriodDays = currentCycleDay <= periodLength

    val progress = (currentCycleDay.toFloat() / cycleLength.toFloat()).coerceIn(0.05f, 1f)
    val animatedProgress by animateFloatAsState(
        targetValue = progress,
        animationSpec = tween(durationMillis = 1200),
        label = "CycleProgress"
    )

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Top Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Xin chào, ${profile?.displayName ?: "Bạn"}",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = LocalDate.now().toString(),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Favorite,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(28.dp))

        // Cycle Wheel (Flo inspired canvas)
        Box(
            modifier = Modifier.size(280.dp),
            contentAlignment = Alignment.Center
        ) {
            val primaryColor = MaterialTheme.colorScheme.primary
            val trackColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f)
            val highlightColor = if (isPeriodDays) PeriodRed else if (isFertileWindow) FertilePurple else primaryColor

            Canvas(modifier = Modifier.fillMaxSize()) {
                val strokeWidth = 22.dp.toPx()
                // Background Track
                drawCircle(
                    color = trackColor,
                    style = Stroke(width = strokeWidth)
                )
                // Progress Arc
                drawArc(
                    brush = Brush.sweepGradient(
                        colors = listOf(primaryColor, highlightColor, primaryColor)
                    ),
                    startAngle = -90f,
                    sweepAngle = 360f * animatedProgress,
                    useCenter = false,
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                )
            }

            // Wheel Center Text
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = stringResource(R.string.cycle_day_indicator, currentCycleDay),
                    style = MaterialTheme.typography.displayLarge.copy(fontSize = 32.sp, fontWeight = FontWeight.Bold),
                    color = highlightColor
                )
                Text(
                    text = stringResource(R.string.cycle_day_of_cycle),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(12.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Text(
                        text = if (daysUntilNextPeriod > 0)
                            stringResource(R.string.days_until_period, daysUntilNextPeriod)
                        else stringResource(R.string.period_starts_today),
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                Text(
                    text = if (isOvulation) stringResource(R.string.fertile_chance_ovulation)
                    else if (isFertileWindow) stringResource(R.string.fertile_chance_high)
                    else stringResource(R.string.fertile_chance_low),
                    style = MaterialTheme.typography.labelSmall,
                    color = if (isFertileWindow) FertilePurple else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Spacer(modifier = Modifier.height(28.dp))

        // Quick Action Button: Ghi nhận kỳ kinh
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Button(
                onClick = {
                    coroutineScope.launch {
                        profile?.let { p ->
                            val updatedProfile = p.copy(lastPeriodStartDate = LocalDate.now())
                            repository.saveProfile(updatedProfile)
                            repository.saveCycle(
                                Cycle(
                                    id = "",
                                    userId = p.id,
                                    startDate = LocalDate.now(),
                                    periodLength = p.avgPeriodLength
                                )
                            )
                        }
                    }
                },
                modifier = Modifier
                    .weight(1f)
                    .height(52.dp),
                shape = RoundedCornerShape(26.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PeriodRed)
            ) {
                Icon(Icons.Default.WaterDrop, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text(stringResource(R.string.btn_log_period), style = MaterialTheme.typography.labelLarge)
            }

            Button(
                onClick = onNavigateToLog,
                modifier = Modifier
                    .weight(1f)
                    .height(52.dp),
                shape = RoundedCornerShape(26.dp),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary)
            ) {
                Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text("Ghi nhật ký", style = MaterialTheme.typography.labelLarge)
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Phase Health Advice Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(18.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.AutoAwesome,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = if (isPeriodDays) "Pha Hành Kinh: Hãy nghỉ ngơi nhẹ nhàng"
                        else if (isFertileWindow) "Pha Nang Trứng: Năng lượng đạt đỉnh"
                        else "Pha Hoàng Thể: Lắng nghe cơ thể",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = if (isPeriodDays)
                        "Mức hormone estrogen và progesterone đang ở mức thấp. Hãy bổ sung thực phẩm giàu chất sắt, giữ ấm cơ thể và ngủ đủ giấc."
                    else if (isFertileWindow)
                        "Cửa sổ thụ thai đang mở. Nồng độ estrogen tăng cao giúp bạn cảm thấy tự tin, nhiều năng lượng và làn da tươi sáng."
                    else
                        "Progesterone tăng cao có thể gây cảm giác thèm ăn hoặc mệt mỏi nhẹ. Hãy ưu tiên đồ ăn tươi, hạn chế caffeine.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
