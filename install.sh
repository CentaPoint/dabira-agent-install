#!/usr/bin/env bash
set -e

REPO="CentaPoint/dabira-server-agent"
BINARY_NAME="dabira-agent"
INSTALL_DIR="/usr/local/bin"
GITHUB_API="https://api.github.com"
GITHUB_DOWNLOAD="https://github.com"

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

if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
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

print_banner() {
    echo ""
    echo  -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo  -e "${CYAN}║${NC}  ${BOLD}Dabira Agent Installer${NC}                             ${CYAN}║${NC}"
    echo  -e "${CYAN}║${NC}  Secure database proxy for AI-powered analytics   ${CYAN}║${NC}"
    echo  -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() { echo "${GREEN}✓${NC} $1"; }
print_error() { echo "${RED}✗ Error:${NC} $1" >&2; }
print_warning() { echo "${YELLOW}⚠ Warning:${NC} $1"; }
print_info() { echo  -e "${CYAN}ℹ${NC} $1"; }

detect_platform() {
    local os arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)
    
    case "$os" in
        linux) OS_TYPE="linux" ;;
        darwin) OS_TYPE="macos" ;;
        mingw*|msys*|cygwin*) OS_TYPE="windows" ;;
        *)
            print_error "Unsupported OS: $os"
            exit 1
            ;;
    esac
    
    case "$arch" in
        x86_64|amd64) ARCH_TYPE="x86_64" ;;
        aarch64|arm64) ARCH_TYPE="aarch64" ;;
        *)
            print_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    if [ "$OS_TYPE" = "windows" ]; then
        DOWNLOAD_FILE="${BINARY_NAME}-${OS_TYPE}-${ARCH_TYPE}.exe"
    else
        DOWNLOAD_FILE="${BINARY_NAME}-${OS_TYPE}-${ARCH_TYPE}"
    fi
    
    print_info "Detected platform: ${BOLD}${OS_TYPE} ${ARCH_TYPE}${NC}"
}

check_requirements() {
    local missing_tools=()
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if ! command -v shasum &> /dev/null && ! command -v sha256sum &> /dev/null; then
        missing_tools+=("shasum or sha256sum")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
}

get_latest_version() {
    print_info "Fetching latest version..."
    
    local api_url="${GITHUB_API}/repos/${REPO}/releases/latest"
    local response http_code
    
    # Get response with HTTP status code
    response=$(curl -fsSL -w "\n%{http_code}" "$api_url" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | head -n-1)
    
    if [ "$http_code" != "200" ]; then
        print_error "Failed to fetch release information (HTTP $http_code)"
        if [ "$http_code" = "403" ]; then
            print_warning "GitHub API rate limit reached"
            print_info "Try again in a few minutes or specify version: --version v1.2.0"
        fi
        exit 1
    fi
    
    VERSION=$(echo "$response" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
    
    if [ -z "$VERSION" ]; then
        print_error "Could not parse version from response"
        exit 1
    fi
    
    print_success "Latest version: ${BOLD}${VERSION}${NC}"
}

check_existing() {
    if command -v "$BINARY_NAME" &> /dev/null; then
        local existing_version
        existing_version=$("$BINARY_NAME" --version 2>/dev/null | head -n1 || echo "unknown")
        
        print_warning "Already installed: ${existing_version}"
        echo ""
        read -p "Reinstall/upgrade? (y/N) " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi
}

download_binary() {
    print_info "Downloading Dabira Agent ${VERSION}..."
    
    DOWNLOAD_URL="${GITHUB_DOWNLOAD}/${REPO}/releases/download/${VERSION}/${DOWNLOAD_FILE}"
    CHECKSUM_URL="${GITHUB_DOWNLOAD}/${REPO}/releases/download/${VERSION}/${DOWNLOAD_FILE}.sha256"
    
    TEMP_DIR=$(mktemp -d)
    TEMP_FILE="${TEMP_DIR}/${BINARY_NAME}"
    CHECKSUM_FILE="${TEMP_DIR}/${DOWNLOAD_FILE}.sha256"
    
    if ! curl -fL --progress-bar "$DOWNLOAD_URL" -o "$TEMP_FILE"; then
        print_error "Failed to download binary"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    if curl -fsSL "$CHECKSUM_URL" -o "$CHECKSUM_FILE" 2>/dev/null; then
        print_info "Verifying checksum..."
        
        local expected_checksum actual_checksum
        expected_checksum=$(cat "$CHECKSUM_FILE")
        
        if command -v sha256sum &> /dev/null; then
            actual_checksum=$(sha256sum "$TEMP_FILE" | awk '{print $1}')
        else
            actual_checksum=$(shasum -a 256 "$TEMP_FILE" | awk '{print $1}')
        fi
        
        if [ "$expected_checksum" = "$actual_checksum" ]; then
            print_success "Checksum verified"
        else
            print_error "Checksum verification failed!"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    else
        print_warning "Could not download checksum, skipping verification"
    fi
    
    if [ ! -s "$TEMP_FILE" ]; then
        print_error "Downloaded file is empty"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    chmod +x "$TEMP_FILE"
    print_success "Download complete"
}

install_binary() {
    print_info "Installing to ${INSTALL_DIR}..."
    
    if [ ! -d "$INSTALL_DIR" ]; then
        sudo mkdir -p "$INSTALL_DIR"
    fi
    
    if [ -w "$INSTALL_DIR" ]; then
        mv "$TEMP_FILE" "$INSTALL_DIR/$BINARY_NAME"
    else
        print_info "Requesting sudo permission..."
        sudo mv "$TEMP_FILE" "$INSTALL_DIR/$BINARY_NAME"
        sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
    fi
    
    rm -rf "$TEMP_DIR"
    
    if [ ! -f "$INSTALL_DIR/$BINARY_NAME" ]; then
        print_error "Installation failed"
        exit 1
    fi
    
    print_success "Installation complete"
}

verify_installation() {
    print_info "Verifying installation..."
    
    if ! command -v "$BINARY_NAME" &> /dev/null; then
        print_warning "Binary installed but not in PATH"
        echo ""
        echo "Add ${INSTALL_DIR} to your PATH:"
        echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
        return 1
    fi
    
    local installed_version
    installed_version=$("$BINARY_NAME" --version 2>/dev/null | head -n1)
    
    print_success "Installed: ${BOLD}${installed_version}${NC}"
    return 0
}

print_next_steps() {
    echo ""
    echo "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
    echo "${GREEN}${BOLD}║  Installation Successful! 🎉                           ║${NC}"
    echo "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "${BOLD}Next Steps:${NC}"
    echo ""
    echo "  ${CYAN}1.${NC} Configure your agent:"
    echo "     ${BOLD}$ dabira-agent setup${NC}"
    echo ""
    echo "  ${CYAN}2.${NC} Check agent status:"
    echo "     ${BOLD}$ dabira-agent status${NC}"
    echo ""
    echo "  ${CYAN}3.${NC} View available commands:"
    echo "     ${BOLD}$ dabira-agent --help${NC}"
    echo ""
}

main() {
    print_banner
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                VERSION="$2"
                shift 2
                ;;
            --help)
                echo "Usage: install.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --version VERSION    Install specific version"
                echo "  --help               Show this help"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    detect_platform
    check_requirements
    check_existing
    
    if [ -z "$VERSION" ]; then
        get_latest_version
    fi
    
    download_binary
    install_binary
    
    if verify_installation; then
        print_next_steps
    fi
}

main "$@"