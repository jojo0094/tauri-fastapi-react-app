# Building a Complete Bundled App for Windows

This document provides exact steps to build a complete, bundled Windows application from this Tauri + FastAPI + React project.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Manual Build Steps](#manual-build-steps)
4. [Automated Build Script](#automated-build-script)
5. [Build Output](#build-output)
6. [Troubleshooting](#troubleshooting)
7. [Distribution](#distribution)

## Prerequisites

Before building the Windows application, ensure you have the following software installed:

### Required Software

1. **Node.js** (v14 or later, recommended v18 LTS)
   - Download from: https://nodejs.org/
   - Verify installation: `node --version` and `npm --version`

2. **Python** (v3.12 or later)
   - Download from: https://www.python.org/downloads/
   - During installation, check "Add Python to PATH"
   - Verify installation: `python --version` or `py --version`

3. **Rust and Cargo**
   - Download from: https://rustup.rs/
   - Run the installer and follow the prompts
   - Verify installation: `rustc --version` and `cargo --version`

4. **Poetry** (Python dependency manager)
   - Install via pip: `pip install poetry`
   - Or via PowerShell (recommended):
     ```powershell
     (Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | py -
     ```
   - Verify installation: `poetry --version`

5. **Microsoft Visual Studio C++ Build Tools**
   - Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
   - Install "Desktop development with C++" workload
   - This is required for Rust to compile native dependencies

6. **WebView2 Runtime** (usually pre-installed on Windows 10/11)
   - Download if needed: https://developer.microsoft.com/en-us/microsoft-edge/webview2/

### Optional but Recommended

- **Git** for version control
- **Windows Terminal** for better command-line experience

## Environment Setup

### 1. Verify All Tools Are Installed

Open PowerShell or Command Prompt and run:

```bash
node --version
npm --version
python --version
poetry --version
rustc --version
cargo --version
```

All commands should return version numbers without errors.

### 2. Configure Environment Variables

Ensure Python and Rust are in your PATH:

```powershell
# Check if Python is in PATH
where python

# Check if Rust is in PATH
where rustc
```

If any are missing, add them to your system PATH environment variable.

## Manual Build Steps

Follow these steps exactly to build the Windows application:

### Step 1: Clone or Navigate to the Project

```bash
git clone https://github.com/jojo0094/tauri-fastapi-react-app.git
cd tauri-fastapi-react-app
```

### Step 2: Install Node.js Dependencies

```bash
npm install
```

This installs all frontend dependencies including React, Vite, TypeScript, and Tauri CLI.

### Step 3: Install Python Dependencies

```bash
poetry install
```

This creates a virtual environment and installs FastAPI, PyInstaller, and other Python dependencies.

### Step 4: Build the FastAPI Binary

```bash
poetry run python src-python/pyinstaller.py
```

This step:
- Compiles the FastAPI application into a standalone executable using PyInstaller
- Detects your system architecture (e.g., x86_64-pc-windows-msvc)
- Creates an `api.exe` file
- Moves it to `src-tauri/binaries/` with the architecture suffix (e.g., `api-x86_64-pc-windows-msvc.exe`)

**Expected Output:**
```
Building FastAPI Binary...
Running post-build steps...
Rust host info: x86_64-pc-windows-msvc
Moving files to src-tauri...
Updated api-x86_64-pc-windows-msvc.exe
Cleaning up temporary files...
Removed dist directory
Removed build directory
```

### Step 5: Build the Frontend

```bash
npm run build
```

This step:
- Compiles TypeScript to JavaScript
- Builds the React application using Vite
- Creates an optimized production build in the `dist/` directory

### Step 6: Build the Tauri Application

```bash
npm run tauri build
```

This is the final step that:
- Compiles the Rust code
- Bundles the frontend with the backend
- Creates the Windows installer and executable
- Packages everything into distributable formats

**This process may take 5-15 minutes** depending on your system.

### Step 7: Locate the Built Application

After successful build, find your application in:

```
src-tauri/target/release/
├── my-tauri-app.exe          # Standalone executable
└── bundle/
    └── nsis/
        └── my-tauri-app_0.1.0_x64-setup.exe  # Windows installer
    └── msi/
        └── my-tauri-app_0.1.0_x64_en-US.msi  # MSI installer (if enabled)
```

## Automated Build Script

For convenience, use the provided build script to automate all steps.

### Using the Build Script (bash/Git Bash)

```bash
# Make the script executable
chmod +x build-windows.sh

# Run the build script
./build-windows.sh
```

### Using the Build Script (PowerShell)

If you're using PowerShell, you can run the bash script via Git Bash or WSL, or follow the manual steps above.

The script performs all the steps automatically and provides colored output for each stage.

## Build Output

### Files Created

After a successful build, you'll have:

1. **Standalone Executable**: `src-tauri/target/release/my-tauri-app.exe`
   - Can be run directly without installation
   - Includes all dependencies
   - Size: ~15-30 MB (depending on your application)

2. **NSIS Installer**: `src-tauri/target/release/bundle/nsis/my-tauri-app_0.1.0_x64-setup.exe`
   - Professional Windows installer
   - Handles installation, shortcuts, and uninstallation
   - Recommended for distribution

3. **MSI Installer**: `src-tauri/target/release/bundle/msi/my-tauri-app_0.1.0_x64_en-US.msi`
   - Windows Installer package
   - Enterprise-friendly format
   - May require administrator privileges

### Testing the Application

To test the built application:

```bash
# Run the standalone executable
./src-tauri/target/release/my-tauri-app.exe

# Or install using the installer
./src-tauri/target/release/bundle/nsis/my-tauri-app_0.1.0_x64-setup.exe
```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "rustc is not recognized"

**Solution:** Install Rust from https://rustup.rs/ and restart your terminal.

#### Issue 2: "poetry is not recognized"

**Solution:** 
```bash
pip install poetry
# Or reinstall with official installer
```

#### Issue 3: "error: linker 'link.exe' not found"

**Solution:** Install Microsoft Visual Studio C++ Build Tools with the "Desktop development with C++" workload.

#### Issue 4: PyInstaller fails with "No module named 'X'"

**Solution:** 
```bash
poetry install
poetry run python src-python/pyinstaller.py
```

#### Issue 5: Tauri build fails with "beforeBuildCommand failed"

**Solution:** Ensure all previous steps completed successfully:
```bash
npm install
npm run build
poetry run python src-python/pyinstaller.py
```

#### Issue 6: "api.exe not found" during Tauri build

**Solution:** The FastAPI binary wasn't built. Run:
```bash
poetry run python src-python/pyinstaller.py
# Verify the file exists
ls src-tauri/binaries/
```

#### Issue 7: Application starts but API doesn't respond

**Solution:** 
- Check Windows Firewall settings
- Ensure port 8008 is not blocked
- Check the application logs in `%APPDATA%/my-tauri-app/logs/`

#### Issue 8: "npm ERR! code ELIFECYCLE"

**Solution:** Delete node_modules and reinstall:
```bash
rm -rf node_modules package-lock.json
npm install
```

### Getting More Help

If you encounter issues:

1. Check the build logs in `src-tauri/target/release/build/`
2. Enable debug mode: `npm run tauri build -- --debug`
3. Check Tauri documentation: https://tauri.app/
4. Open an issue on the GitHub repository

## Distribution

### Distributing Your Application

Choose one of the following methods:

#### Option 1: Standalone Executable (Simplest)

Distribute `my-tauri-app.exe` directly:
- No installation required
- Users just double-click to run
- Best for tech-savvy users

#### Option 2: NSIS Installer (Recommended)

Distribute `my-tauri-app_0.1.0_x64-setup.exe`:
- Professional installation experience
- Creates Start Menu shortcuts
- Handles updates elegantly
- Includes uninstaller

#### Option 3: MSI Installer (Enterprise)

Distribute `my-tauri-app_0.1.0_x64_en-US.msi`:
- Preferred in enterprise environments
- Can be deployed via Group Policy
- Supports Windows Installer features

### Code Signing (Optional but Recommended)

For professional distribution, consider code signing your application:

1. Obtain a code signing certificate
2. Configure Tauri to sign the executables
3. Update `src-tauri/tauri.conf.json`:

```json
{
  "tauri": {
    "bundle": {
      "windows": {
        "certificateThumbprint": "YOUR_CERTIFICATE_THUMBPRINT",
        "digestAlgorithm": "sha256",
        "timestampUrl": "http://timestamp.sectigo.com"
      }
    }
  }
}
```

### System Requirements for End Users

Inform your users of minimum requirements:

- **OS**: Windows 10 (version 1803 or later) or Windows 11
- **RAM**: 2 GB minimum, 4 GB recommended
- **Disk Space**: 50 MB for installation
- **WebView2**: Pre-installed on Windows 10/11 (auto-installs if missing)

## Build Configuration

### Customizing the Build

Edit `src-tauri/tauri.conf.json` to customize:

- Application name and version
- Window size and title
- Application icon
- Bundle identifier
- Additional resources

Example:

```json
{
  "package": {
    "productName": "MyAwesomeApp",
    "version": "1.0.0"
  },
  "tauri": {
    "windows": [
      {
        "title": "My Awesome App",
        "width": 1024,
        "height": 768
      }
    ]
  }
}
```

### Build Optimization

For smaller builds:

1. Enable release optimizations in `src-tauri/Cargo.toml`:
```toml
[profile.release]
opt-level = "z"     # Optimize for size
lto = true          # Enable Link Time Optimization
codegen-units = 1   # Better optimization
panic = "abort"     # Smaller binary
strip = true        # Remove debug symbols
```

2. Minimize JavaScript bundle size in production

3. Use UPX to compress the executable (optional):
```bash
upx --best --lzma src-tauri/target/release/my-tauri-app.exe
```

## Continuous Integration

For automated builds, consider setting up GitHub Actions:

```yaml
# .github/workflows/build.yml
name: Build Windows App

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - uses: actions/setup-python@v4
        with:
          python-version: '3.12'
      - uses: dtolnay/rust-toolchain@stable
      
      - name: Install dependencies
        run: |
          npm install
          pip install poetry
          poetry install
      
      - name: Build
        run: |
          poetry run python src-python/pyinstaller.py
          npm run build
          npm run tauri build
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: windows-build
          path: src-tauri/target/release/bundle/
```

## Summary

To build a complete Windows application:

```bash
# Quick build command sequence
npm install
poetry install
poetry run python src-python/pyinstaller.py
npm run build
npm run tauri build
```

Or simply use the automated script:

```bash
./build-windows.sh
```

Your distributable application will be in:
- `src-tauri/target/release/bundle/nsis/my-tauri-app_0.1.0_x64-setup.exe`

---

**Last Updated:** 2025-10-15  
**Tauri Version:** 1.x  
**Platform:** Windows 10/11 (x64)
