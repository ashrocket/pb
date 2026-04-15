#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/clip-03.app"
CONTENTS_DIR="$APP_DIR/Contents"
LOCAL_CACHE_DIR="$ROOT_DIR/.build/local-cache"
MODULE_CACHE_DIR="$ROOT_DIR/.build/module-cache"

cd "$ROOT_DIR"

mkdir -p "$LOCAL_CACHE_DIR" "$MODULE_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"
export SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR"
export SWIFTPM_CUSTOM_CACHE_PATH="$LOCAL_CACHE_DIR"
export XDG_CACHE_HOME="$LOCAL_CACHE_DIR"

swift build --disable-sandbox -c release

mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp ".build/release/clip-03" "$CONTENTS_DIR/MacOS/clip-03"
cp "bundle/Info.plist" "$CONTENTS_DIR/Info.plist"

printf '%s\n' "$APP_DIR"
