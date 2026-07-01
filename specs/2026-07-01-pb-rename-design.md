# pb — rename and `/pb` command design

**Date:** 2026-07-01
**Status:** Approved

## Goal

Rename `agent-pb` to `pb` across the repo, plugin, and site; make `/pb` a first-class slash command in Claude Code that works with no arguments or with a free-form argument the LLM interprets; move the site from Cloudflare Pages (`agent-pb.raiteri.net`) to GitHub Pages; delete the Cloudflare project.

## Current state

- GitHub repo: `ashrocket/agent-pb` (local checkout already at `~/ashcode/pb`). `ashrocket/pb` is free.
- Plugin + marketplace both named `agent-pb` (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`).
- Clipboard behavior ships only as a skill (`skills/pb/SKILL.md`) — no `commands/` directory, so `/pb` is not a guaranteed slash command in Claude Code.
- Portable snippet at `snippets/pb-rules.md` for Cursor/Windsurf/Copilot.
- Static site in `site/`, deployed to Cloudflare Pages project `agent-pb` (see `wrangler.toml`), served at `agent-pb.raiteri.net`.
- `clipboard-lab/` is an unrelated experiment directory — untouched by this work.

## Design

### 1. Rename: repo, plugin, marketplace

- `gh repo rename pb` → `ashrocket/pb`. GitHub redirects the old URL, so existing marketplace installs pointing at `ashrocket/agent-pb` keep resolving.
- `plugin.json`: `name: "pb"`, `repository: "https://github.com/ashrocket/pb"`, `homepage: "https://ashrocket.github.io/pb/"`. Bump version to `0.2.0`.
- `marketplace.json`: marketplace name `pb`, plugin entry name `pb`, matching version.
- New install incantation: `/plugin marketplace add ashrocket/pb` then `/plugin install pb@pb`.

### 2. `/pb` slash command

Add `commands/pb.md` so `/pb` is an explicit slash command with `$ARGUMENTS`:

- `/pb` (no args): the LLM picks the most recent useful artifact from the conversation. Priority: query > shell command > code block > URL > config > plain text.
- `/pb <anything>`: the LLM interprets the argument to decide what to copy — artifact type ("command"), description ("the AQL query"), ordinal ("2" = 2nd most recent), or fuzzy intent ("that thing for prod").
- The command is thin: it states the invocation contract and defers selection/copy/safety rules to the skill content so there is one source of truth.

Keep `skills/pb/SKILL.md` for natural-language triggers ("copy that", "gimme that") and Codex portability (Codex consumes SKILL.md directly).

### 3. Skill improvements

- Clearer guidance for ambiguous arguments: prefer the most recent match; if nothing plausibly matches, say so rather than guessing.
- OSC52 escape-sequence fallback when no clipboard binary exists (SSH/remote sessions): emit `\e]52;c;<base64>\a` so the terminal sets the local clipboard; keep the fenced-code-block fallback as the last resort.
- Richer trigger description (mention `/pb`, `$pb`, "copy that", "put X in my paste buffer").
- Same safety rules as today: never copy secrets unasked, strip fences, preserve internal newlines, one-line confirmation.
- Mirror the same updates in `snippets/pb-rules.md`.

### 4. Site → GitHub Pages, Cloudflare removed

- Move `site/` → `docs/` (GitHub branch-based Pages only serves `/` or `/docs`).
- Enable Pages via `gh api`: source branch `main`, path `/docs`.
- Update all site content: `agent-pb.raiteri.net` → `https://ashrocket.github.io/pb/`; brand copy `agent-pb` → `pb`; fix `sitemap.xml`, `robots.txt`, canonical/OG tags, internal links.
- Delete Cloudflare Pages project `agent-pb` (`wrangler pages project delete agent-pb`); remove `wrangler.toml`. The `agent-pb.raiteri.net` subdomain stops resolving — accepted.

### 5. README

Rewrite for the new name: install commands (`pb@pb`), raw URLs (`raw.githubusercontent.com/ashrocket/pb/...`), usage examples showing `/pb` and `/pb <arg>`, GitHub Pages site link.

## Rejected alternatives

- **Skill-only (no `commands/pb.md`)** — `/pb` resolution via skill invocation is less guaranteed across hosts and argument handling is implicit.
- **GitHub Actions Pages deploy** — more machinery than branch `/docs` serving for a static folder.
- **Repo-only rename** — leaves the plugin namespaced `agent-pb`, defeating the clean `/pb` goal.

## Error handling

- `gh repo rename` or Pages API failure: stop and report; nothing else depends silently on it.
- `wrangler` unauthenticated: report the exact command for the user to run (`npx wrangler pages project delete agent-pb`); everything else proceeds.
- Clipboard fallback chain in the skill: binary → OSC52 → fenced block for manual copy.

## Testing / verification

- `plugin.json` / `marketplace.json` parse as valid JSON; names consistent (`pb@pb`).
- No stale `agent-pb` references outside `clipboard-lab/` and git history (grep sweep).
- GitHub Pages returns 200 for `https://ashrocket.github.io/pb/` after enabling.
- `/pb` and `/pb <arg>` invoke correctly in a fresh Claude Code session after reinstall.
