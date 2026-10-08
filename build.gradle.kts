plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.ksp) apply false
}

allprojects {
    val buildBase = file("${project.rootDir}/.build")
    layout.buildDirectory.set(if (this == rootProject) file("$buildBase/root") else file("$buildBase/${project.name}"))
}
