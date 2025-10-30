#!/bin/bash

# Home Panel App - Compilation Check Script
# This script compiles the project and reports detailed compilation status

set -o pipefail

echo "🔨 Compiling Home Panel App..."
echo "=================================="
echo ""

# Get project root (go up one level from cursor_tools)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT/HomePanelApp"

# Start timer
START_TIME=$(date +%s)

# Compile the project with full output
echo "📦 Building project..."
xcodebuild -project HomePanelApp.xcodeproj \
           -scheme HomePanelApp \
           -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' \
           clean build 2>&1 | tee "$PROJECT_ROOT/cursor_tools/compile_output.log"

BUILD_EXIT_CODE=${PIPESTATUS[0]}

# End timer
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "=================================="
echo ""

# Analyze the build output
ERROR_COUNT=$(grep -c "error:" "$PROJECT_ROOT/cursor_tools/compile_output.log" 2>/dev/null || echo "0")
WARNING_COUNT=$(grep -c "warning:" "$PROJECT_ROOT/cursor_tools/compile_output.log" 2>/dev/null || echo "0")

# Check exit code and provide detailed feedback
if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "✅ BUILD SUCCEEDED"
    echo "=================="
    echo ""
    echo "📊 Build Summary:"
    echo "  Status:   Success"
    echo "  Duration: ${DURATION}s"
    echo "  Warnings: $WARNING_COUNT"
    echo ""
    if [ "$WARNING_COUNT" -gt 0 ]; then
        echo "⚠️  Note: Build succeeded but has $WARNING_COUNT warning(s)."
        echo "💡 Run './cursor_tools/check_syntax_errors.sh' to see warnings."
        echo ""
    fi
    echo "📝 Full build log: cursor_tools/compile_output.log"
    exit 0
else
    echo "❌ BUILD FAILED"
    echo "==============="
    echo ""
    echo "📊 Build Summary:"
    echo "  Status:   Failed"
    echo "  Duration: ${DURATION}s"
    echo "  Errors:   $ERROR_COUNT"
    echo "  Warnings: $WARNING_COUNT"
    echo ""

    # Show last 30 lines containing errors or important messages
    echo "🔍 Recent Errors:"
    echo "================="
    grep -E "(error:|warning:|note:|BUILD FAILED)" "$PROJECT_ROOT/cursor_tools/compile_output.log" | tail -30
    echo ""

    echo "💡 Next Steps:"
    echo "  1. Review errors above"
    echo "  2. Run './cursor_tools/check_syntax_errors.sh' for filtered errors"
    echo "  3. Check full log: cursor_tools/compile_output.log"
    echo ""
    exit 1
fi
