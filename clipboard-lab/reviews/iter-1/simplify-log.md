# Simplify Log

## What I Removed
- I removed the custom status-item anchoring math for the history panel.
- I removed the shared `RelativeDateTimeFormatter` static state.
- I removed an empty table-selection callback that did nothing.
- I removed the direct use of undeclared `SQLITE_TRANSIENT` symbols and replaced that path with one local binder constant.

## Why
- Centering the panel is less polished than menu-bar anchoring, but it is much simpler and less fragile than hand-maintaining screen-coordinate math in a small iter-1 app.
- Dropping the shared formatter eliminated Swift 6 concurrency complaints and made the display path easier to reason about.
- The empty delegate method added noise without behavior.
- Consolidating SQLite binder behavior in one place reduced repeated low-level glue and fixed the build blocker cleanly.

## Outcome
- The simplified source rebuilt successfully.
- The app keeps the same core value: poll clipboard, persist history, search it, and replay selections.
- The main tradeoff is slightly less refined panel presentation in exchange for a smaller and more robust implementation.
