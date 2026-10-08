package com.cyclecare.app.core.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = RosePrimaryDark,
    onPrimary = RoseOnPrimaryDark,
    primaryContainer = RoseContainerDark,
    onPrimaryContainer = OnRoseContainerDark,
    secondary = LavenderSecondaryDark,
    onSecondary = LavenderOnSecondaryDark,
    secondaryContainer = LavenderContainerDark,
    onSecondaryContainer = OnLavenderContainerDark,
    background = BackgroundDark,
    surface = SurfaceDark,
    surfaceVariant = SurfaceVariantDark,
    onBackground = TextPrimaryDark,
    onSurface = TextPrimaryDark
)

private val LightColorScheme = lightColorScheme(
    primary = RosePrimaryLight,
    onPrimary = RoseOnPrimaryLight,
    primaryContainer = RoseContainerLight,
    onPrimaryContainer = OnRoseContainerLight,
    secondary = LavenderSecondaryLight,
    onSecondary = LavenderOnSecondaryLight,
    secondaryContainer = LavenderContainerLight,
    onSecondaryContainer = OnLavenderContainerLight,
    tertiary = PeachTertiaryLight,
    tertiaryContainer = PeachContainerLight,
    background = BackgroundLight,
    surface = SurfaceLight,
    surfaceVariant = SurfaceVariantLight,
    onBackground = TextPrimaryLight,
    onSurface = TextPrimaryLight,
    onSurfaceVariant = TextSecondaryLight
)

@Composable
fun CycleCareTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                window.statusBarColor = colorScheme.background.toArgb()
                window.navigationBarColor = colorScheme.background.toArgb()
                WindowCompat.getInsetsController(window, view).apply {
                    isAppearanceLightStatusBars = !darkTheme
                    isAppearanceLightNavigationBars = !darkTheme
                }
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
