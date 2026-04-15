# Simplify Log

## Pass Goal
Reduce implementation complexity without removing any of the final-iteration
polish work.

## Simplification Applied
- Kept one encrypted search pipeline for both normal text clips and OCR text.
  `Store.replaceSearchTerms` and `SearchIndex` now serve both cases instead of
  introducing a second OCR-specific index path or a shadow search store.
- Kept thumbnail and preview decoding behind one small `ThumbnailBroker`
  instead of scattering background decode logic across the table cell and
  preview pane.
- Kept config reloading on a single file-system watcher pointed at the config
  directory instead of mixing FSEvents and separate file polling.

## Why This Was Worth It
- The code now has fewer parallel systems to reason about.
- OCR did not add a second persistence model; it plugs into the same encrypted
  metadata and HMAC search path as everything else.
- The UI polish is still present, but the threading and image-loading logic are
  centralized enough to review.

## Rebuild
- `./scripts/build.sh`: pass
- `swift test --disable-sandbox`: pass as compile gate
- standalone verifier: `31` cases passed
- Log: `reviews/iter-5/clip-05-build.log`
