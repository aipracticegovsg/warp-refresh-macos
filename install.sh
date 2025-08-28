#!/bin/bash

# WARP Refresh for macOS - Installation Script
# This script automates the installation process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/Documents/warp-refresh"
SCRIPT_NAME="warp-refresh.sh"
PLIST_NAME="com.warp.refresh.plist"
LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if warp-cli is available
    if ! command -v warp-cli &> /dev/null; then
        print_error "warp-cli not found. Please install Cloudflare WARP first."
        print_status "Download from: https://developers.cloudflare.com/warp-client/get-started/macos/"
        exit 1
    fi
    
    print_success "warp-cli found"
    
    # Test warp-cli
    if ! warp-cli status &> /dev/null; then
        print_warning "warp-cli status command failed. WARP might not be properly configured."
        print_status "Please ensure WARP is installed and configured before continuing."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "warp-cli is working properly"
    fi
}

create_directories() {
    print_status "Creating directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$LAUNCHAGENTS_DIR"
    
    print_success "Directories created"
}

install_script() {
    print_status "Installing warp-refresh script..."
    
    # Copy the script to the install directory
    if [[ -f "$SCRIPT_NAME" ]]; then
        cp "$SCRIPT_NAME" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
        print_success "Script installed to $INSTALL_DIR/$SCRIPT_NAME"
    else
        print_error "Script file $SCRIPT_NAME not found in current directory"
        exit 1
    fi
}

install_plist() {
    print_status "Installing launchd plist..."
    
    if [[ -f "$PLIST_NAME" ]]; then
        # Create a temporary copy with placeholders replaced
        local temp_plist=$(mktemp)
        sed "s|SCRIPT_PATH_PLACEHOLDER|$INSTALL_DIR/$SCRIPT_NAME|g; s|WORKING_DIR_PLACEHOLDER|$INSTALL_DIR|g" "$PLIST_NAME" > "$temp_plist"
        
        # Copy to LaunchAgents directory
        cp "$temp_plist" "$LAUNCHAGENTS_DIR/$PLIST_NAME"
        rm "$temp_plist"
        
        print_success "Plist installed to $LAUNCHAGENTS_DIR/$PLIST_NAME"
    else
        print_error "Plist file $PLIST_NAME not found in current directory"
        exit 1
    fi
}

load_service() {
    print_status "Loading the scheduled service..."
    
    # Unload first if already loaded (ignore errors)
    launchctl unload "$LAUNCHAGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
    
    # Load the service
    if launchctl load "$LAUNCHAGENTS_DIR/$PLIST_NAME"; then
        print_success "Service loaded successfully"
    else
        print_error "Failed to load service"
        exit 1
    fi
}

verify_installation() {
    print_status "Verifying installation..."
    
    # Check if service is loaded
    if launchctl list | grep -q "com.warp.refresh"; then
        print_success "Service is loaded and running"
    else
        print_warning "Service doesn't appear to be loaded"
    fi
    
    # Test the script manually
    print_status "Testing script execution..."
    cd "$INSTALL_DIR"
    if ./"$SCRIPT_NAME"; then
        print_success "Script executed successfully"
        
        # Check if log file was created
        if [[ -f "$INSTALL_DIR/warp-refresh.log" ]]; then
            print_success "Log file created"
            print_status "Recent log entries:"
            tail -n 3 "$INSTALL_DIR/warp-refresh.log" | sed 's/^/  /'
        fi
    else
        print_error "Script execution failed"
        exit 1
    fi
}

show_usage_info() {
    echo
    print_success "Installation completed successfully!"
    echo
    echo "The WARP refresh script is now installed and will run every hour."
    echo
    echo "Useful commands:"
    echo "  View logs:           tail -f $INSTALL_DIR/warp-refresh.log"
    echo "  Stop service:        launchctl unload $LAUNCHAGENTS_DIR/$PLIST_NAME"
    echo "  Start service:       launchctl load $LAUNCHAGENTS_DIR/$PLIST_NAME"
    echo "  Check service:       launchctl list | grep com.warp.refresh"
    echo "  Run manually:        cd $INSTALL_DIR && ./warp-refresh.sh"
    echo
    echo "For more information, see the README.md file."
}

main() {
    echo "WARP Refresh for macOS - Installation Script"
    echo "============================================="
    echo
    
    check_prerequisites
    create_directories
    install_script
    install_plist
    load_service
    verify_installation
    show_usage_info
}

# Run main function
main "$@"
