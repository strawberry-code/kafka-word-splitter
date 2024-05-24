# Build Process Documentation

## Overview
This document describes how to build the kafka-word-splitter project using Gradle.

## Prerequisites

### Required Software

- **Java Development Kit (JDK) 17 or higher**
  - Check version: `java -version`
  - Download from: https://adoptium.net/ or https://www.oracle.com/java/technologies/downloads/

- **Podman (Recommended) OR Docker**
  - Required for running Kafka infrastructure
  - Podman: https://podman.io/getting-started/installation
  - Docker: https://www.docker.com/products/docker-desktop/

### Optional Software
- Git (for cloning the repository)
- IDE with Java support (IntelliJ IDEA, Eclipse, VS Code)

## Build System

The project uses **Gradle 8.10.2** as its build system with the Gradle Wrapper, which means you don't need to install Gradle separately. The wrapper will automatically download the correct Gradle version.

### Gradle Wrapper Files
- `gradlew` - Unix/Linux/macOS wrapper script
- `gradlew.bat` - Windows wrapper script
- `gradle/wrapper/gradle-wrapper.jar` - Wrapper JAR (committed to repository)
- `gradle/wrapper/gradle-wrapper.properties` - Wrapper configuration

## Building the Project

### Clean Build
To perform a clean build (removes previous build artifacts and rebuilds everything):

```bash
./gradlew clean build
```

On Windows:
```cmd
gradlew.bat clean build
```

### Quick Build
To build without cleaning:

```bash
./gradlew build
```

### Build Output
Successful build output includes:
- Compiled classes in `build/classes/`
- JAR files in `build/libs/`
- Distribution archives in `build/distributions/`
- Shadow JAR (fat JAR with dependencies) in `build/libs/`

## Common Build Tasks

### Compile Only
```bash
./gradlew compileJava
```

### Run Tests
```bash
./gradlew test
```

### Create Distribution
```bash
./gradlew distZip
# or
./gradlew distTar
```

### Create Shadow JAR (Fat JAR)
```bash
./gradlew shadowJar
```

The shadow JAR includes all dependencies and can be run standalone:
```bash
java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar
```

### Run Application
```bash
./gradlew run
```

## Project Dependencies

### Runtime Dependencies
- **Apache Kafka Clients** (3.8.0) - Kafka consumer/producer functionality
- **Google Guava** (32.1.0-jre) - Utility libraries
- **Logback Classic** (1.4.14) - Logging framework
- **SLF4J API** (2.0.9) - Logging facade

### Test Dependencies
- **JUnit Jupiter** (5.10.0) - Unit testing framework

## Build Configuration

The build is configured in `build.gradle.kts` using Kotlin DSL.

### Key Plugins
- `java` - Java compilation and packaging
- `application` - Application packaging and execution
- `com.github.johnrengelman.shadow` (7.1.2) - Fat JAR creation

### Java Version
- Source Compatibility: Java 17
- Target Compatibility: Java 17

### Main Class
- `org.example.ConsumerApp`

## Troubleshooting

### Common Issues

#### Issue: Permission denied on gradlew
**Solution:** Make the wrapper executable:
```bash
chmod +x gradlew
```

#### Issue: Java version mismatch
**Error:** `Unsupported class file major version XX`
**Solution:** Ensure you're using JDK 17 or higher:
```bash
java -version
```

#### Issue: Gradle daemon issues
**Solution:** Stop all Gradle daemons and retry:
```bash
./gradlew --stop
./gradlew clean build
```

#### Issue: Dependency resolution failures
**Solution:** Clear Gradle cache and rebuild:
```bash
rm -rf ~/.gradle/caches/
./gradlew clean build --refresh-dependencies
```

#### Issue: Out of memory during build
**Solution:** Increase Gradle memory in `gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
```

### Build Warnings

#### Deprecated API Usage
The build may show warnings about deprecated APIs in Kafka client usage. These are informational and don't prevent the build from succeeding. To see detailed deprecation warnings:
```bash
./gradlew build -Xlint:deprecation
```

#### Gradle 9.0 Compatibility
The current build uses some features that will be deprecated in Gradle 9.0. To see specific warnings:
```bash
./gradlew build --warning-mode all
```

## Build Performance

### First Build
- Downloads Gradle distribution (~100MB)
- Downloads all dependencies
- Compiles all source files
- Typical time: 30-60 seconds

### Incremental Builds
- Uses cached Gradle daemon
- Only recompiles changed files
- Typical time: 5-15 seconds

### Optimization Tips
1. **Keep Gradle daemon running** - Don't use `--no-daemon`
2. **Use build cache** - Add to `gradle.properties`:
   ```properties
   org.gradle.caching=true
   ```
3. **Parallel execution** - For multi-module projects:
   ```properties
   org.gradle.parallel=true
   ```

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Setup JDK 17
  uses: actions/setup-java@v3
  with:
    java-version: '17'
    distribution: 'temurin'

- name: Build with Gradle
  run: ./gradlew clean build
```

### Container Build Example (Podman or Docker)

Using Podman (recommended):
```dockerfile
FROM gradle:8.10.2-jdk17 AS build
COPY . /app
WORKDIR /app
RUN ./gradlew clean build

FROM eclipse-temurin:17-jre
COPY --from=build /app/build/libs/*-all.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

Build with Podman:
```bash
podman build -t kafka-word-splitter:latest .
```

Or with Docker:
```bash
docker build -t kafka-word-splitter:latest .
```

### Podman-Specific Build Considerations

When building in a Podman environment:

1. **Rootless Containers**: Podman runs rootless by default, which is more secure
2. **No Daemon**: Podman doesn't require a background daemon process
3. **Build Context**: Same as Docker - ensure build context is clean
4. **Multi-arch Builds**: Use `podman build --platform linux/amd64,linux/arm64` for multi-architecture

### Container Runtime in Development

The application's Kafka infrastructure uses `compose.yml` which works with both:
- **Podman Compose**: `podman compose` (built-in) or `podman-compose` (separate tool)
- **Docker Compose**: `docker compose` (v2) or `docker-compose` (v1)

Scripts automatically detect the available runtime - no manual configuration needed.

## Getting Help

- Gradle Documentation: https://docs.gradle.org/8.10.2/userguide/userguide.html
- Gradle Wrapper Guide: https://docs.gradle.org/current/userguide/gradle_wrapper.html
- Project Issues: Check repository issue tracker

## Build System Maintenance

### Updating Gradle Version
To update the Gradle wrapper to a newer version:
```bash
gradle wrapper --gradle-version 8.x.x
```

### Adding Dependencies
Edit `build.gradle.kts` and add to the `dependencies` block:
```kotlin
dependencies {
    implementation("group:artifact:version")
}
```

### Viewing Dependencies
To see the complete dependency tree:
```bash
./gradlew dependencies
```

## Success Criteria

A successful build should show:
- `BUILD SUCCESSFUL` message
- Exit code: 0
- Generated artifacts in `build/` directory
- No compilation errors

Example successful output:
```
BUILD SUCCESSFUL in 15s
11 actionable tasks: 8 executed, 3 up-to-date
```
