package com.cyclecare.app.presentation.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.filled.ChildCare
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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cyclecare.app.R
import com.cyclecare.app.core.theme.FertilePurple
import com.cyclecare.app.core.theme.PeriodRed
import com.cyclecare.app.data.repository.CycleCareRepository
import com.cyclecare.app.domain.model.Cycle
import com.cyclecare.app.domain.model.HealthGoal
import com.cyclecare.app.presentation.pregnancy.PregnancyScreen
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
    var isPregnancyModeActive by remember { mutableStateOf(false) }

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

    if (isPregnancyModeActive || profile?.goal == HealthGoal.PREGNANT) {
        Column(modifier = modifier.fillMaxSize()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.End
            ) {
                Button(
                    onClick = { isPregnancyModeActive = false },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Text("Back to Cycle Tracking", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            PregnancyScreen(repository = repository, modifier = Modifier.weight(1f))
        }
        return
    }

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
                    text = "Hello, ${profile?.displayName ?: "You"}",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = "Today: ${LocalDate.now()}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(MaterialTheme.colorScheme.secondaryContainer)
                        .clickable { isPregnancyModeActive = true }
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.ChildCare,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.secondary,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "Pregnancy",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.secondary,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

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

        // Quick Action Button
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
                Text("Log Daily", style = MaterialTheme.typography.labelLarge)
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
                        text = if (isPeriodDays) "Menstrual Phase: Rest & Rejuvenate"
                        else if (isFertileWindow) "Follicular Phase: Energy at Peak"
                        else "Luteal Phase: Listen to Your Body",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = if (isPeriodDays)
                        "Estrogen and progesterone are at baseline levels. Prioritize iron-rich foods, stay warm, and get adequate rest."
                    else if (isFertileWindow)
                        "Fertile window is open. Surging estrogen enhances energy, mood, confidence, and radiant skin."
                    else
                        "Elevated progesterone may cause mild fatigue or food cravings. Prioritize fiber-rich meals and stay hydrated.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
