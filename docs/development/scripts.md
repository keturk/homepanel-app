# Development Scripts

This guide covers the development utilities and scripts available in the `scripts/` directory for the Home Panel App.

## 🛠️ Overview

The Development Scripts provide automated scripts and utilities to streamline the development workflow, including compilation checks, syntax validation, and project management.

**Current Status**: All tools are fully functional and regularly maintained with comprehensive error handling and logging.

## 📁 Tool Directory

```
scripts/
├── README.md                    # Tool documentation
├── compile_check.sh            # Full compilation check
├── check_syntax_errors.sh      # Syntax error detection
├── quick_syntax_check.sh       # Fast syntax check for modified files
├── swift_lint.sh               # Swift file linter
├── run_tests.sh                # Test execution
├── open_xcode.sh               # Open project in Xcode
├── add_lockout_manager.sh      # LockoutManager addition guidance
├── add_sync_files.sh           # Sync files addition guidance
├── fix_duplicate_files.sh      # Duplicate file resolution
├── verify_project_files.sh     # Project file verification
└── quick_fixes.sh              # Quick fix suggestions
```

## 🔧 Available Tools

### Compile Check

**Script**: `compile_check.sh`

**Purpose**: Performs a complete compilation check of the project

**Usage**:
```bash
./scripts/compile_check.sh
```

**Output**:
- ✅ Build successful (exit code 0)
- ❌ Build failed (exit code 1)
- Full compilation log saved to `compile_output.log`

**Implementation**:
```bash
#!/bin/bash
# scripts/compile_check.sh

cd HomePanelApp
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build > ../scripts/compile_output.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
    exit 0
else
    echo "❌ Build failed"
    exit 1
fi
```

### Syntax Error Check

**Script**: `check_syntax_errors.sh`

**Purpose**: Extracts only syntax errors and warnings from compilation

**Usage**:
```bash
./scripts/check_syntax_errors.sh
```

**Output**:
- ✅ No syntax errors (exit code 0)
- ❌ Syntax errors found (exit code 1)
- Error details saved to `syntax_errors.log`

**Implementation**:
```bash
#!/bin/bash
# scripts/check_syntax_errors.sh

cd HomePanelApp
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build 2>&1 | grep -E "(error|warning)" > ../scripts/syntax_errors.log

if [ -s ../scripts/syntax_errors.log ]; then
    echo "❌ Syntax errors found:"
    cat ../scripts/syntax_errors.log
    exit 1
else
    echo "✅ No syntax errors"
    exit 0
fi
```

### Quick Syntax Check

**Script**: `quick_syntax_check.sh`

**Purpose**: Fast syntax check for recently modified Swift files only (much faster than full compilation)

**Usage**:
```bash
./scripts/quick_syntax_check.sh
```

**Output**:
- ✅ All modified files passed (exit code 0)
- ⚠️  Warnings found (exit code 0)
- ❌ Syntax errors found (exit code 1)
- Detailed file-by-file results

**Features**:
- Only checks git-modified and untracked files
- Uses `swiftc -typecheck` for fast validation
- Shows progress for each file
- Provides summary with error/warning counts

### Swift Lint

**Script**: `swift_lint.sh`

**Purpose**: Lint individual Swift files using swiftc for fast syntax checking

**Usage**:
```bash
./scripts/swift_lint.sh <file_path> [additional_files...]
```

**Example**:
```bash
./scripts/swift_lint.sh HomePanelApp/ViewModels/CameraViewModel.swift
./scripts/swift_lint.sh HomePanelApp/Models/*.swift
```

**Output**:
- Syntax errors and warnings for specified files
- Fast typecheck without full compilation

### Run Tests

**Script**: `run_tests.sh`

**Purpose**: Executes all unit tests using the configured simulator

**Usage**:
```bash
./scripts/run_tests.sh
```

**Output**:
- Test results with pass/fail status
- Uses xcpretty for formatted output if available
- Falls back to standard xcodebuild output

**Configuration**:
- Simulator ID: `428CFC03-D765-4FBC-AC20-38C55146A63F`
- Can be modified in the script

### Open Xcode

**Script**: `open_xcode.sh`

**Purpose**: Opens the project in Xcode

**Usage**:
```bash
./scripts/open_xcode.sh
```

**Implementation**:
```bash
#!/bin/bash
# scripts/open_xcode.sh

open HomePanelApp/HomePanelApp.xcodeproj
```

### Add File to Project

**Script**: `add_file_to_project.sh`

**Purpose**: Provides guidance for adding new Swift files to the Xcode project

**Usage**:
```bash
./scripts/add_file_to_project.sh <file_path>
```

**Example**:
```bash
./scripts/add_file_to_project.sh HomePanelApp/Models/NewModel.swift
```

**Output**:
- Instructions for adding the file to Xcode
- Target selection guidance
- Build phase recommendations

### Add LockoutManager

**Script**: `add_lockout_manager.sh`

**Purpose**: Provides guidance for adding LockoutManager to the Xcode project

**Usage**:
```bash
./scripts/add_lockout_manager.sh
```

**Output**:
- Instructions for adding LockoutManager.swift to Xcode
- Target selection guidance
- Build phase recommendations

### Add Sync Files

**Script**: `add_sync_files.sh`

**Purpose**: Provides guidance for adding sync utility files (SyncDebugUtils, ManualSyncService) to the Xcode project

**Usage**:
```bash
./scripts/add_sync_files.sh
```

**Output**:
- Instructions for adding sync utility files to Xcode
- Automatic file addition using xcodebuild
- Confirmation messages

### Verify Project Files

**Script**: `verify_project_files.sh`

**Purpose**: Verifies that all Swift files in the filesystem are properly referenced in the Xcode project

**Usage**:
```bash
./scripts/verify_project_files.sh
```

**Output**:
- List of files in filesystem vs. Xcode project
- Missing files (in filesystem but not in project)
- Orphaned references (in project but not in filesystem)
- Verification summary

**Features**:
- Scans all Swift files in HomePanelApp directory
- Excludes build artifacts and packages
- Identifies synchronization issues
- Helps maintain project integrity

### Fix Duplicate Files

**Script**: `fix_duplicate_files.sh`

**Purpose**: Identifies and helps resolve duplicate file references

**Usage**:
```bash
./scripts/fix_duplicate_files.sh
```

**Output**:
- List of duplicate files
- Resolution suggestions
- Xcode project cleanup guidance

### Quick Fixes

**Script**: `quick_fixes.sh`

**Purpose**: Suggests quick fixes for common issues

**Usage**:
```bash
./scripts/quick_fixes.sh
```

**Output**:
- Common issue suggestions
- Quick resolution steps
- Best practice recommendations

## 🔄 Development Workflow

### Pre-Commit Checks

**Recommended Workflow (Fast)**:
```bash
# 1. Quick check of modified files only (fastest)
./scripts/quick_syntax_check.sh

# 2. If successful, run tests
./scripts/run_tests.sh

# 3. If all tests pass, commit changes
git add .
git commit -m "feat: description of changes"
```

**Recommended Workflow (Thorough)**:
```bash
# 1. Full syntax check
./scripts/check_syntax_errors.sh

# 2. Run all tests
./scripts/run_tests.sh

# 3. Full compilation
./scripts/compile_check.sh

# 4. If successful, commit changes
git add .
git commit -m "feat: description of changes"
```

### Daily Development

**Start Development**:
```bash
# Open project in Xcode
./scripts/open_xcode.sh
```

**Check Changes**:
```bash
# Quick check for modified files only (recommended)
./scripts/quick_syntax_check.sh

# Full syntax check
./scripts/check_syntax_errors.sh

# Run tests
./scripts/run_tests.sh

# Full compilation if needed
./scripts/compile_check.sh
```

**Lint Specific Files**:
```bash
# Check single file
./scripts/swift_lint.sh HomePanelApp/Features/Camera/CameraViewModel.swift

# Check multiple files
./scripts/swift_lint.sh HomePanelApp/Features/Camera/*.swift
```

**Verify Project Integrity**:
```bash
# Verify all Swift files are in Xcode project
./scripts/verify_project_files.sh

# Fix duplicate file references
./scripts/fix_duplicate_files.sh
```

**Add New Files**:
```bash
# Get guidance for adding files
./scripts/add_file_to_project.sh path/to/new/file.swift
```

## 📊 Log Files

### Compilation Output

**File**: `compile_output.log`

**Content**:
- Full xcodebuild output
- Compilation warnings
- Build errors
- Linker messages

**Usage**:
```bash
# View compilation output
cat scripts/compile_output.log

# Search for specific errors
grep "error:" scripts/compile_output.log
```

### Syntax Errors

**File**: `syntax_errors.log`

**Content**:
- Filtered error messages
- Warning messages
- File locations
- Error descriptions

**Usage**:
```bash
# View syntax errors
cat scripts/syntax_errors.log

# Count errors
wc -l scripts/syntax_errors.log
```

## 🔧 Tool Configuration

### Xcode Project Settings

**Required Settings**:
- Scheme: HomePanelApp
- Destination: iPad Pro 13-inch (M4)
- Configuration: Debug
- Build Settings: Default

**Customization**:
```bash
# Edit scripts to change destination
vim scripts/compile_check.sh

# Change simulator destination
# -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Build Configuration

**Debug Build**:
- Optimization: None
- Debug Information: DWARF
- Swift Compilation: Debug

**Release Build**:
- Optimization: Speed
- Debug Information: DWARF with dSYM
- Swift Compilation: Optimize

## 🧪 Testing Integration

### Test Execution

**Run Tests**:
```bash
# Use the test runner script (recommended)
./scripts/run_tests.sh

# Or run tests manually
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' test
```

**Test Coverage**:
```bash
# Enable code coverage
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' test -enableCodeCoverage YES
```

### Continuous Integration

**GitHub Actions Integration**:
```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Compile Check
      run: ./scripts/compile_check.sh
    
    - name: Run Syntax Check
      run: ./scripts/check_syntax_errors.sh
```

## 🔍 Troubleshooting

### Common Issues

**Permission Errors**:
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

**Xcode Not Found**:
```bash
# Check Xcode installation
xcode-select -p

# Set Xcode path
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

**Simulator Issues**:
```bash
# List available simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPad Pro 13-inch (M4)"
```

### Script Debugging

**Debug Mode**:
```bash
# Enable debug output
set -x
./scripts/compile_check.sh
set +x
```

**Verbose Output**:
```bash
# Add verbose flag to xcodebuild
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build -verbose
```

## 📚 Best Practices

### Script Usage

**Regular Checks**:
- Run syntax check before committing
- Use compile check for major changes
- Check logs for detailed error information

**File Management**:
- Use add_file_to_project.sh for new files
- Run fix_duplicate_files.sh periodically
- Keep logs clean and organized

**Error Handling**:
- Always check exit codes
- Review error logs carefully
- Fix issues before proceeding

### Maintenance

**Log Rotation**:
```bash
# Rotate logs periodically
mv scripts/compile_output.log scripts/compile_output.log.old
mv scripts/syntax_errors.log scripts/syntax_errors.log.old
```

**Script Updates**:
- Keep scripts up to date
- Test changes before committing
- Document new functionality

## 🔮 Future Enhancements

### Planned Features

**Advanced Tools**:
- Automated test execution
- Performance profiling
- Memory leak detection
- Code coverage reporting

**Integration**:
- IDE integration
- CI/CD pipeline
- Automated deployment
- Quality gates

### Tool Improvements

**Enhanced Logging**:
- Structured log format
- Error categorization
- Performance metrics
- Historical tracking

**User Experience**:
- Interactive mode
- Progress indicators
- Color-coded output
- Help system

---

The Development Scripts provide essential development utilities for the Home Panel App. Use these tools regularly to maintain code quality and streamline the development workflow.
