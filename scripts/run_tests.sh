#!/bin/bash

# HomePanelApp Test Runner
# This script runs all tests using a working simulator

set -e

cd "$(dirname "$0")/HomePanelApp"

echo "🧪 Running HomePanelApp Tests..."
echo "=================================="

# Use a specific working simulator
SIMULATOR_ID="428CFC03-D765-4FBC-AC20-38C55146A63F"

# Run tests
xcodebuild test \
  -scheme HomePanelApp \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  2>&1 | xcpretty || xcodebuild test \
  -scheme HomePanelApp \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID"

echo ""
echo "✅ Tests completed!"
