# Two tiny tools for the dumb parts of AI coding

There are probably a million reasons why I shouldn't have built these. If you know any, I'd love to hear them.

---

I use AI coding agents constantly. Claude, mostly. And I keep noticing the same pattern: the agent does something genuinely smart — writes a query, generates a function, debugs a failing test — and then I have to do something genuinely stupid to use the result.

Drag a screenshot file. Select text carefully around markdown fences. Copy. Switch to my terminal. Paste.

The agent has shell access. It can see my filesystem. Why am I the one doing the manual labor?

So over the past few weeks I built two small tools that eliminate the two most common friction points.

---

## agent-look: stop dragging screenshots

The first one solves the screenshot problem.

I take a lot of screenshots while working — error messages, UI bugs, terminal output, browser states. Every time, the workflow was: take screenshot, minimise what I'm looking at, find the file (usually named something like `Screenshot 2026-03-23 at 2.15.32 PM.png`), drag it into Claude, then explain what I was even looking at.

**agent-look** is an MCP server that watches your screenshots folder. Say `/look` and it pulls up whatever you've captured in the last few minutes. It auto-renames the generic filenames based on what's in the image and asks if you want to use any of them.

The fun technical detail: the first version dispatched a vision subagent for every screenshot — about 13,000 tokens each. Five screenshots burned 65k tokens just to categorise some PNGs. Then I discovered macOS already OCRs your screen captures via Spotlight. The text is sitting right there in `kMDItemTextContent`. Now it reads the OCR text (cheap text tokens), generates a slug, and renames. The vision subagent only fires when OCR comes up empty — pure graphics, charts with no text. Most screenshots have text on them. The examiner rarely fires.

[agent-look.raiteri.net](https://agent-look.raiteri.net) | [GitHub](https://github.com/ashrocket/agent-look)

---

## pb: stop selecting and copying

The second one solves the clipboard problem.

Dozens of times a day: Claude writes a query, or a curl command, or a code block. Then I have to select the text — carefully, because the markdown fences aren't part of it — copy it, switch to my terminal, and paste.

**pb** is a clipboard butter knife. Say `/pb` and the agent finds the most recent useful artifact in your conversation — a query, shell command, code block, URL, config — and spreads it right into your clipboard. No selecting. No highlighting. You just paste.

The name works on two levels: `pb` is the macOS clipboard command (`pbcopy`/`pbpaste`), but it's also how the tool feels. You're not carefully cutting and placing — you're just spreading it where it needs to go, like butter on toast.

[ashrocket.github.io/pb](https://ashrocket.github.io/pb) | [GitHub](https://github.com/ashrocket/pb)

---

## Same philosophy, portable design

Both tools are Claude Code plugins, but neither requires Claude. The core of each is just a prompt and a shell command. The repos include portable snippets you can drop into `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, or whatever your agent reads. Same tools, different agents.

Cross-platform too: macOS, Linux, WSL. Auto-detects.

I'm calling them the **agent-\*** family. The philosophy is simple: stop moving things around manually. Let the agent handle the boring mechanical parts so you can stay in flow. The agent is already there, already has shell access — let it do the grunt work.

---

Both are MIT licensed. If something's broken, [file an issue](https://github.com/ashrocket/pb/issues). If it works perfectly, I will accept quiet gratitude.