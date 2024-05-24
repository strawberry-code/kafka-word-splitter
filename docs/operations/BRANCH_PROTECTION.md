# Branch Protection Rules

## Overview

This document outlines the recommended branch protection rules for the Kafka Word Splitter repository. These rules ensure code quality, prevent accidental deletions, and enforce a review process for all changes to critical branches.

## Recommended Settings for `main` Branch

### Basic Protection

Apply these settings to the `main` branch via GitHub Settings > Branches > Branch protection rules:

#### 1. Require Pull Request Reviews Before Merging

- **Setting**: Enable "Require a pull request before merging"
- **Required approvals**: 1 (increase to 2 for production-critical projects)
- **Dismiss stale pull request approvals when new commits are pushed**: Enabled
- **Require review from Code Owners**: Optional (requires CODEOWNERS file)
- **Restrict who can dismiss pull request reviews**: Recommended for teams
- **Allow specified actors to bypass pull request requirements**: Disabled (unless specific need)

**Rationale**: Ensures all code is reviewed by at least one other developer before merging, catching bugs and improving code quality.

#### 2. Require Status Checks to Pass Before Merging

- **Setting**: Enable "Require status checks to pass before merging"
- **Require branches to be up to date before merging**: Enabled
- **Status checks that are required**:
  - `Build and Test` (from CI workflow)
  - `Security Scanning` (from CI workflow)
  - `Code Quality Checks` (from CI workflow)

**Rationale**: Prevents merging code that breaks the build, fails tests, or has security vulnerabilities.

#### 3. Require Conversation Resolution Before Merging

- **Setting**: Enable "Require conversation resolution before merging"

**Rationale**: Ensures all review comments and discussions are addressed before merging.

#### 4. Require Signed Commits

- **Setting**: Optional - Enable "Require signed commits"
- **Recommended**: For high-security environments

**Rationale**: Ensures commit authenticity and prevents impersonation.

#### 5. Require Linear History

- **Setting**: Optional - Enable "Require linear history"
- **Recommended**: For teams preferring a clean git history

**Rationale**: Prevents merge commits, enforcing rebase or squash-and-merge strategies.

#### 6. Include Administrators

- **Setting**: Enable "Include administrators"

**Rationale**: Ensures even administrators follow the same rules, preventing accidental bypass of quality checks.

#### 7. Restrict Push Access

- **Setting**: Enable "Restrict who can push to matching branches"
- **Restrict pushes that create matching branches**: Recommended
- **Allowed actors**: Only CI/CD service accounts (if any)

**Rationale**: Prevents direct pushes to main, enforcing the PR workflow.

#### 8. Allow Force Pushes

- **Setting**: Disable "Allow force pushes"

**Rationale**: Prevents rewriting history on the main branch, which could cause issues for other developers.

#### 9. Allow Deletions

- **Setting**: Disable "Allow deletions"

**Rationale**: Prevents accidental deletion of the main branch.

---

## Implementation Steps

### Step 1: Navigate to Branch Protection Settings

1. Go to your repository on GitHub
2. Click **Settings** tab
3. Click **Branches** in the left sidebar
4. Click **Add rule** or edit existing rule

### Step 2: Configure Branch Name Pattern

- Branch name pattern: `main`
- Alternative: Use wildcards like `release/*` for release branches

### Step 3: Apply Recommended Settings

Check the boxes for each protection rule listed above.

### Step 4: Save Changes

Click **Create** or **Save changes** at the bottom.

---

## Additional Branch Protection Recommendations

### Development Branches

For development or feature branches (e.g., `develop`, `staging`):

- Require pull request reviews: 1 approval
- Require status checks: Build and Test only
- Allow force pushes: Enabled (for rebasing)
- Include administrators: Disabled (more flexibility)

### Release Branches

For release branches (e.g., `release/*`, `v*`):

- Require pull request reviews: 2 approvals
- Require status checks: All checks required
- Require signed commits: Enabled
- Restrict push access: Highly restricted
- Include administrators: Enabled
- Allow force pushes: Disabled
- Allow deletions: Disabled

---

## Status Check Configuration

The following status checks should be configured in the CI workflow and required for merging:

| Status Check Name | Description | Workflow Job |
|------------------|-------------|--------------|
| Build and Test | Builds the project and runs all tests | `build-and-test` |
| Security Scanning | Scans dependencies for vulnerabilities | `security-scan` |
| Code Quality Checks | Runs Checkstyle and SpotBugs | `code-quality` |

---

## CODEOWNERS File (Optional)

Create a `.github/CODEOWNERS` file to automatically request reviews from specific people or teams:

```
# Global owners
* @your-username

# Java source code
*.java @java-team

# Build configuration
*.gradle.kts @devops-team
build.gradle.kts @devops-team

# CI/CD configuration
.github/workflows/* @devops-team

# Security-sensitive files
dependency-check-suppressions.xml @security-team
```

---

## Enforcement Timeline

### Phase 1: Soft Enforcement (Week 1-2)

- Enable branch protection with warnings only
- Allow bypasses for administrators
- Monitor compliance and educate team

### Phase 2: Full Enforcement (Week 3+)

- Remove bypass permissions
- Include administrators in rules
- Strictly enforce all checks

---

## Troubleshooting

### Pull Request Can't Be Merged

**Issue**: PR is blocked by branch protection rules

**Solutions**:
1. Ensure all status checks pass (check CI pipeline)
2. Get required approvals from reviewers
3. Resolve all conversations
4. Update branch with latest main: `git pull origin main`
5. Fix any merge conflicts

### Status Check Not Showing

**Issue**: Required status check not appearing in PR

**Solutions**:
1. Verify workflow file syntax is correct
2. Push a new commit to trigger CI
3. Check GitHub Actions tab for errors
4. Ensure workflow has `pull_request` trigger

### Administrator Bypass Not Working

**Issue**: Administrator can't bypass rules even in emergency

**Solutions**:
1. Temporarily disable "Include administrators" setting
2. Merge the critical fix
3. Re-enable "Include administrators" immediately after
4. Document the bypass in incident log

---

## Maintenance

### Review Schedule

- **Monthly**: Review branch protection effectiveness
- **Quarterly**: Update rules based on team feedback
- **Annually**: Comprehensive security audit

### Metrics to Track

- Number of blocked PRs (should decrease over time)
- Time to merge (should stabilize)
- Number of rule bypasses (should be rare)
- Build failure rate (should decrease)

---

## References

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Required Status Checks](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-status-checks-before-merging)
- [CODEOWNERS Documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)

---

## Change Log

| Date | Author          | Change |
|------|-----------------|--------|
| 2025-11-02 | strawberry-code | Initial branch protection rules created |

---

**Note**: These are recommendations based on industry best practices. Adjust based on your team size, project criticality, and workflow preferences.
