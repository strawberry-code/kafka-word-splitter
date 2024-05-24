plugins {
    id("java")
    id("application")
    id("com.github.johnrengelman.shadow") version "7.1.2"
    id("checkstyle")
    id("jacoco")
    id("com.github.spotbugs") version "6.0.7"
    id("org.owasp.dependencycheck") version "9.0.9"
}

group = "org.example"
version = "1.0-SNAPSHOT"
java.sourceCompatibility = JavaVersion.VERSION_17

repositories {
    mavenCentral()
}
dependencies {
    testImplementation(platform("org.junit:junit-bom:5.10.0"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    implementation("org.apache.kafka:kafka-clients:3.8.0")
    implementation("com.google.guava:guava:32.1.0-jre")
    implementation("ch.qos.logback:logback-classic:1.4.14")
    implementation("org.slf4j:slf4j-api:2.0.9")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine")
}

tasks.test {
    useJUnitPlatform()
}

// Configure application plugin with a dummy main class
// Actual main class will be specified on command line using -cp
application {
    mainClass.set("org.example.ConsumerApp")  // Required by plugin, not used at runtime
}

tasks {
    val shadowJar by getting(com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar::class) {
        archiveClassifier.set("all")
        // Disable automatic Main-Class injection from application plugin
        doFirst {
            manifest.attributes.remove("Main-Class")
        }
    }
}

// Checkstyle Configuration
checkstyle {
    toolVersion = "10.12.5"
    configFile = file("config/checkstyle/checkstyle.xml")
    isIgnoreFailures = true  // Set to false when ready to enforce
    maxWarnings = 1000  // High threshold for initial setup
}

// JaCoCo Configuration
jacoco {
    toolVersion = "0.8.11"
}

tasks.test {
    finalizedBy(tasks.jacocoTestReport)
}

tasks.jacocoTestReport {
    dependsOn(tasks.test)
    reports {
        xml.required.set(true)
        html.required.set(true)
        csv.required.set(false)
    }
}

tasks.jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                minimum = "0.0".toBigDecimal()  // Start with 0%, increase as tests are added
            }
        }
    }
}

// SpotBugs Configuration
tasks.withType<com.github.spotbugs.snom.SpotBugsTask>().configureEach {
    ignoreFailures = true  // Set to false when ready to enforce
    reports.create("html") {
        required.set(true)
        outputLocation.set(file("${layout.buildDirectory.get()}/reports/spotbugs/spotbugs.html"))
    }
    reports.create("xml") {
        required.set(false)
    }
}

// OWASP Dependency Check Configuration
dependencyCheck {
    autoUpdate = true
    format = org.owasp.dependencycheck.reporting.ReportGenerator.Format.ALL.toString()
    failBuildOnCVSS = 7.0f  // Fail on HIGH or CRITICAL vulnerabilities
    suppressionFile = "dependency-check-suppressions.xml"
}