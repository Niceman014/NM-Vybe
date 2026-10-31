allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Older Flutter Android plugins default Java to 11 while Kotlin targets 17.
    // Keep library bytecode targets aligned for the app's JDK 17 toolchain.
    val childProject = project
    childProject.plugins.withId("com.android.library") {
        val androidExtension = childProject.extensions.findByName("android")
            ?: throw GradleException("Android extension missing for ${childProject.name}")

        val compileOptions = androidExtension.javaClass.methods
            .firstOrNull { it.name == "getCompileOptions" && it.parameterCount == 0 }
            ?.invoke(androidExtension)
            ?: throw GradleException("Android compile options missing for ${childProject.name}")
        for (property in listOf("setSourceCompatibility", "setTargetCompatibility")) {
            val setter = compileOptions.javaClass.methods.firstOrNull { method ->
                method.name == property &&
                    method.parameterTypes.contentEquals(arrayOf(JavaVersion::class.java))
            } ?: throw GradleException(
                "Android compile option $property missing for ${childProject.name}"
            )
            setter.invoke(compileOptions, JavaVersion.VERSION_17)
        }

    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
