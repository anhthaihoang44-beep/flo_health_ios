package com.cyclecare.app.presentation.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cyclecare.app.R
import com.cyclecare.app.core.security.SessionManager
import com.cyclecare.app.data.repository.CycleCareRepository
import com.cyclecare.app.domain.model.Cycle
import com.cyclecare.app.domain.model.HealthGoal
import com.cyclecare.app.domain.model.UserProfile
import kotlinx.coroutines.launch
import java.time.LocalDate

@Composable
fun OnboardingScreen(
    repository: CycleCareRepository,
    sessionManager: SessionManager,
    onOnboardingComplete: () -> Unit
) {
    var step by remember { mutableIntStateOf(1) }
    var selectedGoal by remember { mutableStateOf(HealthGoal.TRACK) }
    var cycleLength by remember { mutableFloatStateOf(28f) }
    var periodLength by remember { mutableFloatStateOf(5f) }
    var lastPeriodStartDate by remember { mutableStateOf(LocalDate.now().minusDays(14)) }

    val coroutineScope = rememberCoroutineScope()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.background,
                        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f)
                    )
                )
            )
            .padding(24.dp)
    ) {
        AnimatedContent(
            targetState = step,
            transitionSpec = { fadeIn() togetherWith fadeOut() },
            label = "OnboardingStep"
        ) { targetStep ->
            when (targetStep) {
                1 -> GoalSelectionStep(
                    selectedGoal = selectedGoal,
                    onGoalSelected = { selectedGoal = it },
                    onNext = { step = 2 }
                )
                2 -> CycleParametersStep(
                    cycleLength = cycleLength,
                    periodLength = periodLength,
                    onCycleLengthChange = { cycleLength = it },
                    onPeriodLengthChange = { periodLength = it },
                    onNext = { step = 3 }
                )
                3 -> FinalStep(
                    selectedGoal = selectedGoal,
                    cycleLength = cycleLength.toInt(),
                    periodLength = periodLength.toInt(),
                    lastPeriodDate = lastPeriodStartDate,
                    onStart = { isAnon ->
                        coroutineScope.launch {
                            val userId = repository.getActiveUserId()
                            val profile = UserProfile(
                                id = userId,
                                displayName = if (isAnon) "Anonymous User" else "You",
                                goal = selectedGoal,
                                avgCycleLength = cycleLength.toInt(),
                                avgPeriodLength = periodLength.toInt(),
                                isAnonymous = isAnon,
                                lastPeriodStartDate = lastPeriodStartDate
                            )
                            repository.saveProfile(profile)
                            // Save initial cycle
                            repository.saveCycle(
                                Cycle(
                                    id = "",
                                    userId = userId,
                                    startDate = lastPeriodStartDate,
                                    cycleLength = cycleLength.toInt(),
                                    periodLength = periodLength.toInt()
                                )
                            )
                            sessionManager.setOnboardingCompleted(true)
                            onOnboardingComplete()
                        }
                    }
                )
            }
        }
    }
}

@Composable
private fun GoalSelectionStep(
    selectedGoal: HealthGoal,
    onGoalSelected: (HealthGoal) -> Unit,
    onNext: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Spacer(modifier = Modifier.height(32.dp))
            Text(
                text = stringResource(R.string.onboarding_welcome_title),
                style = MaterialTheme.typography.displayLarge.copy(fontSize = 28.sp),
                color = MaterialTheme.colorScheme.onBackground
            )
            Spacer(modifier = Modifier.height(10.dp))
            Text(
                text = stringResource(R.string.onboarding_goal_subtitle),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(28.dp))

            val goals = listOf(
                HealthGoal.TRACK to R.string.goal_track,
                HealthGoal.CONCEIVE to R.string.goal_conceive,
                HealthGoal.PREGNANT to R.string.goal_pregnant,
                HealthGoal.PERIMENOPAUSE to R.string.goal_perimenopause
            )

            goals.forEach { (goal, titleRes) ->
                val isSelected = goal == selectedGoal
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .border(
                            width = if (isSelected) 2.dp else 1.dp,
                            color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant,
                            shape = RoundedCornerShape(18.dp)
                        )
                        .clickable { onGoalSelected(goal) },
                    colors = CardDefaults.cardColors(
                        containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
                        else MaterialTheme.colorScheme.surface
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(20.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = stringResource(titleRes),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.weight(1f)
                        )
                        if (isSelected) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
        }

        Button(
            onClick = onNext,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            shape = RoundedCornerShape(28.dp),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
        ) {
            Text(stringResource(R.string.btn_continue), style = MaterialTheme.typography.labelLarge)
            Spacer(modifier = Modifier.size(8.dp))
            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null)
        }
    }
}

@Composable
private fun CycleParametersStep(
    cycleLength: Float,
    periodLength: Float,
    onCycleLengthChange: (Float) -> Unit,
    onPeriodLengthChange: (Float) -> Unit,
    onNext: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Spacer(modifier = Modifier.height(32.dp))
            Text(
                text = "Your Cycle Parameters",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onBackground
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Helps our algorithm accurately predict your ovulation and next period.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(36.dp))

            // Cycle Length
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text(
                        text = stringResource(R.string.onboarding_cycle_length_title),
                        style = MaterialTheme.typography.titleMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "${cycleLength.toInt()} days",
                        style = MaterialTheme.typography.displayLarge.copy(fontSize = 32.sp),
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold
                    )
                    Slider(
                        value = cycleLength,
                        onValueChange = onCycleLengthChange,
                        valueRange = 21f..40f,
                        steps = 18,
                        colors = SliderDefaults.colors(
                            thumbColor = MaterialTheme.colorScheme.primary,
                            activeTrackColor = MaterialTheme.colorScheme.primary
                        )
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Period Length
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text(
                        text = stringResource(R.string.onboarding_period_length_title),
                        style = MaterialTheme.typography.titleMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "${periodLength.toInt()} days",
                        style = MaterialTheme.typography.displayLarge.copy(fontSize = 32.sp),
                        color = MaterialTheme.colorScheme.secondary,
                        fontWeight = FontWeight.Bold
                    )
                    Slider(
                        value = periodLength,
                        onValueChange = onPeriodLengthChange,
                        valueRange = 2f..10f,
                        steps = 7,
                        colors = SliderDefaults.colors(
                            thumbColor = MaterialTheme.colorScheme.secondary,
                            activeTrackColor = MaterialTheme.colorScheme.secondary
                        )
                    )
                }
            }
        }

        Button(
            onClick = onNext,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            shape = RoundedCornerShape(28.dp),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
        ) {
            Text(stringResource(R.string.btn_continue), style = MaterialTheme.typography.labelLarge)
        }
    }
}

@Composable
private fun FinalStep(
    selectedGoal: HealthGoal,
    cycleLength: Int,
    periodLength: Int,
    lastPeriodDate: LocalDate,
    onStart: (isAnonymous: Boolean) -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .size(100.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primaryContainer),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Favorite,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(54.dp)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = "You're All Set!",
            style = MaterialTheme.typography.displayLarge.copy(fontSize = 28.sp),
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(12.dp))

        Text(
            text = "CycleCare strictly protects your privacy. Your sensitive health data is never shared with third parties.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )

        Spacer(modifier = Modifier.height(40.dp))

        Button(
            onClick = { onStart(true) },
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            shape = RoundedCornerShape(28.dp),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
        ) {
            Icon(Icons.Default.Person, contentDescription = null)
            Spacer(modifier = Modifier.size(8.dp))
            Text(stringResource(R.string.btn_start_anonymous), style = MaterialTheme.typography.labelLarge)
        }

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedButton(
            onClick = { onStart(false) },
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            shape = RoundedCornerShape(28.dp)
        ) {
            Text(stringResource(R.string.btn_signup), style = MaterialTheme.typography.labelLarge)
        }
    }
}
