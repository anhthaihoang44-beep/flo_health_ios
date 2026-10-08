#!/bin/bash
set -e

echo "=== [1/4] Checking and Installing XcodeGen ==="
if ! command -v xcodegen &> /dev/null; then
    echo "Installing xcodegen via Homebrew..."
    brew install xcodegen
fi

echo "=== [2/4] Generating Xcode Project ==="
cd ios
xcodegen generate

echo "=== [3/4] Building CycleCare (ARM64 iOS Device Target) ==="
xcodebuild \
  -project CycleCare.xcodeproj \
  -scheme CycleCare \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  clean build

echo "=== [4/4] Packaging into CycleCare.ipa ==="
rm -rf Payload CycleCare.ipa
mkdir -p Payload
cp -r build/Build/Products/Release-iphoneos/CycleCare.app Payload/
zip -qr CycleCare.ipa Payload
rm -rf Payload

echo "✅ SUCCESS! Generated CycleCare.ipa"
ls -lh CycleCare.ipa
