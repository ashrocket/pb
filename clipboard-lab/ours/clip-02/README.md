# clip-02

`clip-02` is a Swift 6.2 macOS menu bar clipboard history app built with
AppKit, Carbon hotkeys, raw `sqlite3`, and a local TOML config file. It is a
new sibling package to `clip-01`, not a refactor of it.

## What changed from clip-01
- Explicit panel keyboard controls: `Up` / `Down` move selection, `Return`
  copies, `Escape` closes, and `Command` + `1` through `9` quick-pick visible
  rows.
- Image capture stores PNG bytes instead of TIFF and records width, height, and
  byte size for each image row.
- Search supports an `image:` prefix so image-only filtering is one keystroke
  away.
- Runtime privacy controls now live in a watched config file and apply without
  restarting the app.

## Keyboard controls
- `Command` + `Shift` + `V`: open or close the history panel
- `Up` / `Down`: move the current selection
- `Return`: copy the selected row back to the pasteboard
- `Escape`: close the panel
- `Command` + `1` ... `Command` + `9`: copy one of the first nine visible rows

## Search behavior
- Plain text search is still literal substring matching over stored metadata.
- Prefix with `image:` to limit results to image clips.
- Examples:
  - `invoice`
  - `image:`
  - `image: 1440x900`

## Config file
At runtime the app creates and watches:

```text
~/Library/Application Support/clip-02/config.toml
```

The supported keys are:

```toml
pause_capture = false
max_bytes_per_clip = 1048576
excluded_bundle_ids = [
]
```

- `pause_capture`: when `true`, new clipboard changes are ignored
- `max_bytes_per_clip`: byte cap for both text and image clips after
  normalization/encoding
- `excluded_bundle_ids`: frontmost app bundle IDs to ignore during capture

The file is loaded on launch and reloaded on the fly with FSEvents whenever it
changes.

## Build
From this directory:

```sh
./scripts/build.sh
```

The script performs a release build and wraps the executable into:

```text
build/clip-02.app
```

## Runtime storage
At runtime the app creates:

```text
~/Library/Application Support/clip-02/history.sqlite
```

The SQLite file is set to `0600`, the support directory is set to `0700`, and
history is trimmed to the newest 200 entries.
