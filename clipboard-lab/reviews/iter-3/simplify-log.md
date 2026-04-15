# Simplify Log

## Pass Goal
Reduce duplicated query-building code without changing runtime behavior.

## Simplification Applied
- `QueryParser.parse` now uses two small local helpers:
  `append(_:_)` for clause/binding pairs and `appendSubstring(_:)` for the
  repeated `LIKE` pattern.
- `Store.fetchEntries` now binds `QueryParser.BoundValue` through one helper
  instead of repeating the `switch` inline.

## Why This Was Worth It
- The SQL grammar is now easier to audit because every parser path appends
  bindings the same way.
- The store no longer owns parser-specific branching logic beyond "bind this
  query value".
- The change trimmed repetition without changing the package surface or the
  query syntax.

## Rebuild
- `./scripts/build.sh`: pass
- `swift test --disable-sandbox`: pass
- Log: `reviews/iter-3/clip-03-build.log`
