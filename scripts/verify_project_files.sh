#!/bin/bash

# Home Panel App - Project File Verification
# This script verifies that all Swift files in the filesystem are properly referenced in the Xcode project

set -o pipefail

echo "🔍 Verifying Project Files"
echo "=========================="
echo ""

# Get project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Check if project file exists
PROJECT_FILE="HomePanelApp/HomePanelApp.xcodeproj/project.pbxproj"
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Project file not found: $PROJECT_FILE"
    exit 1
fi

echo "📦 Scanning filesystem for Swift files..."

# Find all Swift files in the project (excluding build artifacts and packages)
FILESYSTEM_FILES=$(find HomePanelApp -name "*.swift" -type f \
    ! -path "*/Build/*" \
    ! -path "*/DerivedData/*" \
    ! -path "*/.build/*" \
    ! -path "*/Pods/*" \
    ! -path "*/Carthage/*" \
    | sort)

FILESYSTEM_COUNT=$(echo "$FILESYSTEM_FILES" | grep -v "^$" | wc -l | tr -d ' ')

echo "   Found $FILESYSTEM_COUNT Swift file(s) in filesystem"
echo ""

echo "📋 Checking Xcode project references..."

# Track missing files
MISSING_FILES=""
MISSING_COUNT=0

# Check each file
while IFS= read -r FILE; do
    if [ -z "$FILE" ]; then
        continue
    fi

    FILENAME=$(basename "$FILE")

    # Check if file is referenced in project.pbxproj
    if ! grep -q "$FILENAME" "$PROJECT_FILE"; then
        MISSING_FILES="$MISSING_FILES\n$FILE"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done <<< "$FILESYSTEM_FILES"

echo ""
echo "================================="
echo "📊 Results:"
echo "  Total Swift files:     $FILESYSTEM_COUNT"
echo "  Missing from project:  $MISSING_COUNT"
echo ""

if [ $MISSING_COUNT -gt 0 ]; then
    echo "❌ Files not referenced in Xcode project:"
    echo "=========================================="
    echo -e "$MISSING_FILES" | grep -v "^$"
    echo ""
    echo "💡 These files exist in the filesystem but are not included in the Xcode project."
    echo "   This can cause issues where:"
    echo "   - Files are not compiled"
    echo "   - Changes don't take effect when building"
    echo "   - CI/CD builds may fail"
    echo ""
    echo "🔧 To fix:"
    echo "   1. Open HomePanelApp.xcodeproj in Xcode"
    echo "   2. For each missing file, right-click the appropriate group"
    echo "   3. Select 'Add Files to HomePanelApp'"
    echo "   4. Select the file and ensure target is checked"
    echo ""
    echo "   Or use: ./cursor_tools/add_file_to_project.sh <file_path>"
    exit 1
else
    echo "✅ All Swift files are properly referenced in the Xcode project!"
    echo ""
    echo "Your project structure is consistent."
    exit 0
fi
