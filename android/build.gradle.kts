import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete



// 1. BUILD SCRIPT CONFIGURATION
// This block defines the repositories and dependencies needed to run the Gradle build script itself,
// specifically for resolving plugins like the Android Gradle Plugin and google-services.
buildscript {
    repositories {
        // Essential for finding the 'google-services' plugin and Android Gradle Plugin
        google()
        mavenCentral()
    }
    dependencies {
        // The Android Gradle Plugin version
        classpath("com.android.tools.build:gradle:8.1.1")
        // The Google Services plugin for Firebase/Google Play Services
        classpath("com.google.gms:google-services:4.3.15")
    }
}

// 2. ALL PROJECTS CONFIGURATION
// This block defines the repositories for ALL modules in your project (e.g., the 'app' module).
// It's necessary for resolving libraries and dependencies used by your application code.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- PROJECT-LEVEL DIRECTORY & TASK CONFIGURATION ---

// Define a new build directory location (moving it outside the 'android' folder)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Configure subprojects to use subdirectories within the new global build directory
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Ensure other projects (like Flutter plugins) wait for the ':app' module to be evaluated
subprojects {
    project.evaluationDependsOn(":app")
}

// Define a 'clean' task to delete the custom build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}