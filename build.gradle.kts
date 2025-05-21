import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar

val logback_version: String by project
val ktor_version: String by project
val kotlin_version: String by project

plugins {
    kotlin("jvm") version "1.4.32"
    id("com.github.johnrengelman.shadow") version "4.0.3"
    application
}

group = "io.aloha"
version = "0.0.2"

application {
    mainClassName = "io.aloha.AlohaMainKt"
}

repositories {
    mavenCentral()
}


dependencies {

    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:$kotlin_version")
    implementation("junit:junit:4.12")
    implementation("org.apache.logging.log4j:log4j-core:2.14.1")
    implementation("org.jruby:jruby-complete:9.4.3.0")
// https://mvnrepository.com/artifact/org.jsoup/jsoup
    implementation("org.jsoup:jsoup:1.20.1")
    // cantena
    implementation(files("libs/cantena.jar"))
    // cantena deps start
    implementation("org.apache.commons:commons-math3:3.6.1")
    implementation("org.apache.ignite:ignite-core:2.9.1")
    implementation("org.slf4j:slf4j-simple:1.7.21")
    implementation("org.tinylog:tinylog:1.3.2")
    implementation("com.google.guava:guava:24.0-jre")
    implementation("org.xerial.snappy:snappy-java:1.1.7.2")
    implementation("com.google.code.gson:gson:2.8.7")
    implementation("org.apache.commons:commons-lang3:3.6")
    implementation("commons-io:commons-io:2.5")

    testImplementation(kotlin("test"))
    // cantena deps end
}

sourceSets {
    // main
    getByName("main").java.srcDirs("src")
    getByName("main").kotlin.srcDirs("src")

    // test
    getByName("test").java.srcDirs("test")
    getByName("test").kotlin.srcDirs("test")
}

val SourceSet.kotlin: SourceDirectorySet
    get() = (this as org.gradle.api.internal.HasConvention).convention.getPlugin<org.jetbrains.kotlin.gradle.plugin.KotlinSourceSet>().kotlin


tasks {
    withType<KotlinCompile> {
        kotlinOptions.jvmTarget = "1.8"
    }
}

sourceSets["main"].resources.srcDirs("resources")
sourceSets["test"].resources.srcDirs("testresources")

tasks.withType<ShadowJar> {
    manifest.attributes.apply {

        ///////////////////////////////////////////////////////////
        // The following attributes apply to the archive/jar file
        // that is being created and not the manifest.
        ///////////////////////////////////////////////////////////

        baseName = "aloha"


        description = ""

        // The classifier part of the archive/jar name
        classifier = ""

        version = ""

        ///////////////////////////////////////////////////////////
        // The following attributes apply to the mainfest for the
        // archive/jar being created.
        ///////////////////////////////////////////////////////////
        manifest {
            attributes(
                mutableMapOf<String, String>(
                    "Base-Name" to baseName!!,
                    "Main-Class" to "io.aloha.AlohaMainKt",
                    "Start-Class" to "",
                    "Implementation-Title" to "",
                    "Implementation-Version" to version!!
                )
            )
        }
    }
}
val compileKotlin: KotlinCompile by tasks
compileKotlin.kotlinOptions {
    languageVersion = "1.4"
}
