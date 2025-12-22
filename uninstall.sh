#!/usr/bin/env bash
set -e

# Dabira Agent Uninstall Script
# Removes the Dabira Agent binary and optionally configuration data

BINARY_NAME="dabira-agent"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="${HOME}/.config/dabira-agent"
CACHE_DIR="${HOME}/.cache/dabira-agent"
DATA_DIR="${HOME}/.local/share/dabira-agent"

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

print_banner() {
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}Dabira Agent Uninstaller${NC}                          ${RED}║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Parse arguments
FORCE=false
KEEP_CONFIG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        --keep-config)
            KEEP_CONFIG=true
            shift
            ;;
        -h|--help)
            echo "Usage: uninstall.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --force        Skip confirmation prompts"
            echo "  --keep-config      Keep configuration and data files"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Example:"
            echo "  bash uninstall.sh --force"
            echo "  curl -fsSL https://raw.githubusercontent.com/CentaPoint/dabira-agent-install/main/uninstall.sh | bash -s -- --force"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_banner

# Check if Dabira Agent is installed
if ! command -v $BINARY_NAME &> /dev/null; then
    print_warning "Dabira Agent is not installed"
    echo ""
    echo "The binary was not found in your PATH."
    echo "If you installed it to a custom location, please remove it manually."
    exit 0
fi

BINARY_PATH=$(which $BINARY_NAME)
print_info "Found installation at: ${BOLD}${BINARY_PATH}${NC}"

# Get version info
INSTALLED_VERSION=$($BINARY_NAME --version 2>/dev/null | head -n1 || echo "unknown")
print_info "Version: ${BOLD}${INSTALLED_VERSION}${NC}"

echo ""
echo -e "${YELLOW}${BOLD}This will remove:${NC}"
echo "  ${RED}•${NC} Binary: ${BINARY_PATH}"

if [ -d "$CONFIG_DIR" ] && [ "$KEEP_CONFIG" = false ]; then
    echo "  ${RED}•${NC} Configuration: ${CONFIG_DIR}"
fi

if [ -d "$CACHE_DIR" ] && [ "$KEEP_CONFIG" = false ]; then
    echo "  ${RED}•${NC} Cache: ${CACHE_DIR}"
fi

if [ -d "$DATA_DIR" ] && [ "$KEEP_CONFIG" = false ]; then
    echo "  ${RED}•${NC} Data: ${DATA_DIR}"
fi

# Check for keyring credentials
KEYRING_WARNING=false
case "$(uname -s)" in
    Darwin)
        if security find-generic-password -s "dabira-agent" &> /dev/null; then
            KEYRING_WARNING=true
            echo "  ${RED}•${NC} Keychain credentials (macOS Keychain)"
        fi
        ;;
    Linux)
        KEYRING_WARNING=true
        echo "  ${YELLOW}•${NC} Keyring credentials (if stored)"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        KEYRING_WARNING=true
        echo "  ${YELLOW}•${NC} Credential Manager entries (Windows)"
        ;;
esac

echo ""

# Confirmation prompt
if [ "$FORCE" = false ]; then
    echo -e "${YELLOW}${BOLD}Are you sure you want to uninstall Dabira Agent?${NC}"
    read -p "Type 'yes' to confirm: " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Uninstallation cancelled"
        exit 0
    fi
    
    # Double confirmation if removing config
    if [ "$KEEP_CONFIG" = false ] && ([ -d "$CONFIG_DIR" ] || [ -d "$DATA_DIR" ]); then
        echo -e "${RED}${BOLD}This will permanently delete all configuration and data.${NC}"
        echo "This action cannot be undone."
        echo ""
        read -p "Type 'DELETE' to confirm: " -r
        echo ""
        
        if [[ $REPLY != "DELETE" ]]; then
            print_info "Configuration will be preserved"
            KEEP_CONFIG=true
        fi
    fi
fi

echo ""
print_info "Starting uninstallation..."
echo ""

# Stop any running daemon
if $BINARY_NAME status &> /dev/null; then
    print_info "Stopping agent daemon..."
    $BINARY_NAME stop &> /dev/null || true
    sleep 2
    print_success "Daemon stopped"
fi

# Remove binary
print_info "Removing binary..."

if [ -w "$(dirname "$BINARY_PATH")" ]; then
    rm -f "$BINARY_PATH"
else
    print_info "Requesting sudo permission to remove binary..."
    sudo rm -f "$BINARY_PATH"
fi

if [ ! -f "$BINARY_PATH" ]; then
    print_success "Binary removed"
else
    print_error "Failed to remove binary"
fi

# Remove configuration and data
if [ "$KEEP_CONFIG" = false ]; then
    if [ -d "$CONFIG_DIR" ]; then
        print_info "Removing configuration..."
        rm -rf "$CONFIG_DIR"
        print_success "Configuration removed"
    fi
    
    if [ -d "$CACHE_DIR" ]; then
        print_info "Removing cache..."
        rm -rf "$CACHE_DIR"
        print_success "Cache removed"
    fi
    
    if [ -d "$DATA_DIR" ]; then
        print_info "Removing data..."
        rm -rf "$DATA_DIR"
        print_success "Data removed"
    fi
    
    # Attempt to remove keyring credentials
    if [ "$KEYRING_WARNING" = true ]; then
        print_info "Attempting to remove keyring credentials..."
        
        case "$(uname -s)" in
            Darwin)
                # macOS Keychain
                security delete-generic-password -s "dabira-agent" 2>/dev/null && \
                    print_success "Keychain credentials removed" || \
                    print_warning "Could not remove keychain credentials (may not exist)"
                ;;
            Linux)
                # Linux secret-tool
                if command -v secret-tool &> /dev/null; then
                    secret-tool clear service dabira-agent 2>/dev/null && \
                        print_success "Keyring credentials removed" || \
                        print_warning "Could not remove keyring credentials (may not exist)"
                else
                    print_warning "secret-tool not found, cannot remove keyring credentials automatically"
                fi
                ;;
            *)
                print_warning "Keyring credentials may need to be removed manually"
                ;;
        esac
    fi
else
    print_info "Configuration and data preserved (use without --keep-config to remove)"
fi

# Verify uninstallation
echo ""
print_info "Verifying uninstallation..."

if command -v $BINARY_NAME &> /dev/null; then
    print_error "Binary still found in PATH"
    echo ""
    echo "You may need to restart your terminal or manually remove:"
    echo "  $(which $BINARY_NAME)"
else
    print_success "Binary successfully removed from PATH"
fi

# Final summary
echo ""
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║  Uninstallation Complete!                              ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$KEEP_CONFIG" = true ]; then
    echo -e "${YELLOW}Configuration preserved at:${NC}"
    [ -d "$CONFIG_DIR" ] && echo "  • $CONFIG_DIR"
    [ -d "$DATA_DIR" ] && echo "  • $DATA_DIR"
    echo ""
    echo "To remove configuration:"
    echo "  rm -rf $CONFIG_DIR $DATA_DIR"
    echo ""
fi

echo "To reinstall Dabira Agent:"
echo "  curl -fsSL https://raw.githubusercontent.com/CentaPoint/dabira-agent-install/main/install.sh | bash"
echo ""

print_info "Thank you for using Dabira Agent!"
echo ""