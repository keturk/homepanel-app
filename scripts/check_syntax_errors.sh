#!/bin/bash

# Home Panel App - Syntax Error Check Script
# This script compiles and extracts syntax errors, warnings, and notes from the output

set -o pipefail

echo "🔍 Checking for syntax errors..."
echo "================================="

# Get project root (go up one level from cursor_tools)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT/HomePanelApp"

# Clean previous logs
> "$PROJECT_ROOT/cursor_tools/syntax_errors.log"

# Compile and capture ALL output
BUILD_OUTPUT=$(xcodebuild -project HomePanelApp.xcodeproj \
           -scheme HomePanelApp \
           -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' \
           -quiet \
           clean build 2>&1)

BUILD_EXIT_CODE=$?

# Extract errors, warnings, and notes with context
echo "$BUILD_OUTPUT" | grep -E "(error:|warning:|note:)" > "$PROJECT_ROOT/cursor_tools/syntax_errors.log"

# Also capture "BUILD FAILED" messages
if echo "$BUILD_OUTPUT" | grep -q "BUILD FAILED"; then
    echo "" >> "$PROJECT_ROOT/cursor_tools/syntax_errors.log"
    echo "=== BUILD FAILED ===" >> "$PROJECT_ROOT/cursor_tools/syntax_errors.log"
fi

# Count errors and warnings
ERROR_COUNT=$(grep -c "error:" "$PROJECT_ROOT/cursor_tools/syntax_errors.log" 2>/dev/null || echo "0")
WARNING_COUNT=$(grep -c "warning:" "$PROJECT_ROOT/cursor_tools/syntax_errors.log" 2>/dev/null || echo "0")
NOTE_COUNT=$(grep -c "note:" "$PROJECT_ROOT/cursor_tools/syntax_errors.log" 2>/dev/null || echo "0")

# Check if there are any errors
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "❌ Syntax errors found!"
    echo "======================="
    echo ""
    echo "📊 Summary:"
    echo "  Errors:   $ERROR_COUNT"
    echo "  Warnings: $WARNING_COUNT"
    echo "  Notes:    $NOTE_COUNT"
    echo ""
    echo "📄 Details:"
    echo "==========="
    cat "$PROJECT_ROOT/cursor_tools/syntax_errors.log"
    echo ""
    echo "💡 Tip: Review the errors above and fix them before proceeding."
    echo "📝 Full log: cursor_tools/syntax_errors.log"
    exit 1
elif [ "$WARNING_COUNT" -gt 0 ]; then
    echo "⚠️  Warnings found (no errors):"
    echo "==============================="
    echo ""
    echo "📊 Summary:"
    echo "  Errors:   $ERROR_COUNT"
    echo "  Warnings: $WARNING_COUNT"
    echo "  Notes:    $NOTE_COUNT"
    echo ""
    echo "📄 Details:"
    echo "==========="
    cat "$PROJECT_ROOT/cursor_tools/syntax_errors.log"
    echo ""
    echo "💡 Tip: Consider addressing warnings for better code quality."
    echo "📝 Full log: cursor_tools/syntax_errors.log"
    exit 0
elif [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo "❌ Build failed but no explicit errors captured!"
    echo "================================================"
    echo ""
    echo "This could indicate:"
    echo "  - Linker errors"
    echo "  - Missing dependencies"
    echo "  - Configuration issues"
    echo ""
    echo "💡 Run './cursor_tools/compile_check.sh' for full build output."
    exit 1
else
    echo "✅ No syntax errors or warnings found!"
    echo "======================================"
    echo ""
    echo "Build completed successfully."
    exit 0
fi
