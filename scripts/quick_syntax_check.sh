#!/bin/bash

# Home Panel App - Quick Syntax Check
# This script performs fast validation on recently modified Swift files

set -o pipefail

echo "⚡ Quick Syntax Check"
echo "===================="
echo ""

# Get project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not a git repository"
    echo "This tool requires git to track file changes."
    exit 1
fi

# Find modified and untracked Swift files
echo "🔍 Finding modified Swift files..."

# Get modified files (both staged and unstaged)
MODIFIED_FILES=$(git diff --name-only HEAD -- "*.swift" 2>/dev/null)

# Get untracked Swift files
UNTRACKED_FILES=$(git ls-files --others --exclude-standard "*.swift" 2>/dev/null)

# Combine both lists
ALL_FILES=$(echo -e "$MODIFIED_FILES\n$UNTRACKED_FILES" | grep -v "^$" | sort -u)

# Count files
FILE_COUNT=$(echo "$ALL_FILES" | grep -v "^$" | wc -l | tr -d ' ')

if [ "$FILE_COUNT" -eq 0 ]; then
    echo "✅ No modified Swift files found"
    echo ""
    echo "All files are up to date with the last commit."
    echo ""
    echo "💡 To check all files, use:"
    echo "   ./cursor_tools/check_syntax_errors.sh"
    exit 0
fi

echo "📄 Found $FILE_COUNT modified file(s):"
echo "$ALL_FILES" | sed 's/^/   - /'
echo ""

# Ask user if they want to proceed with checking
echo "🔍 Checking syntax..."
echo ""

# Use the swift_lint tool to check each file
ERROR_COUNT=0
WARNING_COUNT=0
CHECKED_COUNT=0

# Find SDK path for iOS
SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
if [ -z "$SDK_PATH" ]; then
    SDK_ARG=""
else
    SDK_ARG="-sdk $SDK_PATH"
fi

FRAMEWORK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks"

# Check each file
while IFS= read -r FILE; do
    if [ -z "$FILE" ]; then
        continue
    fi

    # Skip if file doesn't exist (might have been deleted)
    if [ ! -f "$FILE" ]; then
        continue
    fi

    CHECKED_COUNT=$((CHECKED_COUNT + 1))
    FILENAME=$(basename "$FILE")

    echo "📄 Checking: $FILE"

    # Run Swift syntax check
    OUTPUT=$(swiftc -typecheck $SDK_ARG \
        -target x86_64-apple-ios18.0-simulator \
        -F "$FRAMEWORK_PATH" \
        "$FILE" 2>&1)

    CHECK_EXIT_CODE=$?

    if [ $CHECK_EXIT_CODE -eq 0 ]; then
        echo "   ✅ No issues"
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
done <<< "$ALL_FILES"

# Summary
echo "================================="
echo "📊 Summary:"
echo "  Files checked: $CHECKED_COUNT"
echo "  Total errors:  $ERROR_COUNT"
echo "  Total warnings: $WARNING_COUNT"
echo ""

if [ $ERROR_COUNT -gt 0 ]; then
    echo "❌ Syntax errors found in modified files!"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Fix the errors shown above"
    echo "   2. Run this script again to verify"
    echo "   3. Run './cursor_tools/check_syntax_errors.sh' for full validation"
    exit 1
elif [ $WARNING_COUNT -gt 0 ]; then
    echo "⚠️  Warnings found (no errors)"
    echo ""
    echo "💡 Consider addressing warnings before committing."
    exit 0
else
    echo "✅ All modified files passed syntax check!"
    echo ""
    echo "💡 Ready to proceed. For full validation, run:"
    echo "   ./cursor_tools/check_syntax_errors.sh"
    exit 0
fi
