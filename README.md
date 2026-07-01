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
