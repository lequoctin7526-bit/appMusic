#!/bin/bash
set -e

# ==============================================================================
# WaveMix iOS Release Build & IPA Packaging Script
# Requires macOS with Xcode 15 or 16 installed
# ==============================================================================

PROJECT_NAME="WaveMix"
SCHEME_NAME="WaveMix"
CONFIGURATION="Release"
BUILD_DIR="$(pwd)/build"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/IPA"
EXPORT_OPTIONS_PLIST="$(pwd)/scripts/ExportOptions.plist"

echo "=== 1. Cleaning build directory ==="
rm -rf "$BUILD_DIR"
mkdir -p "$EXPORT_PATH"

echo "=== 2. Running Unit Tests ==="
xcodebuild test \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "${SCHEME_NAME}Tests" \
    -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
    -resultBundlePath "$BUILD_DIR/TestResults.xcresult" \
    CODE_SIGNING_ALLOWED=NO

echo "=== 3. Creating Release Archive ==="
xcodebuild archive \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_STYLE=Automatic

echo "=== 4. Exporting Signed IPA ==="
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

echo "=== Build Complete! ==="
echo "Artifact IPA path: $EXPORT_PATH/$PROJECT_NAME.ipa"
ls -lh "$EXPORT_PATH"
