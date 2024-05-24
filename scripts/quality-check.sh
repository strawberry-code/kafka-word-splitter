#!/bin/bash

###############################################################################
# Quality Check Script
#
# Runs code quality checks (Checkstyle and SpotBugs).
# This mimics the code quality stage of the CI pipeline.
#
# Usage:
#   ./scripts/quality-check.sh
#
# Exit codes:
#   0 - All quality checks passed
#   1 - Quality violations found
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
echo -e "${BLUE}    Code Quality Checks${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Change to project root
cd "${PROJECT_ROOT}"

# Validate Gradle wrapper
if [ ! -x "./gradlew" ]; then
    echo -e "${YELLOW}Making gradlew executable...${NC}"
    chmod +x ./gradlew
fi

CHECKSTYLE_PASSED=true
SPOTBUGS_PASSED=true

# Step 1: Run Checkstyle
echo -e "${YELLOW}Step 1: Running Checkstyle...${NC}"
echo -e "${BLUE}Checking code style compliance...${NC}"
echo ""

if ./gradlew checkstyleMain checkstyleTest --no-daemon --stacktrace; then
    echo -e "${GREEN}✓ Checkstyle passed${NC}"
else
    echo -e "${RED}✗ Checkstyle violations found${NC}"
    CHECKSTYLE_PASSED=false
fi

echo ""

# Check for Checkstyle reports
CHECKSTYLE_MAIN_REPORT="build/reports/checkstyle/main.html"
CHECKSTYLE_TEST_REPORT="build/reports/checkstyle/test.html"

if [ -f "${CHECKSTYLE_MAIN_REPORT}" ]; then
    echo -e "${BLUE}Checkstyle main report: ${CHECKSTYLE_MAIN_REPORT}${NC}"
fi

if [ -f "${CHECKSTYLE_TEST_REPORT}" ]; then
    echo -e "${BLUE}Checkstyle test report: ${CHECKSTYLE_TEST_REPORT}${NC}"
fi

echo ""

# Step 2: Run SpotBugs
echo -e "${YELLOW}Step 2: Running SpotBugs...${NC}"
echo -e "${BLUE}Analyzing code for potential bugs...${NC}"
echo ""

if ./gradlew spotbugsMain --no-daemon --stacktrace; then
    echo -e "${GREEN}✓ SpotBugs passed${NC}"
else
    echo -e "${RED}✗ SpotBugs found potential issues${NC}"
    SPOTBUGS_PASSED=false
fi

echo ""

# Check for SpotBugs report
SPOTBUGS_REPORT="build/reports/spotbugs/spotbugs.html"

if [ -f "${SPOTBUGS_REPORT}" ]; then
    echo -e "${BLUE}SpotBugs report: ${SPOTBUGS_REPORT}${NC}"
fi

echo ""

# Step 3: Summary
echo -e "${BLUE}========================================${NC}"

if [ "$CHECKSTYLE_PASSED" = true ] && [ "$SPOTBUGS_PASSED" = true ]; then
    echo -e "${GREEN}  Quality Checks: SUCCESS${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}All quality checks passed!${NC}"
    echo ""
    echo -e "Reports generated:"
    [ -f "${CHECKSTYLE_MAIN_REPORT}" ] && echo -e "  - Checkstyle (main): ${CHECKSTYLE_MAIN_REPORT}"
    [ -f "${CHECKSTYLE_TEST_REPORT}" ] && echo -e "  - Checkstyle (test): ${CHECKSTYLE_TEST_REPORT}"
    [ -f "${SPOTBUGS_REPORT}" ] && echo -e "  - SpotBugs: ${SPOTBUGS_REPORT}"
    echo ""
    echo -e "Next steps:"
    echo -e "  - Commit your changes"
    echo -e "  - Push to GitHub for full CI validation"
    echo ""
    exit 0
else
    echo -e "${RED}  Quality Checks: FAILED${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${RED}Quality violations found!${NC}"
    echo ""

    if [ "$CHECKSTYLE_PASSED" = false ]; then
        echo -e "${RED}Checkstyle violations:${NC}"
        echo -e "  - Review: ${CHECKSTYLE_MAIN_REPORT}"
        echo -e "  - Common issues: naming conventions, Javadoc, formatting"
        echo -e "  - Config: config/checkstyle/checkstyle.xml"
        echo ""
    fi

    if [ "$SPOTBUGS_PASSED" = false ]; then
        echo -e "${RED}SpotBugs issues:${NC}"
        echo -e "  - Review: ${SPOTBUGS_REPORT}"
        echo -e "  - Common issues: null pointers, resource leaks, bad practices"
        echo ""
    fi

    echo -e "Action required:"
    echo -e "  1. Open the report files in your browser"
    echo -e "  2. Fix each violation"
    echo -e "  3. Re-run: ./scripts/quality-check.sh"
    echo -e "  4. Commit when all checks pass"
    echo ""

    echo -e "To view reports:"
    [ -f "${CHECKSTYLE_MAIN_REPORT}" ] && echo -e "  open ${CHECKSTYLE_MAIN_REPORT}"
    [ -f "${SPOTBUGS_REPORT}" ] && echo -e "  open ${SPOTBUGS_REPORT}"
    echo ""

    exit 1
fi
