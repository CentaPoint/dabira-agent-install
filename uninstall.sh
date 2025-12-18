#!/usr/bin/env bash
set -e

# Dabira Agent Uninstall Script

BINARY_NAME="dabira-agent"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="${HOME}/.config/dabira-agent"

# Colors
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BOLD=''
    NC=''
fi

print_warning() {
    echo "${YELLOW}⚠ Warning:${NC} $1"
}

print_success() {
    echo "${GREEN}✓${NC} $1"
}

print_error() {
    echo "${RED}✗ Error:${NC} $1" >&2
}

echo ""
echo "${RED}${BOLD}Dabira Agent Uninstaller${NC}"
echo ""

# Confirm uninstallation
echo "This will remove:"
echo "  • Binary: ${INSTALL_DIR}/${BINARY_NAME}"
echo "  • Configuration: ${CONFIG_DIR}"
echo ""

read -p "Are you sure you want to uninstall? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled"
    exit 0
fi

# Remove binary
if [ -f "${INSTALL_DIR}/${BINARY_NAME}" ]; then
    echo "Removing binary..."
    if [ -w "$INSTALL_DIR" ]; then
        rm "${INSTALL_DIR}/${BINARY_NAME}"
    else
        sudo rm "${INSTALL_DIR}/${BINARY_NAME}"
    fi
    print_success "Binary removed"
else
    print_warning "Binary not found"
fi

# Ask about configuration
echo ""
read -p "Remove configuration and data? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        print_success "Configuration removed"
    else
        print_warning "Configuration directory not found"
    fi
fi

echo ""
print_success "Uninstallation complete"
echo ""
echo "To reinstall:"
echo "  curl -fsSL https://install.dabira.com/install.sh | bash"
echo ""