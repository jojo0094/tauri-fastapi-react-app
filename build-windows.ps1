################################################################################
# Windows Build Script for Tauri + FastAPI + React Application (PowerShell)
# 
# This script automates the complete build process for creating a bundled
# Windows application using PowerShell.
#
# Usage: .\build-windows.ps1 [options]
#
# Options:
#   -Clean        Clean build artifacts before building
#   -SkipDeps     Skip dependency installation
#   -Debug        Build in debug mode (faster but larger)
#   -Help         Show this help message
#
# Requirements:
#   - Node.js (v14+)
#   - Python (v3.12+)
#   - Rust & Cargo
#   - Poetry
#
################################################################################

param(
    [switch]$Clean,
    [switch]$SkipDeps,
    [switch]$Debug,
    [switch]$Help
)

# Configuration
$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

################################################################################
# Helper Functions
################################################################################

function Write-Header {
    param([string]$Message)
    Write-Host "`n================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "================================`n" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "▶ $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    $allGood = $true
    
    # Check Node.js
    if (Test-CommandExists "node") {
        $nodeVersion = node --version
        Write-Success "Node.js installed: $nodeVersion"
    } else {
        Write-Error "Node.js is not installed"
        Write-Info "Download from: https://nodejs.org/"
        $allGood = $false
    }
    
    # Check npm
    if (Test-CommandExists "npm") {
        $npmVersion = npm --version
        Write-Success "npm installed: v$npmVersion"
    } else {
        Write-Error "npm is not installed"
        $allGood = $false
    }
    
    # Check Python
    if (Test-CommandExists "python") {
        $pythonVersion = python --version
        Write-Success "Python installed: $pythonVersion"
    } else {
        Write-Error "Python is not installed"
        Write-Info "Download from: https://www.python.org/"
        $allGood = $false
    }
    
    # Check Poetry
    if (Test-CommandExists "poetry") {
        $poetryVersion = poetry --version
        Write-Success "Poetry installed: $poetryVersion"
    } else {
        Write-Error "Poetry is not installed"
        Write-Info "Install with: pip install poetry"
        $allGood = $false
    }
    
    # Check Rust
    if (Test-CommandExists "rustc") {
        $rustVersion = rustc --version
        Write-Success "Rust installed: $rustVersion"
    } else {
        Write-Error "Rust is not installed"
        Write-Info "Download from: https://rustup.rs/"
        $allGood = $false
    }
    
    # Check Cargo
    if (Test-CommandExists "cargo") {
        $cargoVersion = cargo --version
        Write-Success "Cargo installed: $cargoVersion"
    } else {
        Write-Error "Cargo is not installed"
        $allGood = $false
    }
    
    if (-not $allGood) {
        Write-Error "`nSome prerequisites are missing. Please install them and try again."
        Write-Info "See BUILD_WINDOWS.md for detailed installation instructions."
        exit 1
    }
    
    Write-Success "`nAll prerequisites are installed!"
}

function Remove-BuildArtifacts {
    Write-Header "Cleaning Build Artifacts"
    
    Write-Step "Removing old build files..."
    
    # Clean Node.js build artifacts
    if (Test-Path "dist") {
        Remove-Item -Recurse -Force "dist"
        Write-Success "Removed dist directory"
    }
    
    # Clean Python build artifacts
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
        Write-Success "Removed build directory"
    }
    
    if (Test-Path "api.spec") {
        Remove-Item -Force "api.spec"
        Write-Success "Removed api.spec file"
    }
    
    # Clean Tauri build artifacts
    if (Test-Path "src-tauri/target") {
        Remove-Item -Recurse -Force "src-tauri/target"
        Write-Success "Removed src-tauri/target directory"
    }
    
    # Clean binaries
    if (Test-Path "src-tauri/binaries") {
        Remove-Item -Recurse -Force "src-tauri/binaries"
        Write-Success "Removed src-tauri/binaries directory"
    }
    
    Write-Success "Build artifacts cleaned!"
}

function Install-NodeDependencies {
    Write-Header "Installing Node.js Dependencies"
    
    Write-Step "Running npm install..."
    
    try {
        npm install
        Write-Success "Node.js dependencies installed successfully!"
    } catch {
        Write-Error "Failed to install Node.js dependencies"
        Write-Error $_.Exception.Message
        exit 1
    }
}

function Install-PythonDependencies {
    Write-Header "Installing Python Dependencies"
    
    Write-Step "Running poetry install..."
    
    try {
        poetry install
        Write-Success "Python dependencies installed successfully!"
    } catch {
        Write-Error "Failed to install Python dependencies"
        Write-Error $_.Exception.Message
        exit 1
    }
}

function Build-FastAPIBinary {
    Write-Header "Building FastAPI Binary"
    
    Write-Step "Compiling FastAPI application with PyInstaller..."
    Write-Info "This may take a few minutes..."
    
    try {
        poetry run python src-python/pyinstaller.py
        Write-Success "FastAPI binary built successfully!"
        
        # Verify the binary was created
        if ((Test-Path "src-tauri/binaries") -and (Get-ChildItem "src-tauri/binaries" -ErrorAction SilentlyContinue)) {
            Write-Success "Binary found in src-tauri/binaries/"
            Get-ChildItem "src-tauri/binaries" | ForEach-Object {
                $size = [math]::Round($_.Length / 1MB, 2)
                Write-Host "  - $($_.Name) ($size MB)"
            }
        } else {
            Write-Error "Binary was not created in src-tauri/binaries/"
            exit 1
        }
    } catch {
        Write-Error "Failed to build FastAPI binary"
        Write-Error $_.Exception.Message
        exit 1
    }
}

function Build-Frontend {
    Write-Header "Building Frontend"
    
    Write-Step "Compiling TypeScript and building React app with Vite..."
    
    try {
        npm run build
        Write-Success "Frontend built successfully!"
        
        # Verify dist directory was created
        if (Test-Path "dist") {
            $distSize = (Get-ChildItem "dist" -Recurse | Measure-Object -Property Length -Sum).Sum
            $distSizeMB = [math]::Round($distSize / 1MB, 2)
            Write-Success "Build output in dist/ (Size: $distSizeMB MB)"
        } else {
            Write-Error "dist directory was not created"
            exit 1
        }
    } catch {
        Write-Error "Failed to build frontend"
        Write-Error $_.Exception.Message
        exit 1
    }
}

function Build-TauriApp {
    Write-Header "Building Tauri Application"
    
    try {
        if ($Debug) {
            Write-Step "Building in DEBUG mode..."
            Write-Warning "Debug builds are faster but larger in size"
            npm run tauri build -- --debug
            Write-Success "Tauri application built successfully (DEBUG)!"
        } else {
            Write-Step "Building in RELEASE mode..."
            Write-Info "This may take 5-15 minutes depending on your system..."
            Write-Info "Go grab a coffee ☕"
            npm run tauri build
            Write-Success "Tauri application built successfully!"
        }
    } catch {
        Write-Error "Failed to build Tauri application"
        Write-Error $_.Exception.Message
        exit 1
    }
}

function Show-BuildResults {
    Write-Header "Build Complete!"
    
    Write-Host "`nYour Windows application has been built successfully!`n" -ForegroundColor Green
    
    Write-Info "Build artifacts location:"
    Write-Host ""
    
    $releaseDir = if ($Debug) { "src-tauri/target/debug" } else { "src-tauri/target/release" }
    
    # Check for executable
    if (Test-Path "$releaseDir/my-tauri-app.exe") {
        $exeSize = [math]::Round((Get-Item "$releaseDir/my-tauri-app.exe").Length / 1MB, 2)
        Write-Host "  ▸ Standalone Executable:" -ForegroundColor Cyan
        Write-Host "    $releaseDir/my-tauri-app.exe"
        Write-Host "    Size: $exeSize MB"
        Write-Host ""
    }
    
    # Check for NSIS installer
    $nsisInstaller = Get-ChildItem "$releaseDir/bundle/nsis/*-setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($nsisInstaller) {
        $installerSize = [math]::Round($nsisInstaller.Length / 1MB, 2)
        Write-Host "  ▸ NSIS Installer (Recommended):" -ForegroundColor Cyan
        Write-Host "    $($nsisInstaller.FullName)"
        Write-Host "    Size: $installerSize MB"
        Write-Host ""
    }
    
    # Check for MSI installer
    $msiInstaller = Get-ChildItem "$releaseDir/bundle/msi/*.msi" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($msiInstaller) {
        $msiSize = [math]::Round($msiInstaller.Length / 1MB, 2)
        Write-Host "  ▸ MSI Installer:" -ForegroundColor Cyan
        Write-Host "    $($msiInstaller.FullName)"
        Write-Host "    Size: $msiSize MB"
        Write-Host ""
    }
    
    Write-Info "To test the application:"
    Write-Host "  $releaseDir/my-tauri-app.exe" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Info "To distribute the application, use the installer:"
    if ($nsisInstaller) {
        Write-Host "  $($nsisInstaller.FullName)" -ForegroundColor Yellow
    }
    Write-Host ""
    
    Write-Success "Build process completed successfully!"
}

function Show-Usage {
    Write-Host @"

Windows Build Script for Tauri + FastAPI + React Application

Usage:
  .\build-windows.ps1 [options]

Options:
  -Clean        Clean build artifacts before building
  -SkipDeps     Skip dependency installation
  -Debug        Build in debug mode (faster but larger)
  -Help         Show this help message

Examples:
  .\build-windows.ps1                    # Standard build
  .\build-windows.ps1 -Clean             # Clean build from scratch
  .\build-windows.ps1 -Debug             # Quick debug build
  .\build-windows.ps1 -Clean -Debug      # Clean debug build

Requirements:
  - Node.js (v14+)
  - Python (v3.12+)
  - Rust & Cargo
  - Poetry

For detailed instructions, see BUILD_WINDOWS.md

"@
}

################################################################################
# Main Script
################################################################################

function Main {
    # Show help if requested
    if ($Help) {
        Show-Usage
        exit 0
    }
    
    # Print banner
    Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Tauri + FastAPI + React - Windows Build Script         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan
    
    # Change to project root
    Set-Location $ProjectRoot
    
    # Start build process
    Write-Info "Starting build process..."
    Write-Info "Project directory: $ProjectRoot"
    Write-Host ""
    
    # Check prerequisites
    Test-Prerequisites
    
    # Clean if requested
    if ($Clean) {
        Remove-BuildArtifacts
    }
    
    # Install dependencies
    if (-not $SkipDeps) {
        Install-NodeDependencies
        Install-PythonDependencies
    } else {
        Write-Warning "Skipping dependency installation (-SkipDeps flag)"
    }
    
    # Build FastAPI binary
    Build-FastAPIBinary
    
    # Build frontend
    Build-Frontend
    
    # Build Tauri application
    Build-TauriApp
    
    # Show results
    Show-BuildResults
    
    Write-Info "For distribution and troubleshooting guide, see BUILD_WINDOWS.md"
}

# Run main function
try {
    Main
} catch {
    Write-Error "Build failed with error:"
    Write-Error $_.Exception.Message
    exit 1
}
