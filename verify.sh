#!/usr/bin/env bash
set -e

# Dabira Agent Verification Script
# Verifies installation integrity and checksum

REPO="CentaPoint/dabira-server-agent"
BINARY_NAME="dabira-agent"

# Colors
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1" >&2; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}Dabira Agent Verification${NC}                          ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if dabira-agent is installed
if ! command -v $BINARY_NAME &> /dev/null; then
    print_error "Dabira Agent is not installed"
    echo ""
    echo "Install it with:"
    echo "  curl -fsSL https://raw.githubusercontent.com/CentaPoint/dabira-agent-install/main/install.sh | bash"
    exit 1
fi

print_success "Dabira Agent is installed"

# Get installed binary path
BINARY_PATH=$(which $BINARY_NAME)
print_info "Binary location: ${BOLD}${BINARY_PATH}${NC}"

# Get installed version
INSTALLED_VERSION=$($BINARY_NAME --version 2>/dev/null | head -n1 | awk '{print $NF}' || echo "unknown")
print_info "Installed version: ${BOLD}${INSTALLED_VERSION}${NC}"

# Get latest version from GitHub
print_info "Fetching latest version from GitHub..."
LATEST_VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' || echo "unknown")

if [ "$LATEST_VERSION" != "unknown" ]; then
    print_info "Latest version: ${BOLD}${LATEST_VERSION}${NC}"
    
    # Compare versions
    if [ "$INSTALLED_VERSION" = "${LATEST_VERSION#v}" ]; then
        print_success "You have the latest version"
    else
        print_warning "A newer version is available: ${LATEST_VERSION}"
        echo ""
        echo "Update with:"
        echo "  curl -fsSL https://raw.githubusercontent.com/CentaPoint/dabira-agent-install/main/install.sh | bash"
    fi
else
    print_warning "Could not fetch latest version from GitHub"
fi

echo ""
print_info "Verifying binary integrity..."

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
    linux) OS_TYPE="linux" ;;
    darwin) OS_TYPE="macos" ;;
    *)
        print_warning "Unknown OS: $OS, skipping checksum verification"
        exit 0
        ;;
esac

case "$ARCH" in
    x86_64|amd64) ARCH_TYPE="x86_64" ;;
    aarch64|arm64) ARCH_TYPE="aarch64" ;;
    *)
        print_warning "Unknown architecture: $ARCH, skipping checksum verification"
        exit 0
        ;;
esac

# Construct asset name
if [ "$OS_TYPE" = "windows" ]; then
    ASSET_NAME="${BINARY_NAME}-${OS_TYPE}-${ARCH_TYPE}.exe"
else
    ASSET_NAME="${BINARY_NAME}-${OS_TYPE}-${ARCH_TYPE}"
fi

# Download checksum file
CHECKSUM_URL="https://github.com/${REPO}/releases/download/${LATEST_VERSION}/${ASSET_NAME}.sha256"
TEMP_CHECKSUM=$(mktemp)

if curl -fsSL "$CHECKSUM_URL" -o "$TEMP_CHECKSUM" 2>/dev/null; then
    EXPECTED_CHECKSUM=$(cat "$TEMP_CHECKSUM")
    
    # Calculate actual checksum
    if command -v sha256sum &> /dev/null; then
        ACTUAL_CHECKSUM=$(sha256sum "$BINARY_PATH" | awk '{print $1}')
    elif command -v shasum &> /dev/null; then
        ACTUAL_CHECKSUM=$(shasum -a 256 "$BINARY_PATH" | awk '{print $1}')
    else
        print_warning "No checksum utility found (sha256sum or shasum)"
        rm -f "$TEMP_CHECKSUM"
        exit 0
    fi
    
    # Compare checksums
    if [ "$EXPECTED_CHECKSUM" = "$ACTUAL_CHECKSUM" ]; then
        print_success "Checksum verified - binary is authentic"
        echo ""
        echo -e "${GREEN}Expected:${NC} ${EXPECTED_CHECKSUM}"
        echo -e "${GREEN}Actual:${NC}   ${ACTUAL_CHECKSUM}"
    else
        print_error "Checksum mismatch - binary may be corrupted or tampered"
        echo ""
        echo -e "${RED}Expected:${NC} ${EXPECTED_CHECKSUM}"
        echo -e "${RED}Actual:${NC}   ${ACTUAL_CHECKSUM}"
        echo ""
        echo "Consider reinstalling:"
        echo "  curl -fsSL https://raw.githubusercontent.com/CentaPoint/dabira-agent-install/main/install.sh | bash"
        rm -f "$TEMP_CHECKSUM"
        exit 1
    fi
    
    rm -f "$TEMP_CHECKSUM"
else
    print_warning "Could not download checksum file for verification"
fi

echo ""
print_info "Testing binary functionality..."

# Test basic commands
if $BINARY_NAME --version &> /dev/null; then
    print_success "Version command works"
else
    print_error "Version command failed"
fi

if $BINARY_NAME --help &> /dev/null; then
    print_success "Help command works"
else
    print_error "Help command failed"
fi

# Check if configured
if $BINARY_NAME config show &> /dev/null; then
    print_success "Configuration exists"
    
    # Try to check status
    if $BINARY_NAME status &> /dev/null; then
        print_success "Status check works"
    fi
else
    print_warning "Agent not configured yet"
    echo ""
    echo "Configure with:"
    echo "  dabira-agent setup"
fi

echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║  Verification Complete!                                ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
echo ""