# pb Rename + /pb Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename agent-pb to pb everywhere (GitHub repo, plugin, marketplace, site), add a first-class `/pb` slash command whose argument the LLM interprets, move the site to GitHub Pages, and delete the Cloudflare Pages project.

**Architecture:** The plugin ships three prompt surfaces sharing one ruleset: `skills/pb/SKILL.md` (source of truth — selection/copy/safety rules, also consumed by Codex), `commands/pb.md` (thin `/pb` slash command that invokes the skill with `$ARGUMENTS`), and `snippets/pb-rules.md` (portable copy for Cursor/Windsurf/Copilot). The static site moves from `site/` (Cloudflare Pages) to `docs/` (GitHub Pages, branch `main`, path `/docs`).

**Tech Stack:** Claude Code plugin format (plugin.json / marketplace.json / commands / skills), `gh` CLI, `wrangler` CLI, plain static HTML.

## Global Constraints

- Spec: `specs/2026-07-01-pb-rename-design.md`
- New names: repo `ashrocket/pb`, marketplace `pb`, plugin `pb`, version `0.2.0`. Install: `/plugin marketplace add ashrocket/pb` + `/plugin install pb@pb`.
- New site base URL: `https://ashrocket.github.io/pb/` (subpath! — no root-absolute links like `href="/blog.html"` anywhere in `docs/`).
- Do NOT touch `clipboard-lab/` (unrelated experiment; its files mention agent-pb — leave them).
- Do NOT rewrite `specs/` history mentions of agent-pb (they document the rename).
- Keep the `agent-look.raiteri.net` link in README/site as-is (different project).
- Commit after every task. Commit messages end with:
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Y2v68Hf4tUzCgARe2r6MAf`
- sed ORDER MATTERS in Task 5: rewrite `agent-pb.raiteri.net` → `ashrocket.github.io/pb` FIRST, then the blanket `agent-pb` → `pb`. Reversed, the domain would wrongly become `pb.raiteri.net`.

---

### Task 1: Rename the GitHub repo

**Files:** none (external + git config only)

**Interfaces:**
- Produces: remote `origin` → `https://github.com/ashrocket/pb.git`; repo homepage set. All later tasks reference `ashrocket/pb`.

- [ ] **Step 1: Rename via gh**

```bash
gh repo rename pb --repo ashrocket/agent-pb --yes
```

Expected: `✓ Renamed repository ashrocket/pb`

- [ ] **Step 2: Point local remote at the new URL and set homepage**

```bash
git remote set-url origin https://github.com/ashrocket/pb.git
gh repo edit ashrocket/pb --homepage "https://ashrocket.github.io/pb/"
```

- [ ] **Step 3: Verify**

```bash
gh repo view ashrocket/pb --json name,homepageUrl
git ls-remote origin HEAD
```

Expected: `{"homepageUrl":"https://ashrocket.github.io/pb/","name":"pb"}` and a commit hash (remote reachable). No commit for this task (nothing in the tree changed).

---

### Task 2: Plugin + marketplace manifests → pb 0.2.0

**Files:**
- Modify: `.claude-plugin/plugin.json` (full replacement)
- Modify: `.claude-plugin/marketplace.json` (full replacement)

**Interfaces:**
- Produces: plugin id `pb`, marketplace `pb` — the `pb@pb` install coordinates and the `pb:pb` skill namespace used by Task 3's command.

- [ ] **Step 1: Write `.claude-plugin/plugin.json`**

```json
{
  "name": "pb",
  "version": "0.2.0",
  "description": "Copy the right artifact from your conversation to the clipboard. /pb grabs the most recent useful thing; /pb <hint> lets the LLM pick the match.",
  "author": {
    "name": "Ashley Raiteri",
    "email": "pb@raiteri.net"
  },
  "homepage": "https://ashrocket.github.io/pb/",
  "repository": "https://github.com/ashrocket/pb",
  "license": "MIT",
  "keywords": ["clipboard", "pbcopy", "paste-buffer", "productivity", "cross-agent"]
}
```

- [ ] **Step 2: Write `.claude-plugin/marketplace.json`**

```json
{
  "name": "pb",
  "description": "Clipboard butter knife for AI coding agents",
  "owner": { "name": "Ashley Raiteri" },
  "plugins": [
    {
      "name": "pb",
      "description": "Clipboard butter knife. Say /pb — copies the right artifact from the conversation to your paste buffer.",
      "version": "0.2.0",
      "source": "./",
      "author": { "name": "Ashley Raiteri" }
    }
  ]
}
```

- [ ] **Step 3: Verify both parse and are consistent**

```bash
jq -e '.name == "pb" and .version == "0.2.0"' .claude-plugin/plugin.json
jq -e '.name == "pb" and .plugins[0].name == "pb" and .plugins[0].version == "0.2.0"' .claude-plugin/marketplace.json
```

Expected: `true` twice.

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/
git commit -m "Rename plugin and marketplace to pb, bump to 0.2.0"
```

---

### Task 3: Add the `/pb` slash command

**Files:**
- Create: `commands/pb.md`

**Interfaces:**
- Consumes: skill namespace `pb:pb` (established by Task 2's plugin rename; skill file exists already at `skills/pb/SKILL.md`).
- Produces: `/pb [args]` slash command with `$ARGUMENTS` passthrough.

- [ ] **Step 1: Write `commands/pb.md`**

```markdown
---
description: Copy an artifact from this conversation to the clipboard — /pb picks the most recent useful thing, /pb <hint> picks the best match
argument-hint: [what to copy — a type, description, or ordinal]
---

Copy an artifact from this conversation to the user's clipboard.

What the user asked for: $ARGUMENTS

Invoke the `pb:pb` skill with the request above as its arguments. If the
request is empty, invoke it with no arguments — the skill picks the most
recent useful artifact.

If the skill is unavailable, do it directly: choose the artifact (with a
hint, interpret it — type, description, or ordinal; without one, most
recent useful: query > shell command > code block > URL > config > plain
text), pipe the raw content to pbcopy / wl-copy / xclip -selection
clipboard / clip.exe, and confirm in one line. Never copy secrets unasked.
```

- [ ] **Step 2: Verify frontmatter and placeholder**

```bash
head -4 commands/pb.md | grep -c "description:\|argument-hint:" && grep -c '\$ARGUMENTS' commands/pb.md
```

Expected: `2` then `1`.

- [ ] **Step 3: Commit**

```bash
git add commands/pb.md
git commit -m "Add /pb slash command with LLM-interpreted arguments"
```

---

### Task 4: Improve the skill and the portable snippet

**Files:**
- Modify: `skills/pb/SKILL.md` (full replacement)
- Modify: `snippets/pb-rules.md` (full replacement)

**Interfaces:**
- Produces: the selection/copy/safety ruleset that `commands/pb.md` (Task 3) delegates to.

- [ ] **Step 1: Write `skills/pb/SKILL.md`**

````markdown
---
name: pb
description: Use when the user types /pb or $pb, or asks to copy something from the conversation to the clipboard or paste buffer — "copy that", "copy the query", "grab that command", "put it in my paste buffer", "gimme that". Copies the selected artifact to the system clipboard; with no target given, picks the most recent useful artifact.
---

Copy the artifact to clipboard. Be fast — no explanation, no preamble.

## Select

With args, interpret them freely: artifact type ("command"), description
("the AQL query"), ordinal ("2" = 2nd most recent), or fuzzy intent
("that thing for prod"). Prefer the most recent match.

Without args, pick the most recent useful artifact:
query > shell command > code block > URL > config > plain text.

Ordered sequences: copy first-to-run, not last.

If nothing plausibly matches, say so — don't guess, don't copy noise.

## Copy

```bash
if command -v pbcopy &>/dev/null; then CB="pbcopy"
elif command -v wl-copy &>/dev/null; then CB="wl-copy"
elif command -v xclip &>/dev/null; then CB="xclip -selection clipboard"
elif command -v clip.exe &>/dev/null; then CB="clip.exe"; fi
```

Single-line: `printf '%s' 'CONTENT' | $CB` (escape `'` as `'\''`)

Multi-line: heredoc with `$CB <<'PBEOF'`

No clipboard binary (e.g. SSH session)? Try OSC52 — the terminal sets the
local clipboard:

```bash
printf '\033]52;c;%s\a' "$(printf '%s' "$CONTENT" | base64 | tr -d '\n')" > /dev/tty
```

If that fails too, print the artifact in a fenced code block and tell the
user to copy it manually.

## Rules

- Strip markdown fences and trailing newlines, copy raw content only
- Preserve internal newlines/indentation
- Never copy secrets without explicit request
- One-line confirmation only: `Copied to clipboard: <description>`
````

- [ ] **Step 2: Write `snippets/pb-rules.md`**

```markdown
## /pb — Paste Buffer

When the user says "/pb", "$pb", "copy that", "gimme that", "put it in my
paste buffer", or asks to copy something from the conversation, copy it to
their clipboard.

### Select

With args, interpret them freely: artifact type ("command"), description
("the AQL query"), ordinal ("2" = 2nd most recent), or fuzzy intent.
Prefer the most recent match. Without args, pick the most recent useful
artifact: query > shell command > code block > URL > config > plain text.

Ordered sequences: copy first-to-run, not last. If nothing plausibly
matches, say so — don't guess.

### Copy

Detect platform: `pbcopy` (macOS), `wl-copy` / `xclip -selection clipboard`
(Linux), `clip.exe` (WSL). Assign to `$CB`. Single-line:
`printf '%s' 'CONTENT' | $CB`. Escape `'` as `'\''`. Multi-line: heredoc
with `$CB <<'PBEOF'`. No binary? Try OSC52:
`printf '\033]52;c;%s\a' "$(printf '%s' "$CONTENT" | base64 | tr -d '\n')" > /dev/tty`.

### Rules

- Strip markdown fences and trailing newlines, copy raw content only
- Preserve internal newlines/indentation
- Never copy secrets without explicit request
- If no clipboard route works, print artifact in a fenced code block for manual copy
- One-line confirmation: `Copied to clipboard: <description>`
```

- [ ] **Step 3: Verify no stale name and OSC52 present in both**

```bash
grep -L "agent-pb" skills/pb/SKILL.md snippets/pb-rules.md && grep -lc ']52;c;' skills/pb/SKILL.md snippets/pb-rules.md
```

Expected: both files listed by `grep -L` (no agent-pb), both listed with count 1 for OSC52.

- [ ] **Step 4: Commit**

```bash
git add skills/pb/SKILL.md snippets/pb-rules.md
git commit -m "Improve pb skill: freer arg interpretation, OSC52 fallback, richer triggers"
```

---

### Task 5: Move site to docs/ and rewrite URLs/brand

**Files:**
- Move: `site/` → `docs/` (git mv, all 10 files)
- Modify (in place after move): `docs/index.html`, `docs/blog.html`, `docs/seashells-tour.html`, `docs/clipboard-lab-review.html`, `docs/sitemap.xml`, `docs/robots.txt`, `docs/*.md`, `docs/*.txt`

**Interfaces:**
- Produces: `docs/` tree served by GitHub Pages (Task 7 enables it). All URLs relative or pointing at `https://ashrocket.github.io/pb/...`.

- [ ] **Step 1: Move the directory**

```bash
git mv site docs
```

- [ ] **Step 2: Rewrite domain THEN brand (order matters — see Global Constraints)**

```bash
LC_ALL=C find docs -type f \( -name '*.html' -o -name '*.xml' -o -name '*.txt' -o -name '*.md' \) \
  -exec sed -i '' -e 's|agent-pb\.raiteri\.net|ashrocket.github.io/pb|g' -e 's|agent-pb|pb|g' {} +
```

- [ ] **Step 3: Fix root-absolute links (break under the /pb/ subpath)**

Three known instances (line numbers pre-move): `blog.html:169` `href="/"`, `blog.html:171` `href="/blog.html"`, `index.html:380` `href="/blog.html"`.

```bash
sed -i '' -e 's|href="/"|href="./"|g' -e 's|href="/blog.html"|href="blog.html"|g' docs/blog.html docs/index.html
```

- [ ] **Step 4: Verify no stale domains, brand, or root-absolute links remain**

```bash
grep -rn "agent-pb\|raiteri.net/sitemap\|pb\.raiteri\.net" docs/ ; grep -rnE 'href="/[^"]|src="/[^"]' docs/
```

Expected: no output from either grep (exit 1). Note `agent-look.raiteri.net` may legitimately appear — if it does, it is allowed; adjust the first grep to `grep -rn "agent-pb" docs/` plus `grep -rn "pb\.raiteri\.net" docs/` and require both empty.

- [ ] **Step 5: Spot-check the install commands rendered on the site**

```bash
grep -n "plugin marketplace add\|plugin install" docs/index.html
```

Expected: `/plugin marketplace add ashrocket/pb` and `/plugin install pb@pb`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Move site to docs/ for GitHub Pages; rebrand agent-pb -> pb; fix subpath links"
```

---

### Task 6: Rewrite README

**Files:**
- Modify: `README.md` (full replacement)

- [ ] **Step 1: Write `README.md`**

````markdown
# pb

Clipboard helper for AI coding agents. Say `/pb`.

Ask the agent to copy the thing you just produced — a query, shell command,
code block, URL, or config — and `pb` puts the artifact itself on your
clipboard. No selecting. No highlighting. No dragging.

```
/pb                    # copies the most recent useful artifact
/pb command            # copies the last shell command
/pb the AQL query      # describe it — the model figures out what you mean
/pb 2                  # 2nd most recent artifact
copy that              # natural language works too
```

## Install

### Claude Code (plugin)

```
/plugin marketplace add ashrocket/pb
/plugin install pb@pb
```

You get `/pb` as a slash command plus natural-language triggers
("copy that", "gimme that").

### Codex

Install the bundled skill into your Codex skills directory:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills/pb"
curl -sL https://raw.githubusercontent.com/ashrocket/pb/main/skills/pb/SKILL.md \
  -o "${CODEX_HOME:-$HOME/.codex}/skills/pb/SKILL.md"
```

In Codex, `$pb` is the explicit invocation; natural-language requests work
when the prompt matches the skill description.

### Cursor / Windsurf / Copilot

Append the portable snippet to your rules file:

```bash
curl -sL https://raw.githubusercontent.com/ashrocket/pb/main/snippets/pb-rules.md >> .cursorrules
```

Or paste [`snippets/pb-rules.md`](snippets/pb-rules.md) into
`.windsurfrules` or `.github/copilot-instructions.md`.

## How it picks

With an argument, the model interprets it — artifact type, description, or
ordinal. Without one, it takes the most recent useful artifact:
query > shell command > code block > URL > config > plain text.

Works on macOS (`pbcopy`), Linux (`xclip`/`wl-copy`), and WSL/Windows
(`clip.exe`), with an OSC52 escape-sequence fallback for SSH sessions.
Some hosts may ask approval before writing to the system clipboard.

## Site

https://ashrocket.github.io/pb/

## Also

- [agent-look](https://agent-look.raiteri.net) — screenshot scanner for
  Claude. Same philosophy: stop dragging things around.

## License

MIT
````

- [ ] **Step 2: Verify no stale references**

```bash
grep -n "agent-pb" README.md
```

Expected: no output (exit 1).

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Rewrite README for pb rename and /pb command"
```

---

### Task 7: Push and enable GitHub Pages

**Files:** none (remote config)

**Interfaces:**
- Consumes: `docs/` tree on `main` (Task 5), renamed repo (Task 1).
- Produces: live site at `https://ashrocket.github.io/pb/` — precondition for deleting Cloudflare (Task 8).

- [ ] **Step 1: Push main**

```bash
git push origin main
```

- [ ] **Step 2: Enable Pages from main:/docs**

```bash
gh api -X POST repos/ashrocket/pb/pages -f 'source[branch]=main' -f 'source[path]=/docs'
```

Expected: HTTP 201 with a JSON body containing `"html_url": "https://ashrocket.github.io/pb/"`. If it returns 409 (already enabled), run instead:

```bash
gh api -X PUT repos/ashrocket/pb/pages -f 'source[branch]=main' -f 'source[path]=/docs'
```

- [ ] **Step 3: Wait for the first build and verify 200**

```bash
for i in $(seq 1 12); do
  code=$(curl -s -o /dev/null -w '%{http_code}' https://ashrocket.github.io/pb/)
  echo "attempt $i: $code"; [ "$code" = "200" ] && break; sleep 15
done
```

Expected: reaches `200` within ~3 minutes (first Pages build). If still 404 after 12 attempts, check `gh api repos/ashrocket/pb/pages/builds/latest`.

---

### Task 8: Delete the Cloudflare Pages project, drop wrangler.toml

**Files:**
- Delete: `wrangler.toml`

- [ ] **Step 1: Confirm auth, then delete the Cloudflare project**

```bash
npx wrangler whoami && npx wrangler pages project delete agent-pb
```

Expected: confirmation of deletion. If the command prompts interactively and cannot proceed non-interactively, or auth fails, STOP and report: user should run `! npx wrangler pages project delete agent-pb` themselves. Do not retry blindly. Continue to Step 2 either way (the repo-side cleanup is independent).

- [ ] **Step 2: Remove wrangler.toml, commit, push**

```bash
git rm wrangler.toml
git commit -m "Remove Cloudflare Pages config; site now on GitHub Pages"
git push origin main
```

---

### Task 9: Final verification sweep

**Files:** none

- [ ] **Step 1: Whole-repo stale-reference grep (allowed: clipboard-lab/, specs/, .git)**

```bash
grep -rn "agent-pb" --exclude-dir=.git --exclude-dir=clipboard-lab --exclude-dir=specs . ; echo "exit=$?"
```

Expected: no matches, `exit=1`.

- [ ] **Step 2: Manifest + structure checks**

```bash
jq -e '.name=="pb"' .claude-plugin/plugin.json && jq -e '.plugins[0].name=="pb"' .claude-plugin/marketplace.json
ls commands/pb.md skills/pb/SKILL.md snippets/pb-rules.md docs/index.html
```

Expected: `true` twice, all four paths listed.

- [ ] **Step 3: Live checks**

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://ashrocket.github.io/pb/
curl -s -o /dev/null -w '%{http_code}\n' https://raw.githubusercontent.com/ashrocket/pb/main/skills/pb/SKILL.md
```

Expected: `200` and `200`.

- [ ] **Step 4: Report manual step to user**

The user must reinstall the plugin in a fresh session to pick up the rename:
`/plugin marketplace add ashrocket/pb` then `/plugin install pb@pb` (and remove the old `agent-pb` marketplace/plugin if present). Then test `/pb` and `/pb <hint>`.
