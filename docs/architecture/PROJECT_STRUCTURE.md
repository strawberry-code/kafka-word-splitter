# Project Structure

This document provides a comprehensive overview of the Kafka Word Splitter project organization, explaining the purpose and contents of each directory and major file.

## Directory Tree

```
kafka-word-splitter/
├── .claude/                          # AI assistant configuration
│   ├── agents/                       # Agent definitions
│   ├── QUICK-START.md                # Claude Code quick start
│   ├── README.md                     # Claude Code documentation
│   └── system-instructions-refactoring.md
│
├── .github/                          # GitHub-specific configurations
│   └── workflows/
│       └── ci.yml                    # GitHub Actions CI/CD pipeline
│
├── .idea/                            # IntelliJ IDEA project files
│   └── ...                           # IDE configuration
│
├── build/                            # Build output (not in version control)
│   ├── classes/                      # Compiled Java classes
│   ├── libs/                         # Generated JAR files
│   │   ├── kafka-word-splitter-1.0-SNAPSHOT.jar
│   │   └── kafka-word-splitter-1.0-SNAPSHOT-all.jar  # Fat JAR
│   ├── reports/                      # Quality and test reports
│   │   ├── checkstyle/               # Code style reports
│   │   ├── spotbugs/                 # Bug detection reports
│   │   ├── jacoco/                   # Code coverage reports
│   │   ├── tests/                    # Test results
│   │   └── dependency-check-report.html  # Security scan
│   └── tmp/                          # Temporary build files
│
├── config/                           # Configuration files
│   └── checkstyle/
│       └── checkstyle.xml            # Checkstyle rules
│
├── docs/                             # Documentation (organized by category)
│   ├── architecture/
│   │   ├── ARCHITECTURE_REPORT.md    # System architecture
│   │   ├── PROJECT_STRUCTURE.md      # This file
│   │   └── SHUTDOWN.md               # Shutdown procedures
│   ├── contributing/
│   │   ├── CONTRIBUTING.md           # Contribution guidelines
│   │   └── SUPPORT.md                # Getting help
│   ├── getting-started/
│   │   ├── BUILD.md                  # Build process guide
│   │   └── QUICK_START.md            # 5-minute setup guide
│   ├── operations/
│   │   ├── BRANCH_PROTECTION.md      # Git workflow
│   │   ├── CI_CD.md                  # CI/CD pipeline guide
│   │   ├── DEVOPS_REPORT.md          # DevOps infrastructure
│   │   └── QUALITY_VERIFICATION_REPORT.md # Phase 1 quality report
│   └── security/
│       ├── DEPENDENCY_UPDATE_POLICY.md # Dependency management
│       └── SECURITY.md               # Security report
│
├── gradle/                           # Gradle wrapper
│   └── wrapper/
│       ├── gradle-wrapper.jar        # Wrapper executable
│       └── gradle-wrapper.properties # Wrapper configuration
│
├── scripts/                          # Helper scripts
│   ├── ci-build.sh                   # Local CI simulation
│   ├── security-check.sh             # Run security scans
│   ├── quality-check.sh              # Run quality checks
│   ├── stop-kafka.sh                 # Stop Kafka infrastructure
│   ├── kafka-status.sh               # Check Kafka infrastructure status
│   ├── create-topics.sh              # Create required Kafka topics
│   └── validate-podman.sh            # Validate Podman migration
│
├── src/                              # Source code
│   ├── main/
│   │   ├── java/
│   │   │   └── org/
│   │   │       └── example/
│   │   │           ├── ProducerApp.java         # Producer entry point
│   │   │           ├── ConsumerApp.java         # Consumer entry point
│   │   │           ├── KafkaProducerService.java # Producer service
│   │   │           ├── KafkaConsumerService.java # Consumer service
│   │   │           ├── FileWatcher.java         # File monitoring
│   │   │           └── KafkaConfig.java         # Configuration constants
│   │   └── resources/
│   │       └── logback.xml                      # Logging configuration
│   └── test/
│       └── java/                     # Test source code (Phase 2+)
│
├── .gitignore                        # Git ignore patterns
├── build.gradle.kts                  # Gradle build configuration
├── CHANGELOG.md                      # Version history
├── compose.yml                       # Kafka infrastructure (Podman/Docker)
├── dependency-check-suppressions.xml # Security scan suppressions
├── docker-compose.yml                # Legacy Kafka config (kept for compatibility)
├── DOCUMENTATION_INDEX.md            # Documentation navigation
├── gradlew                           # Gradle wrapper script (Unix/Mac)
├── gradlew.bat                       # Gradle wrapper script (Windows)
├── LICENSE                           # MIT License
├── MIGRATION-NOTES.md                # Docker to Podman migration notes
├── README.md                         # Project overview (start here!)
├── settings.gradle.kts               # Gradle settings
└── start-kafka.sh                    # Kafka startup helper (enhanced with runtime detection)
```

## Directory Purposes

### `.claude/`
Claude Code AI assistant configuration and agent definitions.

**Key Files:**
- `agents/` - Specialized agent configurations (CTO, DevOps, Security, etc.)
- `QUICK-START.md` - Quick start guide for Claude Code
- `system-instructions-refactoring.md` - Refactoring guidelines

**Purpose:** Provides AI assistant configuration for development workflow automation.

---

### `.github/`
GitHub-specific configuration.

**Key Files:**
- `workflows/ci.yml` - Automated CI/CD pipeline configuration

**Purpose:** Automates testing, security scanning, and quality checks on every push/PR.

---

### `.idea/`
IntelliJ IDEA project configuration.

**Purpose:** IDE-specific settings for development environment. Kept in version control for team consistency.

---

### `docs/`
**Organized documentation by category**

#### `docs/architecture/`
Technical architecture and design documentation.

**Files:**
- `ARCHITECTURE_REPORT.md` - Complete system architecture analysis
- `PROJECT_STRUCTURE.md` - This file - project organization guide
- `SHUTDOWN.md` - Graceful shutdown mechanisms

#### `docs/contributing/`
Contribution and community documentation.

**Files:**
- `CONTRIBUTING.md` - How to contribute to the project
- `SUPPORT.md` - Getting help and support channels

#### `docs/getting-started/`
Essential getting started guides.

**Files:**
- `BUILD.md` - Build process and troubleshooting
- `QUICK_START.md` - 5-minute setup guide

#### `docs/operations/`
DevOps, deployment, and operational documentation.

**Files:**
- `BRANCH_PROTECTION.md` - Git workflow guidelines
- `CI_CD.md` - CI/CD pipeline user guide
- `DEVOPS_REPORT.md` - DevOps infrastructure report
- `QUALITY_VERIFICATION_REPORT.md` - Phase 1 quality verification

#### `docs/security/`
Security policies and reports.

**Files:**
- `DEPENDENCY_UPDATE_POLICY.md` - Dependency management policy
- `SECURITY.md` - Security vulnerabilities and patches

**Purpose:** Centralized, organized documentation structure for easy navigation.

---

### `build/`
Generated build artifacts and reports (excluded from Git).

**Subdirectories:**
- `classes/` - Compiled `.class` files
- `libs/` - JAR files (both regular and fat JAR)
- `reports/` - Quality, security, and test reports
- `distributions/` - Distribution archives (zip/tar)

**Purpose:** Contains all build outputs. Cleaned with `./gradlew clean`.

---

### `config/`
Configuration files for build tools.

**Files:**
- `checkstyle/checkstyle.xml` - Java code style rules

**Purpose:** Centralized configuration for code quality tools.

---

### `gradle/`
Gradle Wrapper files ensuring consistent builds.

**Files:**
- `wrapper/gradle-wrapper.jar` - The Gradle wrapper executable
- `wrapper/gradle-wrapper.properties` - Wrapper version configuration

**Purpose:** Allows building without installing Gradle locally.

---

### `scripts/`
Helper scripts for local development and infrastructure management.

**Infrastructure Scripts:**
- `stop-kafka.sh` - Gracefully stop Kafka infrastructure
- `kafka-status.sh` - Check Kafka infrastructure health and connectivity
- `create-topics.sh` - Create required Kafka topics (3-10)
- `validate-podman.sh` - Validate Podman migration and installation

**Development Scripts:**
- `ci-build.sh` - Simulates CI pipeline locally
- `security-check.sh` - Runs security scans
- `quality-check.sh` - Runs code quality checks

**Purpose:** Automates infrastructure management and enables developers to run CI checks before pushing.

**Usage:**
```bash
# Infrastructure management
./scripts/stop-kafka.sh      # Stop Kafka
./scripts/kafka-status.sh    # Check status
./scripts/create-topics.sh   # Create topics
./scripts/validate-podman.sh # Validate setup

# Development checks
./scripts/ci-build.sh        # Full CI simulation
./scripts/security-check.sh  # Security scan only
./scripts/quality-check.sh   # Quality checks only
```

---

### `src/main/java/`
Application source code.

**Package:** `org.example`

#### Core Components

**Entry Points:**
- `ProducerApp.java` - Main class for producer application
- `ConsumerApp.java` - Main class for consumer application

**Services:**
- `KafkaProducerService.java` - Kafka message production
- `KafkaConsumerService.java` - Kafka message consumption
- `FileWatcher.java` - File system monitoring

**Configuration:**
- `KafkaConfig.java` - Centralized constants and configuration

**Purpose:** Contains all application logic.

---

### `src/main/resources/`
Application resources and configuration.

**Files:**
- `logback.xml` - Logging configuration (SLF4J/Logback)

**Purpose:** Runtime resources bundled in JAR.

---

### `src/test/java/`
Test source code (Phase 2 - upcoming).

**Purpose:** Unit and integration tests.

---

## Key Files Explained

### Build Configuration

#### `build.gradle.kts`
Main Gradle build configuration using Kotlin DSL.

**Defines:**
- Java version (17)
- Dependencies (Kafka, Logback, etc.)
- Build plugins (Shadow, Checkstyle, SpotBugs, etc.)
- Quality tool configurations
- Main class for application plugin

**Key Sections:**
```kotlin
plugins {
    id("java")
    id("application")
    id("com.github.johnrengelman.shadow") version "7.1.2"
    id("checkstyle")
    id("jacoco")
    id("com.github.spotbugs") version "6.0.7"
    id("org.owasp.dependencycheck") version "9.0.9"
}

dependencies {
    implementation("org.apache.kafka:kafka-clients:3.8.0")
    implementation("ch.qos.logback:logback-classic:1.4.14")
    implementation("org.slf4j:slf4j-api:2.0.9")
    // ...
}
```

---

#### `settings.gradle.kts`
Gradle settings file.

**Defines:**
- Project name: `kafka-word-splitter`

---

#### `gradlew` / `gradlew.bat`
Gradle wrapper scripts for Unix/Mac and Windows.

**Purpose:** Builds project without requiring Gradle installation.

**Usage:**
```bash
./gradlew build        # Unix/Mac
gradlew.bat build      # Windows
```

---

### Infrastructure

#### `compose.yml`
Container orchestration configuration for Kafka infrastructure (Podman/Docker compatible).

**Services:**
- Zookeeper (port 2181)
- Kafka (port 9092)

**Key Features:**
- Compose v3.8 specification
- Works with both Podman Compose and Docker Compose
- Explicit container names for consistent management
- Bridge network configuration
- No Docker socket mounting (security improvement)

**Usage:**
```bash
# Use wrapper scripts (recommended)
./start-kafka.sh         # Start (auto-detects runtime)
./scripts/stop-kafka.sh  # Stop

# Or use compose directly
podman compose up -d     # Start with Podman
docker compose up -d     # Start with Docker
podman compose down      # Stop with Podman
docker compose down      # Stop with Docker
```

#### `docker-compose.yml`
Legacy Docker Compose configuration (kept for backward compatibility).

**Note:** Scripts prioritize `compose.yml` but fall back to `docker-compose.yml` if needed.

#### `MIGRATION-NOTES.md`
Technical documentation for the Docker to Podman migration.

**Contains:**
- Migration changes and rationale
- Podman-specific configurations
- Platform notes (macOS vs Linux)
- Troubleshooting guide
- Performance characteristics
- Security improvements

**Purpose:** Reference for developers and operators managing the infrastructure.

---

#### `dependency-check-suppressions.xml`
OWASP Dependency Check suppressions for known false positives.

**Purpose:** Prevents CI failures from false positive CVE detections.

---

### Documentation

#### `README.md`
Main project documentation and entry point.

**Contains:**
- Project overview
- Quick start guide
- Feature list
- Documentation index
- Technology stack

---

#### `QUICK_START.md`
Fast 5-minute setup guide for new users.

**Contains:**
- Step-by-step setup
- Running examples
- Troubleshooting common issues

---

#### `BUILD.md`
Comprehensive build process documentation.

**Contains:**
- Prerequisites
- Build commands
- Troubleshooting
- CI/CD integration examples

---

#### `ARCHITECTURE_REPORT.md`
Detailed architecture documentation.

**Contains:**
- System design
- Shutdown mechanisms
- Resource management
- Design patterns
- Thread safety analysis

---

#### `SHUTDOWN.md`
Graceful shutdown documentation.

**Contains:**
- Shutdown sequences
- Resource cleanup
- JVM shutdown hooks
- Testing procedures

---

#### `SECURITY.md`
Security vulnerability report and patches.

**Contains:**
- CVE analysis
- Dependency upgrades
- Security improvements
- Vulnerability remediation

---

#### `DEPENDENCY_UPDATE_POLICY.md`
Guidelines for managing dependencies.

**Contains:**
- Update frequency
- Security policies
- Testing requirements
- Rollback procedures

---

#### `CONTRIBUTING.md`
Contribution guidelines for developers.

**Contains:**
- Code style
- Commit message format
- Pull request process
- Testing requirements

---

#### `CHANGELOG.md`
Version history and changes.

**Contains:**
- All Phase 1 changes by wave
- Breaking changes
- Migration notes

---

#### `SUPPORT.md`
Getting help documentation.

**Contains:**
- How to ask for help
- Resources
- Contact information

---

#### `LICENSE`
MIT License for the project.

---

## Source Code Organization

### Package: `org.example`

All source code is in the `org.example` package.

#### Class Hierarchy

```
org.example
├── ProducerApp              # Main entry point
│   └── uses
│       ├── KafkaProducerService
│       └── FileWatcher
│
├── ConsumerApp              # Main entry point
│   └── uses
│       └── KafkaConsumerService
│
├── KafkaProducerService     # Producer logic
│   └── uses
│       └── KafkaConfig
│
├── KafkaConsumerService     # Consumer logic
│   └── uses
│       └── KafkaConfig
│
├── FileWatcher              # File monitoring
│   └── uses
│       └── KafkaProducerService
│
└── KafkaConfig              # Constants
```

#### Responsibilities

**ProducerApp**
- Entry point for producer
- Initializes services
- Registers shutdown hooks
- Coordinates shutdown sequence

**ConsumerApp**
- Entry point for consumer
- Initializes consumer service
- Registers shutdown hooks
- Handles graceful termination

**KafkaProducerService**
- Manages Kafka producer lifecycle
- Sends messages to topics
- Manages executor service
- Implements graceful shutdown

**KafkaConsumerService**
- Manages Kafka consumer lifecycle
- Polls and processes messages
- Writes to output files
- Implements graceful shutdown

**FileWatcher**
- Monitors directory for new files
- Triggers file processing
- Uses Java NIO WatchService
- Implements graceful shutdown

**KafkaConfig**
- Centralized configuration constants
- Bootstrap servers
- Timeouts
- Topic routing rules

---

## Build Artifacts

### JAR Files

After building, two JAR files are generated:

#### 1. Regular JAR
**File:** `build/libs/kafka-word-splitter-1.0-SNAPSHOT.jar`

**Contents:** Only compiled classes (no dependencies)

**Usage:** Requires dependencies on classpath

#### 2. Fat JAR (Shadow JAR)
**File:** `build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar`

**Contents:** All compiled classes + all dependencies

**Usage:** Standalone, no classpath needed
```bash
java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar \
  org.example.ProducerApp /path/to/watch
```

**Recommended** for deployment and distribution.

---

## Reports and Artifacts

### Build Reports

Located in `build/reports/`:

#### Checkstyle
**Path:** `build/reports/checkstyle/main.html`

**Shows:** Code style violations

**View:** Open in browser

#### SpotBugs
**Path:** `build/reports/spotbugs/spotbugs.html`

**Shows:** Potential bugs and code issues

**View:** Open in browser

#### JaCoCo Coverage
**Path:** `build/reports/jacoco/test/html/index.html`

**Shows:** Code coverage metrics

**View:** Open in browser

#### OWASP Dependency Check
**Path:** `build/reports/dependency-check-report.html`

**Shows:** Security vulnerabilities in dependencies

**View:** Open in browser

---

## Configuration Files

### Logging Configuration

**File:** `src/main/resources/logback.xml`

Configures logging behavior:
- Log levels
- Output format
- Console/file output
- Logger hierarchy

### Checkstyle Rules

**File:** `config/checkstyle/checkstyle.xml`

Defines code style rules:
- Indentation (4 spaces)
- Line length (120 chars)
- Naming conventions
- Import organization

### Dependency Suppressions

**File:** `dependency-check-suppressions.xml`

Suppresses false positive CVE warnings:
- Known false positives
- Accepted risks
- Version-specific suppressions

---

## Git Configuration

### `.gitignore`

Excludes from version control:
- `build/` - Build outputs
- `.gradle/` - Gradle cache
- `.idea/` - IDE files
- `*.log` - Log files
- Generated artifacts

**Included in Git:**
- Source code
- Build configuration
- Documentation
- `gradle-wrapper.jar` - Ensures reproducible builds

---

## Working with the Project

### Common Tasks

**Build:**
```bash
./gradlew clean build
```

**Run Tests:**
```bash
./gradlew test
```

**Generate Reports:**
```bash
./gradlew check                    # All checks
./gradlew jacocoTestReport         # Coverage
./gradlew dependencyCheckAnalyze   # Security
```

**Create Fat JAR:**
```bash
./gradlew shadowJar
```

**Clean Build:**
```bash
./gradlew clean
```

**View Dependencies:**
```bash
./gradlew dependencies
```

---

## IDE Integration

### IntelliJ IDEA

**Project Files:**
- `.idea/` - IntelliJ configuration (excluded from Git)

**Import:**
1. Open → Select project directory
2. IntelliJ detects Gradle automatically
3. Set SDK to Java 17

### Eclipse

**Import:**
1. File → Import → Gradle Project
2. Select project directory

### VS Code

**Extensions:**
- Java Extension Pack
- Gradle for Java

**Import:**
1. Open folder
2. Extensions auto-configure

---

## Future Structure (Planned)

### Phase 2: Testing
```
src/
├── test/
│   └── java/
│       └── org/
│           └── example/
│               ├── KafkaProducerServiceTest.java
│               ├── KafkaConsumerServiceTest.java
│               └── integration/
│                   └── EndToEndTest.java
```

### Phase 3: Configuration Externalization
```
src/
├── main/
│   └── resources/
│       ├── application.properties
│       ├── kafka.properties
│       └── logback.xml
```

### Documentation Organization
```
docs/
├── getting-started/
│   ├── QUICK_START.md
│   └── BUILD.md
├── architecture/
│   ├── ARCHITECTURE_REPORT.md
│   └── SHUTDOWN.md
└── operations/
    ├── DEVOPS_REPORT.md
    └── SECURITY.md
```

---

## Summary

This project follows standard Gradle project structure with:
- Clear separation of source and build outputs
- Comprehensive documentation at root level
- Quality tooling integrated into build
- Docker-based infrastructure
- CI/CD automation via GitHub Actions

For more details on specific aspects, see:
- [README.md](README.md) - Project overview
- [BUILD.md](BUILD.md) - Build process
- [ARCHITECTURE_REPORT.md](ARCHITECTURE_REPORT.md) - Architecture details
- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guidelines

---

**Questions?** See [SUPPORT.md](SUPPORT.md) for getting help.
