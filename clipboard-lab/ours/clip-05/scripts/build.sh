#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/clip-05.app"
CONTENTS_DIR="$APP_DIR/Contents"
BUILD_ROOT="$ROOT_DIR/.build-work"
LOCAL_CACHE_DIR="$BUILD_ROOT/local-cache"
MODULE_CACHE_DIR="$BUILD_ROOT/module-cache"
HOME_DIR="$BUILD_ROOT/home"

cd "$ROOT_DIR"

mkdir -p "$LOCAL_CACHE_DIR" "$MODULE_CACHE_DIR" "$HOME_DIR"
export HOME="$HOME_DIR"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"
export SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR"
export SWIFTPM_CUSTOM_CACHE_PATH="$LOCAL_CACHE_DIR"
export XDG_CACHE_HOME="$LOCAL_CACHE_DIR"

swift build --disable-sandbox --build-path "$BUILD_ROOT" -c release

mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$BUILD_ROOT/release/clip-05" "$CONTENTS_DIR/MacOS/clip-05"
cp "bundle/Info.plist" "$CONTENTS_DIR/Info.plist"

printf '%s\n' "$APP_DIR"
