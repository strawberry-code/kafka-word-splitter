# CI/CD Pipeline Documentation

## Table of Contents

- [Overview](#overview)
- [Pipeline Architecture](#pipeline-architecture)
- [Pipeline Stages](#pipeline-stages)
- [Local Development Workflow](#local-development-workflow)
- [Running Checks Locally](#running-checks-locally)
- [Manual Pipeline Execution](#manual-pipeline-execution)
- [Interpreting Pipeline Results](#interpreting-pipeline-results)
- [Troubleshooting Failed Pipelines](#troubleshooting-failed-pipelines)
- [Adding New Checks](#adding-new-checks)
- [Performance Optimization](#performance-optimization)
- [Best Practices](#best-practices)

---

## Overview

The Kafka Word Splitter project uses GitHub Actions for continuous integration and continuous delivery (CI/CD). The pipeline automatically builds, tests, and validates every code change to ensure quality and security.

### Pipeline Goals

- **Fast Feedback**: Developers get results within 5-10 minutes
- **Quality Assurance**: Automated checks prevent bugs from reaching production
- **Security**: Dependency scanning catches vulnerabilities early
- **Consistency**: Same checks run locally and in CI
- **Visibility**: Clear reporting of build status and issues

### Triggers

The CI pipeline runs on:

- **Push to any branch**: Full pipeline execution
- **Pull requests to main**: Full pipeline with artifact upload
- **Manual dispatch**: On-demand pipeline runs via GitHub UI

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CI Pipeline Trigger                   │
│            (Push, PR, Manual Dispatch)                   │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              Stage 1: Build and Test                     │
│  - Checkout code                                         │
│  - Setup Java 17                                         │
│  - Cache Gradle dependencies                             │
│  - Run ./gradlew clean build                             │
│  - Execute tests (if present)                            │
│  - Generate coverage report                              │
│  - Upload artifacts (JARs, reports)                      │
└─────────────────────┬───────────────────────────────────┘
                      │
          ┌───────────┴────────────┐
          │                        │
          ▼                        ▼
┌─────────────────────┐  ┌─────────────────────┐
│ Stage 2: Security   │  │ Stage 3: Quality    │
│  - OWASP Dependency │  │  - Checkstyle       │
│  - CVE scanning     │  │  - SpotBugs         │
│  - Fail on CRITICAL │  │  - Code standards   │
│  - Upload reports   │  │  - Upload reports   │
└─────────┬───────────┘  └──────────┬──────────┘
          │                         │
          └────────────┬────────────┘
                       │
                       ▼
          ┌────────────────────────┐
          │ Stage 4: Build Summary │
          │  - Aggregate results   │
          │  - Update badges       │
          │  - Notify status       │
          └────────────────────────┘
```

---

## Pipeline Stages

### Stage 1: Build and Test

**Purpose**: Compile code, run tests, and generate build artifacts

**Duration**: ~2-4 minutes

**Steps**:

1. **Checkout Code**: Clone repository with full history
2. **Setup Java 17**: Install Temurin JDK 17
3. **Cache Dependencies**: Cache Gradle wrapper and dependencies
4. **Validate Gradle Wrapper**: Security check on gradlew files
5. **Build Project**: `./gradlew clean build`
6. **Run Tests**: `./gradlew test` (gracefully handles missing tests)
7. **Generate Coverage**: JaCoCo coverage report
8. **Upload Artifacts**:
   - JAR files (`build/libs/*.jar`)
   - Test results (`build/test-results/`)
   - Coverage reports (`build/reports/jacoco/`)

**Success Criteria**: Build completes without errors

**Artifacts Produced**:
- `kafka-word-splitter-1.0-SNAPSHOT-all.jar` (executable fat JAR)
- Test reports (HTML and XML)
- Coverage reports (HTML and XML)

---

### Stage 2: Security Scanning

**Purpose**: Identify security vulnerabilities in dependencies

**Duration**: ~3-5 minutes (first run), ~1-2 minutes (cached)

**Steps**:

1. **Checkout Code**: Fresh clone for isolation
2. **Setup Java 17**: Install JDK
3. **Run OWASP Dependency Check**: Scan all dependencies
4. **Analyze Results**: Check for HIGH/CRITICAL CVEs
5. **Upload Reports**: Security scan results

**Security Thresholds**:
- **CRITICAL (CVSS 9.0-10.0)**: Build fails immediately
- **HIGH (CVSS 7.0-8.9)**: Build fails immediately
- **MEDIUM (CVSS 4.0-6.9)**: Warning only
- **LOW (CVSS 0.1-3.9)**: Info only

**Artifacts Produced**:
- `dependency-check-report.html`
- `dependency-check-report.json`
- `dependency-check-report.xml`

**Suppression File**: `dependency-check-suppressions.xml` for false positives

---

### Stage 3: Code Quality Checks

**Purpose**: Enforce coding standards and detect potential bugs

**Duration**: ~1-2 minutes

**Steps**:

1. **Checkout Code**: Fresh clone
2. **Setup Java 17**: Install JDK
3. **Run Checkstyle**: Verify code style compliance
4. **Run SpotBugs**: Static analysis for bug patterns
5. **Upload Reports**: Quality check results

**Quality Tools**:

- **Checkstyle 10.12.5**:
  - Enforces Java coding standards
  - Checks naming conventions
  - Validates Javadoc completeness
  - Config: `config/checkstyle/checkstyle.xml`

- **SpotBugs 6.0.7**:
  - Detects bug patterns
  - Finds potential null pointer exceptions
  - Identifies resource leaks
  - Checks concurrency issues

**Artifacts Produced**:
- Checkstyle reports (HTML/XML)
- SpotBugs reports (HTML/XML)

---

### Stage 4: Build Summary

**Purpose**: Aggregate all results and update status

**Duration**: <1 minute

**Steps**:

1. **Collect Results**: From all previous stages
2. **Check Status**: Verify all stages passed
3. **Update Badges**: Build status in README
4. **Generate Summary**: Overall pipeline status

**Failure Conditions**:
- Build and Test stage failed
- Security scan found CRITICAL CVEs
- Quality checks found violations (if strict mode enabled)

---

## Local Development Workflow

### Recommended Workflow

```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes to code
vim src/main/java/org/example/MyClass.java

# 3. Run local CI checks (mimics GitHub Actions)
./scripts/ci-build.sh

# 4. Fix any issues found
# ... make corrections ...

# 5. Run security check
./scripts/security-check.sh

# 6. Run quality checks
./scripts/quality-check.sh

# 7. Commit changes
git add .
git commit -m "Add my feature"

# 8. Push to GitHub (triggers CI pipeline)
git push origin feature/my-feature

# 9. Create pull request
# - CI pipeline runs automatically
# - Review results in PR checks
# - Address any failures
```

### Pre-Commit Checklist

Before committing code, ensure:

- [ ] Code compiles: `./gradlew build`
- [ ] Tests pass: `./gradlew test`
- [ ] Checkstyle passes: `./gradlew checkstyleMain`
- [ ] No security issues: `./gradlew dependencyCheckAnalyze`
- [ ] Javadoc complete for public APIs
- [ ] No debug statements or print statements

---

## Running Checks Locally

### Full CI Build (Recommended)

Run the complete CI pipeline locally:

```bash
./scripts/ci-build.sh
```

This script runs all checks in the same order as GitHub Actions.

### Individual Commands

#### Build Project

```bash
./gradlew clean build
```

Compiles code, runs tests, and creates JAR files.

#### Run Tests

```bash
./gradlew test
```

Executes all JUnit tests.

#### Generate Coverage Report

```bash
./gradlew jacocoTestReport
```

Creates coverage report in `build/reports/jacoco/test/html/index.html`.

#### Run Checkstyle

```bash
./gradlew checkstyleMain checkstyleTest
```

Validates code style. Reports in `build/reports/checkstyle/`.

#### Run SpotBugs

```bash
./gradlew spotbugsMain
```

Static analysis report in `build/reports/spotbugs/`.

#### Security Scan

```bash
./scripts/security-check.sh
```

Or directly:

```bash
./gradlew dependencyCheckAnalyze
```

Report in `build/reports/dependency-check-report.html`.

#### All Quality Checks

```bash
./scripts/quality-check.sh
```

Runs Checkstyle and SpotBugs together.

### Viewing Reports

All reports are generated in `build/reports/`:

```
build/reports/
├── checkstyle/
│   ├── main.html
│   └── test.html
├── jacoco/
│   └── test/html/index.html
├── spotbugs/
│   └── spotbugs.html
├── tests/
│   └── test/index.html
└── dependency-check-report.html
```

Open any HTML file in a browser:

```bash
open build/reports/dependency-check-report.html
```

---

## Manual Pipeline Execution

### Via GitHub UI

1. Go to repository on GitHub
2. Click **Actions** tab
3. Click **CI Pipeline** workflow
4. Click **Run workflow** button
5. Select branch
6. Click **Run workflow**

### Via GitHub CLI

```bash
# Install GitHub CLI (if not installed)
brew install gh

# Authenticate
gh auth login

# Trigger workflow
gh workflow run ci.yml

# Check status
gh run list --workflow=ci.yml
```

---

## Interpreting Pipeline Results

### Successful Build

Green checkmark on GitHub commit/PR:

```
✓ Build and Test
✓ Security Scanning
✓ Code Quality Checks
✓ Build Summary
```

**Next Steps**:
- Review and merge PR
- Deploy to staging (if applicable)

### Failed Build

Red X on GitHub commit/PR:

```
✗ Build and Test
```

**Possible Causes**:
- Compilation errors
- Test failures
- Gradle build errors

**How to Fix**:
1. Click on failed check
2. View logs to identify error
3. Fix locally and push again

### Failed Security Scan

```
✗ Security Scanning
```

**Possible Causes**:
- New dependency with CVE
- Existing dependency updated with new CVE
- CVSS threshold exceeded

**How to Fix**:

1. Review security report artifact
2. Identify vulnerable dependency
3. Options:
   - **Upgrade** dependency to patched version
   - **Replace** with alternative library
   - **Suppress** if false positive (with justification)

Example suppression in `dependency-check-suppressions.xml`:

```xml
<suppress>
    <notes>
        False positive - CVE does not affect our usage
        Reviewed: 2025-11-02
    </notes>
    <cve>CVE-2024-XXXXX</cve>
</suppress>
```

### Failed Quality Checks

```
✗ Code Quality Checks
```

**Possible Causes**:
- Checkstyle violations (naming, formatting, Javadoc)
- SpotBugs issues (potential bugs, bad practices)

**How to Fix**:

1. Download quality report artifacts
2. Open HTML reports in browser
3. Fix each violation
4. Re-run locally: `./scripts/quality-check.sh`
5. Push corrected code

---

## Troubleshooting Failed Pipelines

### Build Fails: "gradlew: Permission denied"

**Cause**: Gradle wrapper not executable

**Fix**:
```bash
chmod +x gradlew
git add gradlew
git commit -m "Make gradlew executable"
git push
```

### Build Fails: "Could not resolve dependency"

**Cause**: Network issue or invalid dependency

**Fix**:
1. Check internet connectivity
2. Verify dependency exists in Maven Central
3. Clear Gradle cache: `./gradlew clean --refresh-dependencies`

### Security Scan Times Out

**Cause**: Large dependency tree or slow NVD database

**Fix**:
1. Increase timeout in workflow (currently 15 minutes)
2. Use cached NVD database
3. Disable specific analyzers in `build.gradle.kts`

### Checkstyle Fails: "Missing Javadoc"

**Cause**: Public methods/classes lack documentation

**Fix**:
1. Add Javadoc to all public APIs
2. Example:
```java
/**
 * Processes a message from Kafka.
 *
 * @param message the message to process
 * @return processed result
 */
public String processMessage(String message) {
    // ...
}
```

### SpotBugs Fails: "Potential null pointer"

**Cause**: Insufficient null checking

**Fix**:
1. Add null checks:
```java
if (value == null) {
    throw new IllegalArgumentException("Value cannot be null");
}
```

2. Or suppress if false positive:
```java
@SuppressFBWarnings(value = "NP_NULL_ON_SOME_PATH",
                     justification = "Value is guaranteed non-null by caller")
```

---

## Adding New Checks

### Adding a New Gradle Plugin

1. **Update `build.gradle.kts`**:

```kotlin
plugins {
    id("new-plugin-id") version "1.0.0"
}

// Plugin configuration
newPlugin {
    setting = "value"
}
```

2. **Update CI workflow** (`.github/workflows/ci.yml`):

```yaml
- name: Run New Check
  run: ./gradlew newPluginTask --no-daemon --stacktrace
```

3. **Test locally**:
```bash
./gradlew newPluginTask
```

4. **Update documentation** (this file)

### Adding a New GitHub Action

1. **Edit `.github/workflows/ci.yml`**:

```yaml
- name: My New Step
  uses: some-action@v1
  with:
    param: value
```

2. **Test with workflow dispatch**
3. **Monitor first execution**
4. **Document in this file**

---

## Performance Optimization

### Current Performance

- **Build and Test**: 2-4 minutes
- **Security Scan**: 1-5 minutes (depends on cache)
- **Code Quality**: 1-2 minutes
- **Total**: 5-10 minutes

### Optimization Strategies

#### 1. Gradle Build Cache

Already enabled via `GRADLE_OPTS` in workflow:

```yaml
env:
  GRADLE_OPTS: "-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Dorg.gradle.caching=true"
```

#### 2. Dependency Caching

Using GitHub Actions cache:

```yaml
- name: Set up JDK 17
  uses: actions/setup-java@v4
  with:
    cache: 'gradle'  # Caches ~/.gradle/caches and ~/.gradle/wrapper
```

#### 3. Parallel Execution

Currently using Gradle parallel execution. To add job-level parallelism:

```yaml
# Run security and quality in parallel
security-scan:
  needs: build-and-test  # Wait for build, but run parallel to quality

code-quality:
  needs: build-and-test  # Wait for build, but run parallel to security
```

#### 4. Incremental Builds

Gradle incremental compilation is enabled by default.

#### 5. Test Optimization

When tests are added:
- Use `@Tag` to separate fast/slow tests
- Run fast tests in CI, slow tests nightly
- Parallelize test execution

---

## Best Practices

### For Developers

1. **Run checks locally before pushing**
   - Use `./scripts/ci-build.sh`
   - Fix issues early

2. **Keep commits focused**
   - One logical change per commit
   - Easier to debug CI failures

3. **Write meaningful commit messages**
   - Helps understand CI failures in context

4. **Monitor CI pipeline**
   - Don't walk away after pushing
   - Address failures immediately

5. **Keep dependencies updated**
   - Regular `./gradlew dependencyUpdates`
   - Review security scan reports

### For DevOps

1. **Monitor pipeline performance**
   - Track build times
   - Identify bottlenecks

2. **Keep actions updated**
   - Dependabot for GitHub Actions
   - Test updates in separate branch

3. **Review security suppressions**
   - Monthly audit
   - Remove outdated suppressions

4. **Optimize caching**
   - Verify cache hit rates
   - Adjust cache keys if needed

5. **Document changes**
   - Update this file
   - Communicate with team

---

## CI/CD Metrics

Track these metrics for continuous improvement:

| Metric | Target | Current |
|--------|--------|---------|
| Build time | <5 minutes | 5-10 minutes |
| Success rate | >95% | TBD |
| Time to feedback | <10 minutes | 5-10 minutes |
| Security scan coverage | 100% | 100% |
| Code quality pass rate | >90% | TBD |

---

## Related Documentation

- [Branch Protection Rules](.github/BRANCH_PROTECTION.md)
- [Security Policy](../SECURITY.md)
- [Build Documentation](../BUILD.md)
- [Architecture Report](../ARCHITECTURE_REPORT.md)

---

## Support

### Issues with CI/CD Pipeline

1. Check [GitHub Actions status page](https://www.githubstatus.com/)
2. Review workflow logs in GitHub UI
3. Run locally: `./scripts/ci-build.sh`
4. Contact DevOps team

### Questions or Suggestions

- Open a GitHub issue with label `ci/cd`
- Discuss in team chat
- Submit PR with improvements

---

## Change Log

| Date | Author          | Change |
|------|-----------------|--------|
| 2025-11-02 | strawberry-code | Initial CI/CD pipeline documentation |

---

**Happy Building!** The CI/CD pipeline is here to help you ship quality code faster.
