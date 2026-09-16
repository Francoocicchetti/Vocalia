#!/bin/zsh
set -eu
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SOURCE_DIR/dist"
mkdir -p "$OUTPUT_DIR"
BUILD_DIR=$(mktemp -d /private/tmp/franco-transcribe-build.XXXXXX)
APP_DIR="$BUILD_DIR/Vocalia.app"
BUILD_SOURCE="$BUILD_DIR/source"
mkdir -p "$BUILD_SOURCE"
cp "$SOURCE_DIR/"*.swift "$BUILD_SOURCE/"
unzip -q "$SOURCE_DIR/Vendor.zip" -d "$BUILD_SOURCE"
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/module-cache"
export SWIFT_MODULECACHE_PATH="$BUILD_DIR/module-cache"
swift build --package-path "$BUILD_SOURCE" --scratch-path "$BUILD_DIR/build" --cache-path "$BUILD_DIR/cache" --config-path "$BUILD_DIR/config" --security-path "$BUILD_DIR/security" --disable-sandbox -c release
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources/Licencias"
cp "$SOURCE_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$SOURCE_DIR/TranscribeIcon.icns" "$APP_DIR/Contents/Resources/TranscribeIcon.icns"
cp "$BUILD_DIR/build/release/Transcribe" "$APP_DIR/Contents/MacOS/Transcribe"
cp "$BUILD_SOURCE/Vendor/Argmax/LICENSE" "$BUILD_SOURCE/Vendor/Argmax/NOTICES" "$BUILD_SOURCE/Vendor/Argmax/ORIGEN.txt" "$APP_DIR/Contents/Resources/Licencias/"
xattr -cr "$APP_DIR"
codesign --force --sign - "$APP_DIR"
"$APP_DIR/Contents/MacOS/Transcribe" --self-test
codesign --verify --deep --strict "$APP_DIR"
ditto -c -k --norsrc --keepParent "$APP_DIR" "$OUTPUT_DIR/Vocalia-1.0.1-macOS-AppleSilicon.zip"
cp "$SOURCE_DIR/START-HERE.txt" "$BUILD_DIR/START-HERE.txt"
(cd "$BUILD_DIR" && /usr/bin/zip -q "$OUTPUT_DIR/Vocalia-1.0.1-macOS-AppleSilicon.zip" START-HERE.txt)
echo "Build ready: $OUTPUT_DIR/Vocalia-1.0.1-macOS-AppleSilicon.zip"
