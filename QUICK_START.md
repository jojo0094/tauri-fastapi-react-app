# Quick Start Guide - Building for Windows

This is a condensed guide for experienced developers. For detailed instructions, see [BUILD_WINDOWS.md](BUILD_WINDOWS.md).

## Prerequisites

Install the following:
- Node.js 14+ (https://nodejs.org/)
- Python 3.12+ (https://www.python.org/)
- Rust (https://rustup.rs/)
- Poetry: `pip install poetry`
- Visual Studio C++ Build Tools

## Build Commands

### Option 1: Automated Build (Recommended)

#### Using Bash (Git Bash/WSL):
```bash
./build-windows.sh
```

#### Using PowerShell:
```powershell
.\build-windows.ps1
```

### Option 2: Manual Build

```bash
# 1. Install dependencies
npm install
poetry install

# 2. Build FastAPI binary
poetry run python src-python/pyinstaller.py

# 3. Build frontend
npm run build

# 4. Build Tauri application
npm run tauri build
```

## Output Location

Your built application will be in:
```
src-tauri/target/release/bundle/nsis/my-tauri-app_0.1.0_x64-setup.exe
```

## Build Script Options

### Bash:
```bash
./build-windows.sh --clean          # Clean build from scratch
./build-windows.sh --debug          # Faster debug build
./build-windows.sh --skip-deps      # Skip dependency installation
```

### PowerShell:
```powershell
.\build-windows.ps1 -Clean          # Clean build from scratch
.\build-windows.ps1 -Debug          # Faster debug build
.\build-windows.ps1 -SkipDeps       # Skip dependency installation
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `rustc is not recognized` | Install Rust from https://rustup.rs/ |
| `poetry is not recognized` | Run `pip install poetry` |
| `linker 'link.exe' not found` | Install Visual Studio C++ Build Tools |
| `api.exe not found` | Run `poetry run python src-python/pyinstaller.py` |

## Development vs Production

- **Development**: `npm run tauri dev` (hot reload enabled)
- **Production**: Use build scripts above (optimized bundle)

## Verification

Test your build:
```bash
./src-tauri/target/release/my-tauri-app.exe
```

## Distribution

Share the installer with users:
```
src-tauri/target/release/bundle/nsis/my-tauri-app_0.1.0_x64-setup.exe
```

For more details, see [BUILD_WINDOWS.md](BUILD_WINDOWS.md).
