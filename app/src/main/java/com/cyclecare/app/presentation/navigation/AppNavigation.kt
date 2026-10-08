package com.cyclecare.app.presentation.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.EditCalendar
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.cyclecare.app.R
import com.cyclecare.app.core.security.SessionManager
import com.cyclecare.app.data.repository.CycleCareRepository
import com.cyclecare.app.presentation.calendar.CalendarScreen
import com.cyclecare.app.presentation.home.HomeScreen
import com.cyclecare.app.presentation.insights.InsightsScreen
import com.cyclecare.app.presentation.log.DailyLogScreen
import com.cyclecare.app.presentation.onboarding.OnboardingScreen
import com.cyclecare.app.presentation.settings.SettingsScreen
import kotlinx.coroutines.launch

sealed class Screen(val route: String) {
    data object Onboarding : Screen("onboarding")
    data object Main : Screen("main")
}

enum class BottomTab(val titleRes: Int, val icon: ImageVector) {
    HOME(R.string.nav_home, Icons.Default.Favorite),
    CALENDAR(R.string.nav_calendar, Icons.Default.CalendarMonth),
    LOG(R.string.nav_log, Icons.Default.EditCalendar),
    INSIGHTS(R.string.nav_insights, Icons.Default.Insights),
    SETTINGS(R.string.nav_settings, Icons.Default.Settings)
}

@Composable
fun AppNavigation(
    repository: CycleCareRepository,
    sessionManager: SessionManager
) {
    val isOnboardingCompleted by sessionManager.isOnboardingCompletedFlow.collectAsState(initial = false)
    val navController = rememberNavController()

    val startDestination = if (isOnboardingCompleted) Screen.Main.route else Screen.Onboarding.route

    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable(Screen.Onboarding.route) {
            OnboardingScreen(
                repository = repository,
                sessionManager = sessionManager,
                onOnboardingComplete = {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Onboarding.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Main.route) {
            MainContainerScreen(
                repository = repository,
                sessionManager = sessionManager
            )
        }
    }
}

@Composable
fun MainContainerScreen(
    repository: CycleCareRepository,
    sessionManager: SessionManager
) {
    var currentTab by remember { mutableStateOf(BottomTab.HOME) }

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surfaceVariant,
                contentColor = MaterialTheme.colorScheme.primary
            ) {
                BottomTab.entries.forEach { tab ->
                    NavigationBarItem(
                        selected = currentTab == tab,
                        onClick = { currentTab = tab },
                        icon = { Icon(tab.icon, contentDescription = stringResource(tab.titleRes)) },
                        label = { Text(stringResource(tab.titleRes)) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = MaterialTheme.colorScheme.primary,
                            selectedTextColor = MaterialTheme.colorScheme.primary,
                            indicatorColor = MaterialTheme.colorScheme.primaryContainer
                        )
                    )
                }
            }
        }
    ) { paddingValues ->
        val modifier = Modifier.padding(paddingValues)
        when (currentTab) {
            BottomTab.HOME -> HomeScreen(repository = repository, modifier = modifier, onNavigateToLog = { currentTab = BottomTab.LOG })
            BottomTab.CALENDAR -> CalendarScreen(repository = repository, modifier = modifier, onOpenLogForDate = { currentTab = BottomTab.LOG })
            BottomTab.LOG -> DailyLogScreen(repository = repository, modifier = modifier)
            BottomTab.INSIGHTS -> InsightsScreen(repository = repository, modifier = modifier)
            BottomTab.SETTINGS -> SettingsScreen(repository = repository, sessionManager = sessionManager, modifier = modifier)
        }
    }
}
