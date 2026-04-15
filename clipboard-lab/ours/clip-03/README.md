# clip-03

`clip-03` is a Swift 6.2 macOS menu bar clipboard history app built with
AppKit, Carbon hotkeys, raw `sqlite3`, and a local `config.toml`. It keeps the
iter-2 local-first model but fixes three weak points: there is now a real
settings window, the config watcher is scoped to `config.toml`, and search is a
small query language instead of only an `image:` prefix.

## What changed from clip-02
- Settings now live behind a real `NSWindow` with AppKit form controls:
  pause capture, max clip size, and excluded bundle IDs can be edited without
  hand-editing the config file.
- Config reload is disciplined: the app watches only
  `~/Library/Application Support/clip-03/config.toml`, and the event callback
  filters for that filename before reloading.
- Search supports field filters and plain substring terms:
  `app:`, `after:`, `type:`, plus the iter-2-compatible `image:` alias.
- Clipboard URLs are stored as their own clip type so `type:url` has real
  meaning instead of being folded into plain text.
- `QueryParser` is isolated from AppKit and covered by `swift test`.

## Keyboard controls
- `Command` + `Shift` + `V`: open or close the history panel
- `Up` / `Down`: move the current selection
- `Return`: copy the selected row back to the pasteboard
- `Escape`: close the panel
- `Command` + `1` ... `Command` + `9`: copy one of the first nine visible rows

## Search grammar
Tokens are separated by spaces. Tokens are combined with `AND`. Quoted phrases
are kept together.

- `type:text`
- `type:image`
- `type:url`
- `app:com.apple.Safari`
- `after:2026-04-01`
- `after:2026-04-01T15:30:00Z`
- `image:` as an alias for `type:image`
- any other token becomes a case-insensitive substring match on stored search
  text

Examples:

- `invoice`
- `type:url kureapp`
- `app:com.apple.Safari type:text portal`
- `after:2026-04-01 type:image`
- `"prior auth" app:com.google.Chrome`
- `image: receipt`

Date-only `after:` values are interpreted as midnight UTC on that date.

## Settings + config file
At runtime the app creates:

```text
~/Library/Application Support/clip-03/config.toml
```

The settings window edits the same file using these keys:

```toml
pause_capture = false
max_bytes_per_clip = 1048576
excluded_bundle_ids = [
]
```

- `pause_capture`: when `true`, new clipboard changes are ignored
- `max_bytes_per_clip`: byte cap for normalized text, URL, and PNG image clips
- `excluded_bundle_ids`: bundle IDs to ignore while capturing

## Build
From this directory:

```sh
./scripts/build.sh
swift test
```

The build script performs a release build and wraps the executable into:

```text
build/clip-03.app
```

## Runtime storage
At runtime the app creates:

```text
~/Library/Application Support/clip-03/history.sqlite
```

The support directory is set to `0700`, the SQLite file is set to `0600`, and
history is trimmed to the newest 200 entries.
