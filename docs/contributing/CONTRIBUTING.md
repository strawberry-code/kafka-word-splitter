# Contributing to Kafka Word Splitter

Thank you for your interest in contributing to Kafka Word Splitter! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment Setup](#development-environment-setup)
- [Development Workflow](#development-workflow)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Requirements](#testing-requirements)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Code Review Guidelines](#code-review-guidelines)
- [Documentation Requirements](#documentation-requirements)
- [Security Considerations](#security-considerations)
- [Getting Help](#getting-help)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

### Enforcement

Instances of unacceptable behavior may be reported to the project maintainers. All complaints will be reviewed and investigated promptly and fairly.

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Java Development Kit (JDK) 17** or higher
- **Git** for version control
- **Podman** and **Podman Compose** (recommended) OR **Docker** and **Docker Compose** for Kafka infrastructure
- **IDE** with Java support (IntelliJ IDEA recommended)

Container Runtime Installation:
- **Podman (Recommended)**: See [Podman Installation Guide](https://podman.io/getting-started/installation)
  - macOS: `brew install podman` then `podman machine init && podman machine start`
  - Linux: `sudo apt-get install podman`
- **Docker (Alternative)**: [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Finding Something to Work On

1. **Check Open Issues**: Look for issues labeled `good first issue` or `help wanted`
2. **Review Roadmap**: Check [CHANGELOG.md](CHANGELOG.md) for planned features
3. **Propose New Features**: Open an issue to discuss before starting work

## Development Environment Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/kafka-word-splitter.git
cd kafka-word-splitter

# Add upstream remote
git remote add upstream https://github.com/strawberry-code/kafka-word-splitter.git
```

### 2. Build the Project

```bash
# Make gradlew executable (Unix/Mac)
chmod +x gradlew

# Build the project
./gradlew clean build

# Verify build success
# Output should show: BUILD SUCCESSFUL
```

### 3. Set Up Kafka Infrastructure

```bash
# Start Kafka and Zookeeper (auto-detects Podman or Docker)
./start-kafka.sh

# Create required topics
./scripts/create-topics.sh

# Verify Kafka is running
./scripts/kafka-status.sh
```

### 4. Run Tests

```bash
# Run all tests
./gradlew test

# Note: Currently no tests exist (planned for Phase 2)
# Build will succeed with "No tests found"
```

### 5. IDE Setup

#### IntelliJ IDEA

1. Open IntelliJ IDEA
2. Select "Open" and choose the project directory
3. IntelliJ will automatically detect Gradle and import the project
4. Wait for indexing to complete
5. Set Project SDK to Java 17:
   - File → Project Structure → Project → SDK → Java 17

#### Eclipse

1. Install Buildship Gradle plugin if not present
2. File → Import → Gradle → Existing Gradle Project
3. Select project directory and import

#### VS Code

1. Install Java Extension Pack
2. Open project folder
3. VS Code will detect Gradle and configure automatically

## Development Workflow

### 1. Create a Feature Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/my-feature-name

# Or for bug fixes
git checkout -b fix/issue-description
```

### 2. Make Your Changes

- Write clean, readable code
- Follow existing code style
- Add JavaDoc for public APIs
- Update documentation if needed
- Test your changes locally

### 3. Run Quality Checks

```bash
# Run all quality checks
./gradlew check

# Individual checks
./gradlew checkstyleMain      # Code style
./gradlew spotbugsMain         # Bug detection
./gradlew test                 # Tests
./gradlew jacocoTestReport     # Coverage

# Security scan
./gradlew dependencyCheckAnalyze
```

### 4. Commit Your Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: add word filtering by length"

# See commit message guidelines below
```

### 5. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/my-feature-name

# Go to GitHub and create a Pull Request
```

## Code Style Guidelines

### Java Code Style

We follow standard Java conventions with some specific guidelines:

#### Formatting

- **Indentation**: 4 spaces (no tabs)
- **Line Length**: Maximum 120 characters
- **Braces**: Always use braces for if/while/for blocks
- **Imports**: No wildcard imports, organize logically

#### Naming Conventions

- **Classes**: PascalCase (e.g., `KafkaConsumerService`)
- **Methods**: camelCase (e.g., `processFile()`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `POLL_TIMEOUT`)
- **Variables**: camelCase (e.g., `consumerRecord`)

#### Example

```java
public class MyNewService {
    private static final Logger logger = LoggerFactory.getLogger(MyNewService.class);
    private static final int DEFAULT_TIMEOUT = 30;

    private final String serviceName;
    private volatile boolean running = true;

    public MyNewService(String serviceName) {
        this.serviceName = serviceName;
    }

    public void start() {
        logger.info("Starting service: {}", serviceName);
        // Implementation
    }

    public void shutdown() {
        logger.info("Shutting down service: {}", serviceName);
        running = false;
    }
}
```

### Checkstyle Configuration

The project uses Checkstyle for automated style validation:

```bash
# Run Checkstyle
./gradlew checkstyleMain checkstyleTest

# View report
open build/reports/checkstyle/main.html
```

Configuration: `config/checkstyle/checkstyle.xml`

### Best Practices

1. **Use SLF4J for Logging**
   ```java
   private static final Logger logger = LoggerFactory.getLogger(ClassName.class);
   logger.info("Message: {}", variable);  // Use parameterized logging
   ```

2. **Avoid printStackTrace()**
   ```java
   // Bad
   e.printStackTrace();

   // Good
   logger.error("Error processing file", e);
   ```

3. **Use Try-with-Resources**
   ```java
   try (BufferedReader reader = Files.newBufferedReader(path)) {
       // Use reader
   }
   ```

4. **Validate Input**
   ```java
   if (path == null || !Files.exists(path)) {
       logger.error("Invalid path: {}", path);
       return;
   }
   ```

5. **Use Constants**
   ```java
   // Bad
   consumer.poll(100);

   // Good
   consumer.poll(KafkaConfig.POLL_TIMEOUT);
   ```

## Testing Requirements

### Unit Tests (Phase 2 - Upcoming)

While tests are currently minimal, new features should include:

1. **Unit Tests**: Test individual methods and classes
2. **Integration Tests**: Test component interactions
3. **Coverage**: Aim for >80% code coverage

#### Test Structure

```java
class KafkaProducerServiceTest {
    private KafkaProducerService service;

    @BeforeEach
    void setUp() {
        service = new KafkaProducerService();
    }

    @Test
    void testProcessFile() {
        // Given
        Path testFile = createTestFile();

        // When
        service.processFile(testFile);

        // Then
        // Assertions
    }

    @AfterEach
    void tearDown() {
        service.shutdown();
    }
}
```

### Manual Testing

Until automated tests are implemented, manually test:

1. **Build Success**: `./gradlew clean build`
2. **Producer Functionality**: Add files, verify Kafka messages
3. **Consumer Functionality**: Verify output files
4. **Graceful Shutdown**: Ctrl+C works cleanly
5. **Resource Cleanup**: No hanging processes

### Testing Checklist

- [ ] Code compiles without errors
- [ ] No Checkstyle violations
- [ ] No SpotBugs warnings
- [ ] Manual testing completed
- [ ] Documentation updated
- [ ] Examples work as documented

## Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, no logic change)
- **refactor**: Code refactoring (no functional change)
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **chore**: Build process, dependencies, tooling
- **ci**: CI/CD changes

### Examples

```bash
# Feature
git commit -m "feat(consumer): add batch processing support"

# Bug fix
git commit -m "fix(producer): handle null file paths gracefully"

# Documentation
git commit -m "docs(readme): update quick start guide"

# Refactoring
git commit -m "refactor(config): extract constants to KafkaConfig"

# Breaking change
git commit -m "feat(api): change consumer API signature

BREAKING CHANGE: Consumer now requires topic as string instead of int"
```

### Guidelines

- Use imperative mood ("add" not "added")
- Capitalize first letter of subject
- No period at end of subject
- Limit subject line to 50 characters
- Wrap body at 72 characters
- Explain what and why, not how

## Pull Request Process

### Before Creating a PR

1. **Update from Main**
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-branch
   git rebase main
   ```

2. **Run All Checks**
   ```bash
   ./gradlew clean check
   ```

3. **Review Your Changes**
   ```bash
   git diff main...your-branch
   ```

### Creating the PR

1. **Push to Your Fork**
   ```bash
   git push origin your-branch
   ```

2. **Open Pull Request on GitHub**
   - Provide clear title following commit message format
   - Fill out PR template completely
   - Reference related issues (e.g., "Fixes #123")

3. **PR Description Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Changes Made
   - Bullet list of specific changes

   ## Testing
   - How was this tested?
   - What scenarios were covered?

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Documentation updated
   - [ ] No new warnings
   - [ ] Tests added/updated
   ```

### After Creating PR

- Respond to review comments promptly
- Make requested changes in new commits
- Once approved, squash commits if requested
- Maintainer will merge when ready

## Code Review Guidelines

### For Reviewers

When reviewing code:

1. **Be Kind and Constructive**
   - Focus on the code, not the person
   - Suggest improvements, don't demand them
   - Explain the "why" behind suggestions

2. **Check For**
   - Code correctness and logic
   - Style consistency
   - Documentation completeness
   - Test coverage
   - Security implications
   - Performance considerations

3. **Approval Criteria**
   - Code works as intended
   - Follows style guidelines
   - Has appropriate documentation
   - No obvious bugs or security issues
   - Passes all automated checks

### For Contributors

When receiving reviews:

1. **Be Open to Feedback**
   - Reviews are meant to improve the code
   - Ask questions if unclear
   - Learn from suggestions

2. **Respond to Comments**
   - Address all feedback
   - Mark resolved comments
   - Explain your decisions if you disagree

3. **Make Changes**
   - Push new commits addressing feedback
   - Don't force-push unless requested
   - Keep commit history clean

## Documentation Requirements

### When to Update Documentation

Update documentation when you:
- Add a new feature
- Change existing behavior
- Fix a bug that was documented incorrectly
- Add new configuration options
- Change command-line arguments

### What to Update

1. **Code Documentation**
   - Add JavaDoc to all public classes and methods
   - Include parameter descriptions
   - Document exceptions thrown
   - Provide usage examples

2. **README.md**
   - Update if feature affects getting started
   - Add to feature list if applicable

3. **CHANGELOG.md**
   - Add entry under "Unreleased" section
   - Follow format of existing entries

4. **Specialized Docs**
   - BUILD.md for build process changes
   - ARCHITECTURE_REPORT.md for architectural changes
   - SHUTDOWN.md for lifecycle changes
   - New guides for new features

### JavaDoc Example

```java
/**
 * Processes a file by reading its content, splitting into words,
 * and sending each word to the appropriate Kafka topic.
 *
 * <p>Words are routed to topics based on their length. For example,
 * a 5-letter word goes to topic "5".</p>
 *
 * @param filePath the path to the file to process
 * @throws IOException if the file cannot be read
 * @throws IllegalArgumentException if filePath is null or doesn't exist
 */
public void processFile(Path filePath) throws IOException {
    // Implementation
}
```

## Security Considerations

### Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities.

Instead:
1. Email security@example.com (configure this)
2. Or use GitHub Security Advisories
3. Provide detailed description
4. Allow time for fix before public disclosure

### Security Guidelines

When contributing:

1. **Validate Input**
   - Check file paths exist
   - Validate configuration values
   - Sanitize user input

2. **Avoid Hardcoded Secrets**
   - No API keys in code
   - No passwords in code
   - Use environment variables

3. **Dependency Security**
   - Don't downgrade dependency versions
   - Check for known CVEs
   - Run security scans: `./gradlew dependencyCheckAnalyze`

4. **Resource Management**
   - Always close resources (use try-with-resources)
   - Implement proper shutdown
   - Prevent resource leaks

## Getting Help

### Resources

- **Documentation**: Check the [docs](docs/) directory
- **Issues**: Search [existing issues](https://github.com/strawberry-code/kafka-word-splitter/issues)
- **Discussions**: Use [GitHub Discussions](https://github.com/strawberry-code/kafka-word-splitter/discussions)
- **Support**: See [SUPPORT.md](SUPPORT.md)

### Asking Questions

When asking for help:

1. **Search First**: Check if already answered
2. **Be Specific**: Provide exact error messages
3. **Provide Context**: What were you trying to do?
4. **Include Details**: OS, Java version, steps to reproduce
5. **Share Code**: Use code blocks for formatting

### Example Good Question

```
I'm trying to run the producer but getting this error:

Error: Could not find or load main class org.example.ProducerApp

Steps to reproduce:
1. Built with: ./gradlew clean build
2. Ran: java -cp build/libs/kafka-word-splitter-1.0-SNAPSHOT-all.jar org.example.ProducerApp ./input

Environment:
- OS: macOS 13.0
- Java: openjdk 17.0.2
- Project: latest main branch

I've checked that the JAR exists. What am I missing?
```

## Release Process (Maintainers Only)

For project maintainers releasing new versions:

1. **Update Version**: Edit `build.gradle.kts`
2. **Update CHANGELOG.md**: Move "Unreleased" to new version
3. **Create Tag**: `git tag -a v1.0.0 -m "Version 1.0.0"`
4. **Push Tag**: `git push origin v1.0.0`
5. **Create GitHub Release**: Upload artifacts

## Recognition

Contributors will be:
- Listed in [CHANGELOG.md](CHANGELOG.md)
- Mentioned in release notes
- Credited in project documentation

Thank you for contributing to Kafka Word Splitter!

## Questions?

If you have questions about contributing, please:
- Open a [discussion](https://github.com/strawberry-code/kafka-word-splitter/discussions)
- Ask in an existing issue
- Contact the maintainers

---

**Happy Contributing!** We appreciate your interest in making Kafka Word Splitter better.
