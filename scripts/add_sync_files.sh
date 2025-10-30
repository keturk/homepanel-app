#!/bin/bash

# Add sync utility files to Xcode project
cd HomePanelApp

# Add SyncDebugUtils.swift
echo "Adding SyncDebugUtils.swift to Xcode project..."
xcodebuild -project HomePanelApp.xcodeproj -target HomePanelApp -add-to-target HomePanelApp Shared/Utilities/SyncDebugUtils.swift

# Add ManualSyncService.swift  
echo "Adding ManualSyncService.swift to Xcode project..."
xcodebuild -project HomePanelApp.xcodeproj -target HomePanelApp -add-to-target HomePanelApp Shared/Utilities/ManualSyncService.swift

echo "Files added to Xcode project"
