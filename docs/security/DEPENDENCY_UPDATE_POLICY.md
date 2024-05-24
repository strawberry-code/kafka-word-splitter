# Dependency Update Policy

## Overview

This document defines the policy and procedures for maintaining up-to-date and secure dependencies in the kafka-word-splitter project. Following this policy will help prevent the accumulation of security vulnerabilities and technical debt.

---

## Core Principles

1. **Security First**: Security vulnerabilities take priority over feature development
2. **Stay Current**: Dependencies should be updated regularly, not only when vulnerabilities are discovered
3. **Test Thoroughly**: All dependency updates must be verified with comprehensive testing
4. **Document Changes**: All updates must be documented with rationale and impact analysis

---

## Dependency Categories

### Critical Dependencies
Dependencies that directly affect security or core functionality:
- Apache Kafka Clients
- Logging frameworks (SLF4J, Logback)
- Serialization libraries
- Network/HTTP libraries

**Update Frequency**: Monthly check, immediate update for critical CVEs
**Testing Requirement**: Full integration testing

### Standard Dependencies
General-purpose libraries and utilities:
- Guava
- JUnit
- Build plugins

**Update Frequency**: Quarterly check
**Testing Requirement**: Standard test suite

### Build Tools
Gradle wrapper, build plugins:
- Gradle
- Shadow plugin
- Dependency-Check plugin

**Update Frequency**: Semi-annually or when needed for features
**Testing Requirement**: Verify build succeeds

---

## Vulnerability Response Process

### Severity Levels

#### CRITICAL (CVSS 9.0-10.0)
- **Response Time**: Within 24 hours
- **Action**: Immediate patch deployment
- **Approval**: Security team approval required
- **Testing**: Expedited testing in staging
- **Communication**: Notify all stakeholders immediately

#### HIGH (CVSS 7.0-8.9)
- **Response Time**: Within 1 week
- **Action**: Priority patch deployment
- **Approval**: Team lead approval required
- **Testing**: Standard testing cycle
- **Communication**: Status update to team

#### MEDIUM (CVSS 4.0-6.9)
- **Response Time**: Within 1 month
- **Action**: Scheduled update in next sprint
- **Approval**: Standard review process
- **Testing**: Full test suite
- **Communication**: Include in sprint planning

#### LOW (CVSS 0.1-3.9)
- **Response Time**: Next quarterly update
- **Action**: Batch with other updates
- **Approval**: Standard review process
- **Testing**: Standard test suite
- **Communication**: Include in release notes

---

## Update Procedures

### 1. Monitoring Phase

#### Automated Monitoring (Recommended Tools)
```gradle
// Add to build.gradle.kts
plugins {
    id("org.owasp.dependencycheck") version "9.0.9"
}

dependencyCheck {
    format = "ALL"
    failBuildOnCVSS = 7.0f
    suppressionFiles = ["dependency-suppression.xml"]
}
```

#### Manual Monitoring
- Subscribe to security advisories:
  - Apache Kafka security mailing list
  - GitHub Security Advisories
  - National Vulnerability Database (NVD)
  - Snyk/Dependabot alerts (if using GitHub)

#### Monthly Dependency Check
Run on the first Monday of each month:
```bash
./gradlew dependencyUpdates
./gradlew dependencyCheckAnalyze
```

### 2. Research Phase

Before updating any dependency:

1. **Review Release Notes**
   - Identify breaking changes
   - Note new features
   - Check deprecations
   - Review migration guides

2. **Check Compatibility**
   - Java version requirements
   - Transitive dependency impacts
   - API compatibility
   - Framework compatibility

3. **Assess Risk**
   - Breaking change impact
   - Test coverage adequacy
   - Rollback complexity
   - Deployment risk

4. **Review CVE Details**
   - Read full CVE description
   - Understand attack vectors
   - Assess applicability to project
   - Verify fix completeness

### 3. Update Phase

#### Step-by-Step Process

1. **Create Update Branch**
   ```bash
   git checkout -b security/update-[dependency]-[version]
   ```

2. **Update build.gradle.kts**
   ```kotlin
   // Document reason for update
   implementation("org.apache.kafka:kafka-clients:3.8.0") // CVE-2024-31141
   ```

3. **Clear Gradle Cache**
   ```bash
   ./gradlew clean
   rm -rf .gradle
   ```

4. **Verify Build**
   ```bash
   ./gradlew clean build
   ```

5. **Run Tests**
   ```bash
   ./gradlew test
   ./gradlew integrationTest  # if exists
   ```

6. **Run Vulnerability Scan**
   ```bash
   ./gradlew dependencyCheckAnalyze
   ```

7. **Check for Deprecations**
   ```bash
   ./gradlew compileJava --warning-mode all
   ```

### 4. Testing Phase

#### Required Tests
- Unit tests must pass
- Integration tests must pass
- Manual smoke testing
- Performance regression testing (if applicable)
- Security validation

#### Test Checklist
- [ ] Application starts successfully
- [ ] Core functionality works
- [ ] Kafka producer sends messages
- [ ] Kafka consumer receives messages
- [ ] Logging outputs correctly
- [ ] No runtime errors in logs
- [ ] No memory leaks (if long-running test available)

### 5. Documentation Phase

Document in commit message and security report:
- Dependency updated
- Version change (from → to)
- CVEs fixed (if applicable)
- Breaking changes (if any)
- Code changes required (if any)
- Testing performed

Example commit message:
```
security: Upgrade kafka-clients to 3.8.0 to fix CVE-2024-31141

- Patches CVE-2024-31141 (CVSS 6.8) - Privilege escalation vulnerability
- Upgrades from kafka-clients 3.4.0 to 3.8.0
- No breaking changes, backward compatible
- All tests pass
- Build verified successful

Tested:
- Compilation: PASS
- Unit tests: PASS
- Integration: Manual verification PASS

Related: CVE-2024-31141
```

### 6. Review Phase

#### Code Review Checklist
- [ ] build.gradle.kts changes reviewed
- [ ] Dependency versions correct
- [ ] No unnecessary dependency additions
- [ ] Security report documentation complete
- [ ] CVE verification performed
- [ ] Compatibility notes reviewed
- [ ] Test results verified
- [ ] Rollback plan documented

#### Approval Requirements
- Critical/High: 2 approvals (including security team)
- Medium: 1 approval
- Low: Standard review process

### 7. Deployment Phase

1. **Merge to Main**
   ```bash
   git checkout main
   git merge security/update-[dependency]-[version]
   git push origin main
   ```

2. **Tag Release** (if applicable)
   ```bash
   git tag -a v1.0.1-security-patch -m "Security patch: CVE-2024-31141"
   git push origin v1.0.1-security-patch
   ```

3. **Deploy to Staging**
   - Monitor for 24-48 hours
   - Check logs for errors
   - Verify metrics

4. **Deploy to Production**
   - Follow standard deployment process
   - Enhanced monitoring for 7 days
   - Keep rollback plan ready

---

## Dependency Version Strategy

### Version Selection Guidelines

1. **Prefer Stable Releases**
   - Avoid alpha, beta, RC versions in production
   - Use only stable, production-ready versions

2. **Stay on Supported Versions**
   - Check vendor support lifecycle
   - Plan migrations before EOL dates

3. **Balance Currency and Stability**
   - Don't always jump to bleeding edge
   - Allow time for community to find issues
   - Wait 2-4 weeks after major releases before upgrading (unless critical CVE)

4. **Version Patterns**
   - Kafka: Use latest stable patch version (3.8.x)
   - Logback: Use latest stable minor version (1.4.x)
   - SLF4J: Match Logback requirements

### Version Documentation

Maintain in build.gradle.kts:
```kotlin
// Security-critical dependencies - update monthly
val kafkaVersion = "3.8.0"          // Last checked: 2025-11-02
val logbackVersion = "1.4.14"       // Last checked: 2025-11-02
val slf4jVersion = "2.0.9"          // Last checked: 2025-11-02

// Standard dependencies - update quarterly
val guavaVersion = "32.1.0-jre"     // Last checked: 2025-11-02

dependencies {
    implementation("org.apache.kafka:kafka-clients:$kafkaVersion")
    implementation("ch.qos.logback:logback-classic:$logbackVersion")
    implementation("org.slf4j:slf4j-api:$slf4jVersion")
    implementation("com.google.guava:guava:$guavaVersion")
}
```

---

## Automated Dependency Management

### GitHub Dependabot (Recommended)

Create `.github/dependabot.yml`:
```yaml
version: 2
updates:
  - package-ecosystem: "gradle"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 5

    # Group non-security updates
    groups:
      development-dependencies:
        patterns:
          - "org.junit*"
          - "com.github.johnrengelman.shadow"

    # Security updates are always created individually
    labels:
      - "dependencies"
      - "security"

    # Require security review
    reviewers:
      - "security-team"

    # Version update strategies
    versioning-strategy: increase
```

### Gradle Version Catalog (Future Enhancement)

Consider migrating to Gradle version catalogs for centralized dependency management:

`gradle/libs.versions.toml`:
```toml
[versions]
kafka = "3.8.0"
logback = "1.4.14"
slf4j = "2.0.9"
guava = "32.1.0-jre"

[libraries]
kafka-clients = { module = "org.apache.kafka:kafka-clients", version.ref = "kafka" }
logback-classic = { module = "ch.qos.logback:logback-classic", version.ref = "logback" }
slf4j-api = { module = "org.slf4j:slf4j-api", version.ref = "slf4j" }
guava = { module = "com.google.guava:guava", version.ref = "guava" }
```

---

## Dependency Suppression

### When to Suppress CVEs

Only suppress CVEs when:
1. CVE is not applicable (false positive)
2. Attack vector is not possible in this application
3. Vendor has confirmed CVE does not affect this use case
4. Fix is not available and mitigation is in place

### Suppression File Format

Create `dependency-suppression.xml` if needed:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
    <!-- Example: Suppress false positive -->
    <suppress>
        <notes>
            CVE-XXXX-XXXXX is not applicable to our use case because we don't use
            the vulnerable component (logback receiver). Verified on 2025-11-02.
            Re-evaluate: 2025-12-02
        </notes>
        <cve>CVE-XXXX-XXXXX</cve>
    </suppress>
</suppressions>
```

**Important**:
- Document reason for suppression
- Set re-evaluation date
- Review suppressions quarterly
- Remove suppressions when no longer needed

---

## Rollback Procedures

### When to Rollback

Rollback immediately if:
- Build failures that can't be quickly resolved
- Critical functionality broken
- Performance degradation > 20%
- New security vulnerabilities introduced
- Customer-facing errors in production

### Rollback Steps

1. **Immediate Action**
   ```bash
   git revert [commit-hash]
   git push origin main
   ```

2. **Redeploy Previous Version**
   - Deploy last known good version
   - Verify functionality restored

3. **Incident Documentation**
   - Document what went wrong
   - Identify root cause
   - Plan alternative approach

4. **Re-attempt Update**
   - Fix identified issues
   - Additional testing
   - Phased rollout

---

## Security Contacts

### Internal Contacts
- Security Team Lead: [email/slack]
- DevOps Lead: [email/slack]
- Development Lead: [email/slack]

### External Resources
- Apache Kafka Security: security@kafka.apache.org
- Logback Issues: logback-dev@qos.ch
- CERT/CC: cert@cert.org

### Vulnerability Disclosure
- Internal: security@[company].com
- Public: Follow responsible disclosure guidelines

---

## Compliance and Auditing

### Audit Trail Requirements
- All dependency changes must be in git history
- Security updates must have associated CVE documentation
- Quarterly dependency review meeting required
- Annual security audit of all dependencies

### Audit Checklist
- [ ] All dependencies have known, supported versions
- [ ] No dependencies with CRITICAL or HIGH CVEs
- [ ] All suppressions are documented and reviewed
- [ ] Dependency update schedule is being followed
- [ ] Security advisories are being monitored
- [ ] Team is trained on security procedures

### Quarterly Review Meeting Agenda
1. Review current dependency versions
2. Check for pending security updates
3. Review suppressed CVEs
4. Assess technical debt in dependencies
5. Plan major version migrations
6. Update this policy if needed

---

## Best Practices

### Do's
- Run dependency checks before every release
- Update security-critical dependencies promptly
- Document all changes thoroughly
- Test updates in isolation
- Keep staging environment current
- Maintain rollback capability
- Subscribe to security advisories
- Use explicit version numbers (not ranges)

### Don'ts
- Don't ignore security warnings
- Don't batch critical security updates with features
- Don't use outdated dependencies "because they work"
- Don't skip testing after updates
- Don't use SNAPSHOT versions in production
- Don't suppress CVEs without documentation
- Don't delay security updates for convenience

---

## Metrics and KPIs

Track these metrics monthly:

1. **Dependency Freshness**
   - Average age of dependencies
   - Number of major versions behind
   - Target: < 6 months old

2. **Vulnerability Response Time**
   - Time to patch CRITICAL: Target < 24h
   - Time to patch HIGH: Target < 7 days
   - Time to patch MEDIUM: Target < 30 days

3. **Update Success Rate**
   - Percentage of updates deployed without rollback
   - Target: > 95%

4. **Security Posture**
   - Number of known CVEs in production
   - Target: 0 CRITICAL, 0 HIGH
   - MEDIUM acceptable with documented mitigation

---

## Training and Awareness

### Required Training
All developers must:
- Understand this policy
- Know how to check for CVEs
- Know how to update dependencies
- Know when to escalate to security team

### Onboarding Checklist
- [ ] Read this policy document
- [ ] Review SECURITY.md report
- [ ] Understand CVE severity levels
- [ ] Know how to run dependency checks
- [ ] Have access to security communication channels

---

## Policy Review

This policy should be reviewed and updated:
- Annually (scheduled review)
- After major security incidents
- When new tools become available
- When team structure changes
- When technology stack changes

**Last Review**: 2025-11-02
**Next Review**: 2026-11-02
**Policy Version**: 1.0
**Owner**: Security Advisor

---

## Appendix: Useful Commands

### Dependency Management
```bash
# List all dependencies
./gradlew dependencies

# Check for updates
./gradlew dependencyUpdates

# Analyze for vulnerabilities (requires plugin)
./gradlew dependencyCheckAnalyze

# View dependency insight
./gradlew dependencyInsight --dependency kafka-clients

# Generate dependency report
./gradlew htmlDependencyReport
```

### Build Verification
```bash
# Clean build
./gradlew clean build

# Run tests
./gradlew test

# Build without daemon (CI)
./gradlew clean build --no-daemon

# Check for deprecations
./gradlew compileJava --warning-mode all
```

### Version Checking
```bash
# Current Java version
java -version

# Current Gradle version
./gradlew --version

# Gradle wrapper version
grep distributionUrl gradle/wrapper/gradle-wrapper.properties
```

---

## Appendix: CVE Resources

### Primary Sources
- National Vulnerability Database: https://nvd.nist.gov/
- GitHub Advisory Database: https://github.com/advisories
- Apache Kafka CVE List: https://kafka.apache.org/cve-list.html
- Logback News: https://logback.qos.ch/news.html

### Vulnerability Scanners
- OWASP Dependency-Check: https://owasp.org/www-project-dependency-check/
- Snyk: https://snyk.io/
- Trivy: https://github.com/aquasecurity/trivy
- Grype: https://github.com/anchore/grype

### Education
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- CWE Top 25: https://cwe.mitre.org/top25/
- CVSS Calculator: https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator

---

**Policy Status**: ACTIVE
**Effective Date**: 2025-11-02
**Authority**: strawberry-code
