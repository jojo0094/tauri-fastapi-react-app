#!/bin/bash

################################################################################
# Windows Build Script for Tauri + FastAPI + React Application
# 
# This script automates the complete build process for creating a bundled
# Windows application.
#
# Usage: ./build-windows.sh [options]
#
# Options:
#   --clean        Clean build artifacts before building
#   --skip-deps    Skip dependency installation
#   --debug        Build in debug mode (faster but larger)
#   --help         Show this help message
#
# Requirements:
#   - Node.js (v14+)
#   - Python (v3.12+)
#   - Rust & Cargo
#   - Poetry
#   - Git Bash or WSL (for Windows)
#
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
SKIP_DEPS=false
CLEAN_BUILD=false
DEBUG_MODE=false
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BOLD}${CYAN}================================${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${CYAN}================================${NC}\n"
}

print_step() {
    echo -e "${BLUE}▶${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local all_good=true
    
    # Check Node.js
    if command_exists node; then
        local node_version=$(node --version)
        print_success "Node.js installed: $node_version"
    else
        print_error "Node.js is not installed"
        print_info "Download from: https://nodejs.org/"
        all_good=false
    fi
    
    # Check npm
    if command_exists npm; then
        local npm_version=$(npm --version)
        print_success "npm installed: v$npm_version"
    else
        print_error "npm is not installed"
        all_good=false
    fi
    
    # Check Python
    if command_exists python || command_exists python3; then
        local python_cmd=$(command_exists python && echo "python" || echo "python3")
        local python_version=$($python_cmd --version 2>&1)
        print_success "Python installed: $python_version"
    else
        print_error "Python is not installed"
        print_info "Download from: https://www.python.org/"
        all_good=false
    fi
    
    # Check Poetry
    if command_exists poetry; then
        local poetry_version=$(poetry --version 2>&1)
        print_success "Poetry installed: $poetry_version"
    else
        print_error "Poetry is not installed"
        print_info "Install with: pip install poetry"
        all_good=false
    fi
    
    # Check Rust
    if command_exists rustc; then
        local rust_version=$(rustc --version)
        print_success "Rust installed: $rust_version"
    else
        print_error "Rust is not installed"
        print_info "Download from: https://rustup.rs/"
        all_good=false
    fi
    
    # Check Cargo
    if command_exists cargo; then
        local cargo_version=$(cargo --version)
        print_success "Cargo installed: $cargo_version"
    else
        print_error "Cargo is not installed"
        all_good=false
    fi
    
    if [ "$all_good" = false ]; then
        print_error "\nSome prerequisites are missing. Please install them and try again."
        print_info "See BUILD_WINDOWS.md for detailed installation instructions."
        exit 1
    fi
    
    print_success "\nAll prerequisites are installed!"
}

# Function to clean build artifacts
clean_build_artifacts() {
    print_header "Cleaning Build Artifacts"
    
    print_step "Removing old build files..."
    
    # Clean Node.js build artifacts
    if [ -d "dist" ]; then
        rm -rf dist
        print_success "Removed dist directory"
    fi
    
    # Clean Python build artifacts
    if [ -d "build" ]; then
        rm -rf build
        print_success "Removed build directory"
    fi
    
    if [ -f "api.spec" ]; then
        rm -f api.spec
        print_success "Removed api.spec file"
    fi
    
    # Clean Tauri build artifacts
    if [ -d "src-tauri/target" ]; then
        rm -rf src-tauri/target
        print_success "Removed src-tauri/target directory"
    fi
    
    # Clean binaries
    if [ -d "src-tauri/binaries" ]; then
        rm -rf src-tauri/binaries
        print_success "Removed src-tauri/binaries directory"
    fi
    
    print_success "Build artifacts cleaned!"
}

# Function to install Node.js dependencies
install_node_dependencies() {
    print_header "Installing Node.js Dependencies"
    
    print_step "Running npm install..."
    
    if npm install; then
        print_success "Node.js dependencies installed successfully!"
    else
        print_error "Failed to install Node.js dependencies"
        exit 1
    fi
}

# Function to install Python dependencies
install_python_dependencies() {
    print_header "Installing Python Dependencies"
    
    print_step "Running poetry install..."
    
    if poetry install; then
        print_success "Python dependencies installed successfully!"
    else
        print_error "Failed to install Python dependencies"
        exit 1
    fi
}

# Function to build FastAPI binary
build_fastapi_binary() {
    print_header "Building FastAPI Binary"
    
    print_step "Compiling FastAPI application with PyInstaller..."
    print_info "This may take a few minutes..."
    
    if poetry run python src-python/pyinstaller.py; then
        print_success "FastAPI binary built successfully!"
        
        # Verify the binary was created
        if [ -d "src-tauri/binaries" ] && [ -n "$(ls -A src-tauri/binaries 2>/dev/null)" ]; then
            print_success "Binary found in src-tauri/binaries/"
            ls -lh src-tauri/binaries/
        else
            print_error "Binary was not created in src-tauri/binaries/"
            exit 1
        fi
    else
        print_error "Failed to build FastAPI binary"
        exit 1
    fi
}

# Function to build frontend
build_frontend() {
    print_header "Building Frontend"
    
    print_step "Compiling TypeScript and building React app with Vite..."
    
    if npm run build; then
        print_success "Frontend built successfully!"
        
        # Verify dist directory was created
        if [ -d "dist" ]; then
            local dist_size=$(du -sh dist | cut -f1)
            print_success "Build output in dist/ (Size: $dist_size)"
        else
            print_error "dist directory was not created"
            exit 1
        fi
    else
        print_error "Failed to build frontend"
        exit 1
    fi
}

# Function to build Tauri application
build_tauri_app() {
    print_header "Building Tauri Application"
    
    if [ "$DEBUG_MODE" = true ]; then
        print_step "Building in DEBUG mode..."
        print_warning "Debug builds are faster but larger in size"
        
        if npm run tauri build -- --debug; then
            print_success "Tauri application built successfully (DEBUG)!"
        else
            print_error "Failed to build Tauri application"
            exit 1
        fi
    else
        print_step "Building in RELEASE mode..."
        print_info "This may take 5-15 minutes depending on your system..."
        print_info "Go grab a coffee ☕"
        
        if npm run tauri build; then
            print_success "Tauri application built successfully!"
        else
            print_error "Failed to build Tauri application"
            exit 1
        fi
    fi
}

# Function to display build results
show_build_results() {
    print_header "Build Complete!"
    
    echo -e "${GREEN}${BOLD}Your Windows application has been built successfully!${NC}\n"
    
    print_info "Build artifacts location:"
    echo ""
    
    local release_dir="src-tauri/target/release"
    if [ "$DEBUG_MODE" = true ]; then
        release_dir="src-tauri/target/debug"
    fi
    
    # Check for executable
    if [ -f "$release_dir/my-tauri-app.exe" ]; then
        local exe_size=$(du -h "$release_dir/my-tauri-app.exe" | cut -f1)
        echo -e "  ${CYAN}▸${NC} Standalone Executable:"
        echo -e "    ${BOLD}$release_dir/my-tauri-app.exe${NC}"
        echo -e "    Size: $exe_size"
        echo ""
    fi
    
    # Check for NSIS installer
    if [ -f "$release_dir/bundle/nsis/"*"-setup.exe" ]; then
        local installer_path=$(ls "$release_dir/bundle/nsis/"*"-setup.exe" 2>/dev/null | head -1)
        local installer_size=$(du -h "$installer_path" | cut -f1)
        echo -e "  ${CYAN}▸${NC} NSIS Installer (Recommended):"
        echo -e "    ${BOLD}$installer_path${NC}"
        echo -e "    Size: $installer_size"
        echo ""
    fi
    
    # Check for MSI installer
    if [ -f "$release_dir/bundle/msi/"*".msi" ]; then
        local msi_path=$(ls "$release_dir/bundle/msi/"*".msi" 2>/dev/null | head -1)
        local msi_size=$(du -h "$msi_path" | cut -f1)
        echo -e "  ${CYAN}▸${NC} MSI Installer:"
        echo -e "    ${BOLD}$msi_path${NC}"
        echo -e "    Size: $msi_size"
        echo ""
    fi
    
    print_info "To test the application:"
    echo -e "  ${YELLOW}$release_dir/my-tauri-app.exe${NC}"
    echo ""
    
    print_info "To distribute the application, use the installer:"
    if [ -f "$release_dir/bundle/nsis/"*"-setup.exe" ]; then
        local installer=$(ls "$release_dir/bundle/nsis/"*"-setup.exe" 2>/dev/null | head -1)
        echo -e "  ${YELLOW}$installer${NC}"
    fi
    echo ""
    
    print_success "Build process completed successfully!"
}

# Function to show usage
show_usage() {
    cat << EOF
${BOLD}Windows Build Script for Tauri + FastAPI + React Application${NC}

${BOLD}Usage:${NC}
  ./build-windows.sh [options]

${BOLD}Options:${NC}
  --clean        Clean build artifacts before building
  --skip-deps    Skip dependency installation
  --debug        Build in debug mode (faster but larger)
  --help         Show this help message

${BOLD}Examples:${NC}
  ./build-windows.sh                    # Standard build
  ./build-windows.sh --clean            # Clean build from scratch
  ./build-windows.sh --debug            # Quick debug build
  ./build-windows.sh --clean --debug    # Clean debug build

${BOLD}Requirements:${NC}
  - Node.js (v14+)
  - Python (v3.12+)
  - Rust & Cargo
  - Poetry
  - Git Bash or WSL (for Windows)

For detailed instructions, see BUILD_WINDOWS.md

EOF
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Print banner
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Tauri + FastAPI + React - Windows Build Script         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Start build process
    print_info "Starting build process..."
    print_info "Project directory: $PROJECT_ROOT"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Clean if requested
    if [ "$CLEAN_BUILD" = true ]; then
        clean_build_artifacts
    fi
    
    # Install dependencies
    if [ "$SKIP_DEPS" = false ]; then
        install_node_dependencies
        install_python_dependencies
    else
        print_warning "Skipping dependency installation (--skip-deps flag)"
    fi
    
    # Build FastAPI binary
    build_fastapi_binary
    
    # Build frontend
    build_frontend
    
    # Build Tauri application
    build_tauri_app
    
    # Show results
    show_build_results
    
    print_info "For distribution and troubleshooting guide, see BUILD_WINDOWS.md"
}

# Run main function
main "$@"
