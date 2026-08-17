allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Legacy plugins built pre-AGP7 declare `package` in AndroidManifest.xml but
// not `namespace` in build.gradle, which AGP 8 requires. Backfill it.
subprojects {
    val fixNamespace = fun() {
        val androidExt = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (androidExt != null && androidExt.namespace == null) {
            val manifestFile = androidExt.sourceSets.getByName("main").manifest.srcFile
            if (manifestFile.exists()) {
                val pkg = Regex("package=\"([^\"]+)\"").find(manifestFile.readText())?.groupValues?.get(1)
                if (pkg != null) {
                    androidExt.namespace = pkg
                }
            }
        }
    }
    if (state.executed) fixNamespace() else afterEvaluate { fixNamespace() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
