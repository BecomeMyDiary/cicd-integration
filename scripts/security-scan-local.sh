#!/usr/bin/env bash
# =============================================================
# Local Security Scan Script
# =============================================================
# Run all DevSecOps security checks locally before pushing
# to GitHub. This mirrors the CI/CD pipeline checks.
#
# Usage:
#   chmod +x scripts/security-scan-local.sh
#   ./scripts/security-scan-local.sh
# =============================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

print_header() {
    echo ""
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=============================================${NC}"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

# =============================================================
# 1. SECRET SCANNING (using git-secrets or grep-based check)
# =============================================================
print_header "1. Secret Scanning (Pattern-based)"

# Common secret patterns to search for
SECRET_PATTERNS=(
    "AKIA[0-9A-Z]{16}"           # AWS Access Key
    "password\s*=\s*['\"].*['\"]" # Hardcoded passwords
    "api[_-]?key\s*=\s*['\"].*['\"]" # API keys
    "secret[_-]?key\s*=\s*['\"].*['\"]" # Secret keys
    "private[_-]?key"            # Private keys
    "BEGIN RSA PRIVATE KEY"      # RSA keys
    "BEGIN OPENSSH PRIVATE KEY"  # SSH keys
)

SECRETS_FOUND=false
for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -rniE "$pattern" --include="*.py" --include="*.yml" --include="*.yaml" --include="*.json" --include="*.env" --include="*.cfg" --include="*.ini" . 2>/dev/null | grep -v ".git/" | grep -v "node_modules/" | grep -v ".venv/"; then
        SECRETS_FOUND=true
    fi
done

if [ "$SECRETS_FOUND" = true ]; then
    print_fail "Potential secrets detected in source code!"
else
    print_pass "No obvious secrets found in source code"
fi

# =============================================================
# 2. SCA - Dependency Vulnerability Scanning
# =============================================================
print_header "2. SCA - Dependency Scanning (Safety)"

if command -v safety &> /dev/null; then
    if [ -f "requirements.txt" ]; then
        if safety check -r requirements.txt --output text 2>/dev/null; then
            print_pass "No known vulnerabilities in dependencies"
        else
            print_warn "Vulnerabilities found in dependencies (review above)"
        fi
    else
        print_warn "No requirements.txt found, skipping"
    fi
else
    print_warn "Safety not installed. Install with: pip install safety"
fi

# =============================================================
# 3. SAST - Static Application Security Testing
# =============================================================
print_header "3. SAST - Static Code Analysis (Bandit)"

if command -v bandit &> /dev/null; then
    if bandit -r . -f screen -ll -ii -x "./.venv,./venv,./tests,./scripts" 2>/dev/null; then
        print_pass "No high-severity issues found by Bandit"
    else
        print_warn "Security issues detected by Bandit (review above)"
    fi
else
    print_warn "Bandit not installed. Install with: pip install bandit"
fi

# =============================================================
# 4. DOCKERFILE SECURITY CHECK
# =============================================================
print_header "4. Dockerfile Security Best Practices"

if [ -f "Dockerfile" ]; then
    # Check for running as root
    if grep -q "USER " Dockerfile; then
        print_pass "Dockerfile specifies a non-root USER"
    else
        print_warn "Dockerfile does not specify USER (runs as root by default)"
    fi

    # Check for pinned base image
    if grep -qE "FROM.*:latest" Dockerfile; then
        print_warn "Dockerfile uses ':latest' tag - consider pinning a specific version"
    else
        print_pass "Dockerfile uses a pinned base image version"
    fi

    # Check for HEALTHCHECK
    if grep -q "HEALTHCHECK" Dockerfile; then
        print_pass "Dockerfile includes HEALTHCHECK"
    else
        print_warn "Dockerfile does not include HEALTHCHECK instruction"
    fi

    # Check for --no-cache-dir in pip install
    if grep -q "\-\-no-cache-dir" Dockerfile; then
        print_pass "pip install uses --no-cache-dir (reduces image size)"
    else
        print_warn "Consider adding --no-cache-dir to pip install"
    fi
else
    print_warn "No Dockerfile found, skipping Docker checks"
fi

# =============================================================
# 5. CONTAINER IMAGE SCANNING (if Docker is available)
# =============================================================
print_header "5. Container Image Scanning (Trivy)"

if command -v docker &> /dev/null; then
    if command -v trivy &> /dev/null; then
        IMAGE_NAME="local-security-test:latest"
        echo "Building Docker image for scanning..."
        if docker build -t "$IMAGE_NAME" . 2>/dev/null; then
            if trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed "$IMAGE_NAME" 2>/dev/null; then
                print_pass "No HIGH/CRITICAL vulnerabilities in container image"
            else
                print_fail "Vulnerabilities found in container image"
            fi
            docker rmi "$IMAGE_NAME" > /dev/null 2>&1 || true
        else
            print_warn "Docker build failed, skipping image scan"
        fi
    else
        print_warn "Trivy not installed. See: https://aquasecurity.github.io/trivy/"
    fi
else
    print_warn "Docker not available, skipping container scan"
fi

# =============================================================
# SUMMARY
# =============================================================
print_header "Security Scan Summary"

echo -e "  ${GREEN}Passed : ${PASS_COUNT}${NC}"
echo -e "  ${YELLOW}Warnings: ${WARN_COUNT}${NC}"
echo -e "  ${RED}Failed : ${FAIL_COUNT}${NC}"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "${RED}⚠️  Security issues detected! Please fix before pushing.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All critical security checks passed!${NC}"
    exit 0
fi
