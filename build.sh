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
cp "$SOURCE_DIR/ui-translations.json" "$BUILD_SOURCE/"
unzip -q "$SOURCE_DIR/Vendor.zip" -d "$BUILD_SOURCE"
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/module-cache"
export SWIFT_MODULECACHE_PATH="$BUILD_DIR/module-cache"
swift build --package-path "$BUILD_SOURCE" --scratch-path "$BUILD_DIR/build" --cache-path "$BUILD_DIR/cache" --config-path "$BUILD_DIR/config" --security-path "$BUILD_DIR/security" --disable-sandbox -c release
unzip -q "$SOURCE_DIR/OpusDecoder-source.zip" -d "$BUILD_DIR"
sh "$SOURCE_DIR/tools/build_opus.sh" "$BUILD_DIR/decoder"
"$BUILD_DIR/decoder/opusdecode" "$SOURCE_DIR/Vocalia-Windows/test-speech.opus" "$BUILD_DIR/opus-check.wav"
python3 - "$BUILD_DIR/opus-check.wav" <<'PY'
import sys, wave
with wave.open(sys.argv[1], 'rb') as audio:
    assert audio.getframerate() == 48000 and audio.getnchannels() == 1
    assert 10 < audio.getnframes() / audio.getframerate() < 12
print('PASS: bundled OPUS decoder produces complete mono PCM')
PY
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources/Licencias"
cp "$SOURCE_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$SOURCE_DIR/ui-translations.json" "$APP_DIR/Contents/Resources/"
cp "$SOURCE_DIR/TranscribeIcon.icns" "$APP_DIR/Contents/Resources/TranscribeIcon.icns"
cp "$BUILD_DIR/build/release/Transcribe" "$APP_DIR/Contents/MacOS/Transcribe"
cp "$BUILD_SOURCE/Vendor/Argmax/LICENSE" "$BUILD_SOURCE/Vendor/Argmax/NOTICES" "$BUILD_SOURCE/Vendor/Argmax/ORIGEN.txt" "$APP_DIR/Contents/Resources/Licencias/"
cp "$BUILD_DIR/decoder/opusdecode" "$APP_DIR/Contents/MacOS/opusdecode"
cp -R "$BUILD_DIR/decoder/licenses" "$APP_DIR/Contents/Resources/Licencias/Opus"
xattr -cr "$APP_DIR"
codesign --force --sign - "$APP_DIR/Contents/MacOS/opusdecode"
codesign --force --sign - "$APP_DIR"
"$APP_DIR/Contents/MacOS/Transcribe" --self-test
"$APP_DIR/Contents/MacOS/Transcribe" --auto-import-test
"$APP_DIR/Contents/MacOS/Transcribe" --audio-review-test "$SOURCE_DIR/Vocalia-Windows/test-speech.opus"
"$APP_DIR/Contents/MacOS/Transcribe" --update-self-test
codesign --verify --deep --strict "$APP_DIR"
ditto -c -k --norsrc --keepParent "$APP_DIR" "$OUTPUT_DIR/Vocalia-0.0.6-macOS-AppleSilicon.zip"
cp "$SOURCE_DIR/START-HERE.txt" "$BUILD_DIR/START-HERE.txt"
(cd "$BUILD_DIR" && /usr/bin/zip -q "$OUTPUT_DIR/Vocalia-0.0.6-macOS-AppleSilicon.zip" START-HERE.txt)
"$APP_DIR/Contents/MacOS/Transcribe" --update-package-test "$OUTPUT_DIR/Vocalia-0.0.6-macOS-AppleSilicon.zip"
echo "Build ready: $OUTPUT_DIR/Vocalia-0.0.6-macOS-AppleSilicon.zip"
