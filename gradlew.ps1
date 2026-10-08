# PowerShell wrapper for Gradle
$javaArgs = @(
    "-Dfile.encoding=UTF-8",
    "-Xmx1024m",
    "-classpath", "gradle/wrapper/gradle-wrapper.jar",
    "org.gradle.wrapper.GradleWrapperMain"
) + $args

& java @javaArgs
exit $LASTEXITCODE
