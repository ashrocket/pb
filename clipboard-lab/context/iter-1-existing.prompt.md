# Codex dispatch: iter-1 existing review + clip-01 design brief

You are codex working inside `clipboard-lab/` in the `agent-pb` repo.
READ `clipboard-lab/CONTEXT.md` AND `clipboard-lab/SPEC.md` BEFORE DOING
ANYTHING ELSE. They contain rules you must follow.

## Task
Iteration 1 existing-app review. Two apps this iteration: **Maccy** and
**Raycast**.

### Step 1. Install
Run these and capture output to `reviews/iter-1/install.log`:
    brew install --cask maccy
    brew install --cask raycast
If either is already installed, note it and continue.

### Step 2. Smoke test (no deep UI testing — user hasn't granted perms yet)
For each app:
- Launch with `open -a "<App Name>"`, wait 3 seconds, verify process exists
  with `pgrep -f`.
- Quit the app afterward (`osascript -e 'tell application "<name>" to quit'`).
- Note whether macOS prompted for permissions (you won't see this; document
  that the user must grant Accessibility + Input Monitoring manually).

### Step 3. Feature + security documentation
For each app, write `existing/maccy.md` and `existing/raycast.md` covering:
- **What it is** (1 sentence)
- **Clipboard features**: history depth, search, image support, pinning,
  snippets, sync, hotkey
- **Storage**: where history is stored (file path), format, encryption status
- **Security posture**: handles concealed/transient pasteboard types?
  excludes password managers? networked?
- **Performance claims**: startup time, memory, DB size limits
- **Known weaknesses** (from your reading, not speculation)
- **Source**: URL or doc you used

You may use WebFetch if available to read official docs. Do NOT speculate
beyond what you can verify. If a feature is unclear, write "unknown".

### Step 4. clip-01 design brief
Write `ours/clip-01/DESIGN.md` covering what clip-01 should be:
- A Swift 6.2 menu bar clipboard manager, built with SPM, no Xcode.
- Target: 200 history entries, SQLite store, search by substring, global
  hotkey (Cmd+Shift+V), image support, concealed-type exclusion.
- Explicit non-goals for iter 1: cloud sync, snippets, rich text formatting
  beyond plain + image, multi-device.
- Call out the three decisions you had to make and why.

Do NOT write any Swift code yet. Only the design brief.

### Step 5. Write summary
Write `reviews/iter-1/SUMMARY.md` (≤30 lines) covering:
- Which apps got installed and launched successfully
- Any install failures and why
- Key finding from existing review (what's common, what's unique)
- clip-01 direction in 2-3 sentences
- What needs user action (e.g., "grant Accessibility to Maccy to enable
  runtime testing in iter 2")

### Step 6. Mark done
After all above, write the literal string `DONE` to
`reviews/iter-1/existing.done`.

## Token discipline
- Do not print file contents to stdout.
- Keep SUMMARY.md tight.
- Use rg/grep/Read for investigation; don't cat big files.
