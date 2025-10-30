# Development Scripts

This folder contains automated scripts and utilities for the Home Panel App development workflow. These tools help catch syntax errors early, validate code changes, and ensure project consistency.

## 🎯 Quick Start

**Most commonly used tools:**

```bash
# Quick check of modified files (fastest, recommended before commits)
./scripts/quick_syntax_check.sh

# Full syntax validation (comprehensive, catches all issues)
./scripts/check_syntax_errors.sh

# Complete build with detailed reporting
./scripts/compile_check.sh
```

## 📋 Available Tools

### `quick_syntax_check.sh` ⚡ **[RECOMMENDED]**
**Fast syntax validation of recently modified Swift files.**

```bash
./scripts/quick_syntax_check.sh
```

**When to use:**
- Before committing changes
- After making code modifications
- When you want quick feedback

**What it does:**
- Finds Swift files modified since last commit
- Performs fast syntax-only checking with `swiftc`
- Reports errors and warnings immediately
- Much faster than full builds (seconds vs minutes)

**Exit codes:**
- `0`: No errors (warnings allowed)
- `1`: Syntax errors found

---

### `check_syntax_errors.sh` 🔍
**Comprehensive syntax checking with full compilation.**

```bash
./scripts/check_syntax_errors.sh
```

**When to use:**
- Before pushing to remote repository
- When quick check passes but you want thorough validation
- After resolving errors to verify fixes
- When AI assistant reports "no errors" but you see issues

**What it does:**
- Performs clean build with xcodebuild
- Extracts all errors, warnings, and notes
- Provides detailed error summaries
- Catches issues that simple syntax checking might miss

**Improvements over previous version:**
- ✅ Captures build exit codes correctly
- ✅ Detects linker and configuration errors
- ✅ Shows error counts and categorization
- ✅ Provides actionable next steps

**Exit codes:**
- `0`: Build succeeded (no errors, warnings ok)
- `1`: Build failed or errors found

---

### `compile_check.sh` 🔨
**Full project compilation with comprehensive reporting.**

```bash
./scripts/compile_check.sh
```

**When to use:**
- Final validation before releases
- Investigating complex build issues
- Reviewing full build logs
- CI/CD pipeline integration

**What it does:**
- Clean build of entire project
- Full output logged to file
- Build timing and statistics
- Detailed error analysis and summary

**New features:**
- ⏱️ Build duration tracking
- 📊 Error and warning counts
- 🔍 Shows recent errors for quick review
- 💡 Suggests next steps on failure

**Exit codes:**
- `0`: Build succeeded
- `1`: Build failed

---

### `swift_lint.sh` 📄 **[NEW]**
**Fast syntax checking for individual Swift files.**

```bash
./scripts/swift_lint.sh HomePanelApp/ViewModels/CameraViewModel.swift
./scripts/swift_lint.sh HomePanelApp/Models/*.swift
```

**When to use:**
- Checking specific files during development
- Validating newly created files
- Quick feedback loop while coding
- Testing AI-generated code snippets

**What it does:**
- Uses `swiftc -typecheck` for fast validation
- Works on individual files or glob patterns
- Shows per-file error summaries
- No need for full project compilation

**Arguments:**
- One or more Swift file paths
- Supports wildcards (e.g., `Models/*.swift`)

**Exit codes:**
- `0`: All files passed (warnings ok)
- `1`: Syntax errors found

---

### `verify_project_files.sh` 🔍 **[NEW]**
**Verifies all Swift files are properly referenced in Xcode project.**

```bash
./scripts/verify_project_files.sh
```

**When to use:**
- After creating new files
- When builds succeed but changes don't appear
- Diagnosing missing file issues
- Before major commits

**What it does:**
- Scans filesystem for all Swift files
- Checks each file is referenced in project.pbxproj
- Reports orphaned files
- Provides fix instructions

**Common issues detected:**
- Files created but not added to Xcode project
- Files that won't be compiled
- Source files ignored in builds

**Exit codes:**
- `0`: All files properly referenced
- `1`: Missing file references found

---

### `add_file_to_project.sh`
**Provides guidance for adding new Swift files to Xcode project.**

```bash
./scripts/add_file_to_project.sh HomePanelApp/Services/NewService.swift
```

**When to use:**
- After creating new Swift files
- When `verify_project_files.sh` reports missing files

**What it does:**
- Validates file exists
- Shows step-by-step instructions
- Suggests verification commands

---

### `open_xcode.sh`
**Opens the project in Xcode.**

```bash
./scripts/open_xcode.sh
```

**When to use:**
- Manual testing needed
- Using Xcode debugging tools
- Resolving complex issues

---

## 📊 Output Files

- `compile_output.log` - Full compilation output from xcodebuild
- `syntax_errors.log` - Filtered errors, warnings, and notes

These logs are automatically created and can be reviewed for detailed debugging.

---

## 🎯 Recommended Workflow

### For Regular Development:
1. Make code changes
2. Run `./scripts/quick_syntax_check.sh` (fast validation)
3. Fix any errors reported
4. Commit changes

### Before Pushing to Repository:
1. Run `./scripts/check_syntax_errors.sh` (thorough validation)
2. Address all errors and critical warnings
3. Run `./scripts/verify_project_files.sh` (ensure project integrity)
4. Push with confidence

### When AI Assistant Says "No Errors" But You See Issues:
1. Run `./scripts/check_syntax_errors.sh` yourself
2. If it still shows success, try `./scripts/compile_check.sh`
3. Review full build logs in `compile_output.log`
4. Check `./scripts/verify_project_files.sh` for missing files

---

## 🚀 Integration with Cursor AI

These tools are designed for use by Cursor AI during development sessions:

### In `.cursorrules`:
Reference these tools for automated validation:
- AI should run `check_syntax_errors.sh` after making changes
- AI should verify with `quick_syntax_check.sh` before claiming "no errors"
- AI should use `swift_lint.sh` for quick validation of specific files

### Best Practices for AI:
1. **Always verify**: Don't just assume code compiles - run validation
2. **Use appropriate tool**: Quick check for minor changes, full check for major changes
3. **Read actual output**: Parse error messages and line numbers accurately
4. **Exit codes matter**: Check exit codes, not just grep for "success"
5. **Report specifics**: Share actual error messages with user, not just "no errors"

---

## 🔧 Troubleshooting

### "No errors found" but build still fails:
- Run `compile_check.sh` for full build output
- Check `compile_output.log` for linker errors
- Look for configuration or dependency issues

### Syntax checker misses errors:
- Use `check_syntax_errors.sh` instead of `swift_lint.sh`
- Full compilation catches more issues than syntax-only checks
- Some errors only appear during linking phase

### Files not being compiled:
- Run `verify_project_files.sh` to find orphaned files
- Use `add_file_to_project.sh` for instructions
- Manually add files in Xcode as a last resort

### Tools report wrong simulator:
- Edit scripts to change simulator name/version
- Check available simulators: `xcrun simctl list devices`
- Update destination in script headers

---

## ⚙️ Configuration

All scripts use these defaults:
- **Project**: `HomePanelApp.xcodeproj`
- **Scheme**: `HomePanelApp`
- **Destination**: `platform=iOS Simulator,name=iPad Pro 13-inch (M4)`
- **SDK**: iOS Simulator SDK (auto-detected)

To customize, edit the respective script file.

---

## 📚 Additional Resources

For detailed information about these tools, see the [Development Scripts documentation](../docs/development/cursor-tools.md) if available.

---

## 🔄 Changelog

**Recent improvements:**
- ✅ Better error detection and exit code handling
- ✅ Added `quick_syntax_check.sh` for fast validation
- ✅ Added `swift_lint.sh` for individual file checking
- ✅ Added `verify_project_files.sh` for project integrity
- ✅ Improved error reporting with counts and summaries
- ✅ Build timing and performance metrics
- ✅ Better integration guidance for AI assistants
