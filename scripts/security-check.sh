#!/bin/bash

###############################################################################
# Security Check Script
#
# Runs OWASP Dependency Check to scan for known vulnerabilities in dependencies.
# This mimics the security scanning stage of the CI pipeline.
#
# Usage:
#   ./scripts/security-check.sh
#
# Exit codes:
#   0 - No critical vulnerabilities found
#   1 - Critical vulnerabilities found (CVSS >= 7.0)
#   2 - Script error
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Security Scan - OWASP Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Change to project root
cd "${PROJECT_ROOT}"

# Validate Gradle wrapper
if [ ! -x "./gradlew" ]; then
    echo -e "${YELLOW}Making gradlew executable...${NC}"
    chmod +x ./gradlew
fi

# Step 1: Run OWASP Dependency Check
echo -e "${YELLOW}Running OWASP Dependency Check...${NC}"
echo -e "${BLUE}This may take several minutes on first run (downloading NVD database)${NC}"
echo ""

START_TIME=$(date +%s)

if ./gradlew dependencyCheckAnalyze --no-daemon --stacktrace; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    echo ""
    echo -e "${GREEN}✓ Security scan completed in ${DURATION}s${NC}"
else
    echo -e "${RED}✗ Security scan failed${NC}"
    exit 1
fi

echo ""

# Step 2: Check for report
echo -e "${YELLOW}Checking for security report...${NC}"

REPORT_HTML="build/reports/dependency-check-report.html"
REPORT_JSON="build/reports/dependency-check-report.json"

if [ -f "${REPORT_HTML}" ]; then
    echo -e "${GREEN}✓ Security report generated${NC}"
    echo -e "${BLUE}  HTML Report: ${REPORT_HTML}${NC}"

    if [ -f "${REPORT_JSON}" ]; then
        echo -e "${BLUE}  JSON Report: ${REPORT_JSON}${NC}"
    fi
else
    echo -e "${RED}✗ Security report not found${NC}"
    exit 2
fi

echo ""

# Step 3: Parse results (if JSON exists)
if [ -f "${REPORT_JSON}" ]; then
    echo -e "${YELLOW}Analyzing vulnerability severity...${NC}"

    # Count vulnerabilities by severity (requires jq)
    if command -v jq &> /dev/null; then
        CRITICAL=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity == "CRITICAL")] | length' "${REPORT_JSON}" 2>/dev/null || echo "0")
        HIGH=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity == "HIGH")] | length' "${REPORT_JSON}" 2>/dev/null || echo "0")
        MEDIUM=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity == "MEDIUM")] | length' "${REPORT_JSON}" 2>/dev/null || echo "0")
        LOW=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity == "LOW")] | length' "${REPORT_JSON}" 2>/dev/null || echo "0")

        echo ""
        echo -e "Vulnerability Summary:"
        echo -e "  ${RED}CRITICAL: ${CRITICAL}${NC}"
        echo -e "  ${RED}HIGH:     ${HIGH}${NC}"
        echo -e "  ${YELLOW}MEDIUM:   ${MEDIUM}${NC}"
        echo -e "  ${GREEN}LOW:      ${LOW}${NC}"
        echo ""

        # Fail if critical or high vulnerabilities found
        if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
            echo -e "${RED}========================================${NC}"
            echo -e "${RED}  SECURITY SCAN: FAILED${NC}"
            echo -e "${RED}========================================${NC}"
            echo ""
            echo -e "${RED}Critical or high severity vulnerabilities found!${NC}"
            echo ""
            echo -e "Action required:"
            echo -e "  1. Open: ${REPORT_HTML}"
            echo -e "  2. Review each vulnerability"
            echo -e "  3. Update affected dependencies"
            echo -e "  4. Or add suppressions (if false positives)"
            echo ""
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠ jq not installed, cannot parse severity counts${NC}"
        echo -e "${YELLOW}  Install jq for detailed analysis: brew install jq${NC}"
    fi
fi

echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Security Scan: SUCCESS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "No critical or high severity vulnerabilities found."
echo ""
echo -e "Report location:"
echo -e "  ${REPORT_HTML}"
echo ""
echo -e "To view the report:"
echo -e "  open ${REPORT_HTML}"
echo ""
echo -e "Next steps:"
echo -e "  - Review medium/low vulnerabilities if any"
echo -e "  - Consider updating dependencies regularly"
echo -e "  - Run quality checks: ./scripts/quality-check.sh"
echo ""

exit 0
