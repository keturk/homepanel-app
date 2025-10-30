#!/bin/bash

# Add LockoutManager.swift to Xcode project
# This script adds the missing LockoutManager.swift file to the Xcode project

echo "🔧 Adding LockoutManager.swift to Xcode project..."
echo "=================================="

# Check if we're in the right directory
if [ ! -f "HomePanelApp.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Not in the correct directory. Please run from the HomePanelApp directory."
    exit 1
fi

# Check if LockoutManager.swift exists
if [ ! -f "Services/LockoutManager.swift" ]; then
    echo "❌ Error: Services/LockoutManager.swift does not exist"
    exit 1
fi

echo "📋 Manual steps required:"
echo "1. Open HomePanelApp.xcodeproj in Xcode"
echo "2. Right-click on the 'Services' group in the navigator"
echo "3. Select 'Add Files to HomePanelApp'"
echo "4. Navigate to and select: Services/LockoutManager.swift"
echo "5. Make sure 'Add to target: HomePanelApp' is checked"
echo "6. Click 'Add'"
echo ""
echo "💡 Alternative: Drag and drop Services/LockoutManager.swift from Finder into the Services group in Xcode"
echo ""
echo "✅ After adding the file, run './cursor_tools/compile_check.sh' to verify the build works"
echo "✅ Run './cursor_tools/open_xcode.sh' to open the project"
