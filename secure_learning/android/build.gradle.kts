val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.findByName("android")
            if (androidExtension != null) {
                val clazz = androidExtension.javaClass
                try {
                    val method = clazz.getMethod("compileSdk", Int::class.java)
                    method.invoke(androidExtension, 36)
                } catch (_: Exception) {
                    try {
                        val field = clazz.getDeclaredField("compileSdkVersion")
                        field.isAccessible = true
                        field.set(androidExtension, 36)
                    } catch (_: Exception) {}
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
