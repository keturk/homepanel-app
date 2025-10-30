#!/bin/bash

# Home Panel App - Swift File Linter
# This script performs fast syntax checking on individual Swift files using swiftc

set -o pipefail

# Check if file path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <swift_file_path> [additional_files...]"
    echo ""
    echo "Examples:"
    echo "  $0 HomePanelApp/ViewModels/CameraViewModel.swift"
    echo "  $0 HomePanelApp/Models/*.swift"
    echo ""
    echo "This tool performs fast syntax-only checking without full compilation."
    exit 1
fi

echo "🔍 Swift Lint Check"
echo "==================="
echo ""

# Get project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Find SDK path for iOS
SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
if [ -z "$SDK_PATH" ]; then
    echo "⚠️  Warning: Could not find iOS Simulator SDK"
    echo "Proceeding with basic syntax check..."
    SDK_ARG=""
else
    SDK_ARG="-sdk $SDK_PATH"
fi

# Common Swift frameworks path
FRAMEWORK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks"

# Count files to check
FILE_COUNT=0
ERROR_COUNT=0
WARNING_COUNT=0

# Process each file
for FILE in "$@"; do
    # Convert to absolute path if relative
    if [[ "$FILE" != /* ]]; then
        FILE="$PROJECT_ROOT/$FILE"
    fi

    # Check if file exists
    if [ ! -f "$FILE" ]; then
        echo "❌ File not found: $FILE"
        continue
    fi

    FILE_COUNT=$((FILE_COUNT + 1))
    FILENAME=$(basename "$FILE")

    echo "📄 Checking: $FILENAME"

    # Run Swift syntax check
    # -parse: Only parse, don't type-check
    # -typecheck: Parse and type-check (more thorough)
    OUTPUT=$(swiftc -typecheck $SDK_ARG \
        -target x86_64-apple-ios18.0-simulator \
        -F "$FRAMEWORK_PATH" \
        "$FILE" 2>&1)

    CHECK_EXIT_CODE=$?

    if [ $CHECK_EXIT_CODE -eq 0 ]; then
        echo "   ✅ No issues found"
    else
        # Count errors and warnings
        FILE_ERRORS=$(echo "$OUTPUT" | grep -c "error:" || echo "0")
        FILE_WARNINGS=$(echo "$OUTPUT" | grep -c "warning:" || echo "0")

        ERROR_COUNT=$((ERROR_COUNT + FILE_ERRORS))
        WARNING_COUNT=$((WARNING_COUNT + FILE_WARNINGS))

        if [ "$FILE_ERRORS" -gt 0 ]; then
            echo "   ❌ $FILE_ERRORS error(s), $FILE_WARNINGS warning(s)"
        else
            echo "   ⚠️  $FILE_WARNINGS warning(s)"
        fi

        echo ""
        echo "   Details:"
        echo "   --------"
        echo "$OUTPUT" | sed 's/^/   /'
    fi

    echo ""
done

# Summary
echo "================================="
echo "📊 Summary:"
echo "  Files checked: $FILE_COUNT"
echo "  Total errors:  $ERROR_COUNT"
echo "  Total warnings: $WARNING_COUNT"
echo ""

if [ $ERROR_COUNT -gt 0 ]; then
    echo "❌ Syntax errors found!"
    echo ""
    echo "💡 Note: This is a fast syntax check only."
    echo "   Some errors may only appear during full build."
    echo "   Run './cursor_tools/compile_check.sh' for complete validation."
    exit 1
elif [ $WARNING_COUNT -gt 0 ]; then
    echo "⚠️  Warnings found (no errors)"
    echo ""
    echo "💡 Consider addressing warnings for better code quality."
    exit 0
else
    echo "✅ All files passed syntax check!"
    echo ""
    echo "💡 Note: This is a fast syntax check only."
    echo "   Run './cursor_tools/check_syntax_errors.sh' for full validation."
    exit 0
fi
