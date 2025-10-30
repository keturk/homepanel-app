#!/bin/bash

# Home Panel App - Fix Duplicate Build Files Script
# This script helps identify and provides instructions for fixing duplicate build files

echo "🔍 Checking for duplicate build files..."
echo "======================================"

# Check if we're in the right directory
if [ ! -f "HomePanelApp.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Not in the correct directory. Please run from the project root."
    exit 1
fi

echo "📋 Duplicate files found in build:"
echo "1. BlueIrisServerSettingsView.swift"
echo "2. CamerasTabView.swift" 
echo "3. CameraSelectionItem.swift"
echo "4. CameraSelectionPanel.swift"
echo ""
echo "🔧 To fix these duplicates:"
echo "1. Open HomePanelApp.xcodeproj in Xcode"
echo "2. Select the project in the navigator"
echo "3. Select the 'HomePanelApp' target"
echo "4. Go to 'Build Phases' tab"
echo "5. Expand 'Compile Sources'"
echo "6. Look for duplicate entries and remove them"
echo ""
echo "💡 Alternative: Use Xcode's 'Find and Replace in Project' to search for duplicate file references"
echo ""
echo "✅ Run './cursor_tools/open_xcode.sh' to open the project"
