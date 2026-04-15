# clip-01

`clip-01` is a small macOS menu bar clipboard history app built with Swift 6.2,
AppKit, Carbon hotkeys, and raw `sqlite3`, packaged without Xcode.

## What it does
- Watches the general pasteboard by polling for change count updates.
- Stores up to 200 history entries in a local SQLite file at runtime.
- Captures plain text and images.
- Skips clipboard items tagged as concealed or transient.
- Opens a floating history panel from the menu bar or `Command` + `Shift` + `V`.
- Supports substring search over stored metadata and replaying a selected entry
  back to the pasteboard.

## Why Carbon for the hotkey
The global shortcut uses `RegisterEventHotKey`. For this build that is a
better fit than a global key event monitor because it registers a single
system hotkey without depending on broad key event monitoring.

## Build
From this directory:

```sh
./scripts/build.sh
```

The script performs a release build and wraps the executable into:

```text
build/clip-01.app
```

## Runtime storage
At runtime the app creates:

```text
~/Library/Application Support/clip-01/history.sqlite
```

The store is created with restrictive permissions in code and trimmed to the
newest 200 entries.
