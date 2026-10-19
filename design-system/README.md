# pb design system

pb is a clipboard helper for AI coding agents. It copies the last useful artifact, such as a command, query or code block, to the system clipboard when the reader says `/pb` or "copy that". The job of the landing page (docs/index.html) is to get the reader to install pb in about one minute, then stop selecting text by hand.

## Voice

1. Say what the reader does, in one short sentence. Example: "Stop selecting and copying text from your AI agent." (docs/index.html:390)
2. Name the reader's own artifacts. Example: "You wrote a query. A curl command. A code block." (docs/index.html:391)
3. Show the exact command in code style. Example: "In Codex, say **$pb**. In other hosts, use **/pb**." (docs/index.html:391)
4. Use plain verbs and no marketing words. Example: "No selecting. No highlighting. No dragging." (project README.md:7)
5. Name the real host tools. Example: "pb is a Claude Code plugin with a first-class `/pb` command." (docs/index.html:435)

## Colour

Source: docs/index.html:19-197 (landing palette). One theme: `landing`. Values are exact. Ratios are WCAG 2.x, computed from the hex values.

| Token | Value | Role | Ground and ratio |
|---|---|---|---|
| page-bg | #8B6914 | Page background | Ground for body text |
| header-bg | #6B4F10 | Header bar | Ground for wordmark (7.63:1) and nav |
| header-rule | #4A370B | Header bottom border | Decorative |
| butter | #FFD966 | Butter pat (shape, not text) | On header-bg 5.59:1 if used as text |
| eyebrow-text | #FFF3D4 | Eyebrow text, 0.75rem uppercase | On page-bg 4.61:1 (pass) |
| wordmark | #FFFFFF | Plain-text "pb" | On header-bg 7.63:1 (pass) |
| nav-link | #FFD966 | Header links | On header-bg 5.59:1 (pass) |
| hero-start | #E8A317 | Hero gradient start | Ground for hero-text |
| hero-end | #D4942A | Hero gradient end | Ground for hero-text |
| hero-text | #2A1F08 | Hero headline and lede | On hero-start 7.46:1, on hero-end 6.22:1 (pass) |
| body-text | #FFF3D4 | Section headings and body | On page-bg 4.61:1 (pass). On code-bg 14.66:1 |
| btn-primary-bg | #FFFFFF | Primary button fill | Ground for btn-primary-text |
| btn-primary-text | #8B6914 | Primary button label | On btn-primary-bg 5.09:1 (pass at 15.2px, weight 600) |
| btn-secondary-bg | rgba(255,255,255,0.15) | Secondary button fill | Over hero gradient |
| btn-secondary-border | rgba(255,255,255,0.4) | Secondary button border | Over hero gradient |
| panel-bg | rgba(255,255,255,0.07) | Step and feature cards | Over page-bg |
| code-bg | #2A1F08 | Code block | Ground for code-text 12.99:1 |
| code-text | #FFE4A0 | Code block text | On code-bg 12.99:1 (pass) |

Every usage-named text pair passes 4.5:1 (checked with contrast.py). Values that differ from the landing page are listed in Status and Drift.

## Type

- Body and UI: `system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif` (docs/index.html:18). No web font is loaded. The OS supplies the face.
- Code: `"SF Mono", "Fira Code", monospace` (docs/index.html:195). No web font is loaded.

Scale (source values; line-height converted from unitless to px where the source gives a unit-less value):

| Style | Size | Weight | Line height | Use | Source |
|---|---|---|---|---|---|
| wordmark | 1.6rem | 700 | normal | Header "pb" | docs/index.html:41-43 |
| hero-headline | 3rem | 800 | 52.8px (1.1) | Hero headline | docs/index.html:72-74 |
| hero-lede | 1.25rem | 400 | 32px (1.6) | Hero lede | docs/index.html:80-83 |
| nav-link | 0.9rem | 400 | normal | Header links | docs/index.html:51 |
| btn | 0.95rem | 600 | normal | Buttons | docs/index.html:91-92 |
| eyebrow | 0.75rem, uppercase, tracking 2px | 700 | normal | Section label | docs/index.html:123-129 |
| code-block | 0.9rem | 400 | normal | Code | docs/index.html:196 |

Google Fonts: none. The landing page loads none. Page-specific fonts (Fraunces, Manrope) are not part of this system. See Drift.

## Layout and spacing

- Page side padding: 48px (header and hero, docs/index.html:28, :58).
- Header padding: 28px vertical (docs/index.html:28). Header bottom border: 6px (docs/index.html:27).
- Hero padding: 72px top, 64px bottom (docs/index.html:58).
- Hero headline max width 640px (docs/index.html:75). Hero lede max width 560px (docs/index.html:82).
- Section max width 880px (docs/index.html:121).
- Gaps: header 16px, header links 24px, hero buttons 12px (docs/index.html:31, :47, :86).
- Breakpoint: 700px. Below it the hero headline drops to 2rem (docs/index.html:363-364).
- Radii: 3px (butter pat), 6px (buttons), 10px (cards), 8px (code). docs/index.html:36, :90, :142, :193.
- Shadow: butter pat only, 0 2px 4px rgba(0,0,0,0.2) (docs/index.html:38).

## Logo and wordmark

There is no logo file in the project. Nothing was copied. The wordmark is plain type:

- Text: `pb`, lowercase, no other mark.
- Family: system-ui stack (see Type). Weight 700. Size 1.6rem. Tracking -0.5px (docs/index.html:41-43).
- Colour: #FFFFFF on header-bg #6B4F10 (docs/index.html:46). Header h1 #FFE4A0 at docs/index.html:44 is overridden.
- The butter pat is a CSS shape (22 by 16px, 3px radius, rotated -4deg, docs/index.html:33-38). It is not an image. It sits left of the wordmark with 16px gap.
- Clear space: at least the height of the butter pat (16px) on every side.
- Minimum size: 1.6rem text height. Do not go below the landing size.
- Do not: add a new mark, set the wordmark in a display face, put it on the hero gradient in white (see Status), or add a second butter pat.

## Landing page anatomy

In order (docs/index.html):

1. Header bar: butter pat, "pb" wordmark, four links (Blog, GitHub, agent-look, File an issue). Tokens: header-bg, header-rule, wordmark, nav-link. Lines 25-52, 376-386.
2. Hero: gradient hero-start to hero-end at 135deg, headline, lede with the `$pb`, `/pb` and "copy that" commands, two buttons (primary "Get it on GitHub", secondary "Install in 1 minute"). Lines 56-98, 389-396. The Hero component reproduces this screen.
3. Toast strip: eight small butter bars on header-rule. Decorative. Line 113 (radius).
4. "How it works" section: eyebrow, headline "Copy the artifact. Skip the selection.", three steps. Lines 405-421.
5. "Works everywhere" section: host list (Claude Code, Codex, Cursor, Windsurf, Copilot). Lines 433-459.
6. "What it actually does" section. Line 472-473.
7. Install section: Claude Code, Codex, Cursor / Windsurf / Copilot. Lines 514-545.
8. "Also by" section. Line 549. Not reproduced here.
9. Footer with three butter pats. Lines 348-356, 566.

## Status

v2. Source: docs/index.html (landing palette and type), scoped by owner decision.

Changes from the canonical surface (old value, the file:line it replaces, and why):

1. Scope: the landing tokens are the system for all new pages. Replaces: no prior system. The dark clipboard-lab palette (docs/clipboard-lab-review.html:10-17) and the sea and sand seashells palette (docs/seashells-tour.html:18-30) are page-specific and are not adopted. Why: owner decision, 2026-10-18.
2. Fonts: Fraunces and Manrope (docs/seashells-tour.html:15, :36, :118) and the clipboard-lab font stacks (docs/clipboard-lab-review.html:23, :45) are not adopted. Why: page-specific, per the owner decision in item 1.
3. Hero decoration: the 🧈 emoji pseudo-element (docs/index.html:62-69, opacity 0.18) is left out of the Hero component. Why: emoji decoration is not used in new design-system work (SPEC "Avoid generic tells").
4. Units: unitless line heights (docs/index.html:74 `1.1`, :83 `1.6`) are written as px (52.8px, 32px) in tokens.json. Values are the same. Why: the tokens grammar takes lengths only.
5. Wordmark: plain text "pb" at docs/index.html:41-46 is kept as is. No change.

6. Hero text: #FFFFFF becomes #2A1F08 (the code-bg value) on hero-start and hero-end. Replaces #FFFFFF at docs/index.html:77, :81. Why: white gave 2.17:1 and 2.60:1, below 4.5:1 for the 20px lede. #2A1F08 gives 7.46:1 and 6.22:1.
7. Primary button label: #A67C00 becomes #8B6914 (the page-bg value) on #FFFFFF. Replaces docs/index.html:97. Why: #A67C00 gave 3.82:1, below 4.5:1. #8B6914 gives 5.09:1.
8. Header nav links: #D4B456 becomes #FFD966 (the butter value) on #6B4F10. Replaces docs/index.html:49. Why: #D4B456 gave 3.80:1, below 4.5:1. #FFD966 gives 5.59:1.
9. Eyebrow text: new token eyebrow-text, #FFF3D4 on page-bg, 4.61:1. Replaces butter as eyebrow text (docs/index.html:127). Butter stays as the pat mark. Why: butter on page-bg gave 3.72:1 at 12px, below 4.5:1.

Open items: none for contrast. All usage-named text pairs pass 4.5:1. The landing page still uses the old values (see Drift).

## Drift

Values on other surfaces that differ from this system (path:line):

| Surface | Path:line | Value | Differs from system |
|---|---|---|---|
| Clipboard-lab review | docs/clipboard-lab-review.html:10 | --bg #0f0f11 | Dark page background; system page-bg is #8B6914 |
| Clipboard-lab review | docs/clipboard-lab-review.html:11 | --fg #e8e6e3 | Not in system |
| Clipboard-lab review | docs/clipboard-lab-review.html:13 | --accent #d4a843 | Not in system |
| Clipboard-lab review | docs/clipboard-lab-review.html:14-15 | --ours #5dade2, --existing #95a5a6 | Not in system |
| Clipboard-lab review | docs/clipboard-lab-review.html:16-17 | --border #26252a, --card #18171c | Not in system |
| Clipboard-lab review | docs/clipboard-lab-review.html:12 | --muted #8a8680 | Not in system |
| Clipboard-lab review | docs/clipboard-lab-review.html:23 | ui-sans-serif stack | Differs from system-ui stack |
| Clipboard-lab review | docs/clipboard-lab-review.html:45 | ui-monospace, SFMono-Regular, Menlo stack | Differs from SF Mono stack |
| Seashells tour | docs/seashells-tour.html:15 | Fraunces (Google Fonts) | Not in system |
| Seashells tour | docs/seashells-tour.html:36 | Manrope, system-ui | Not in system |
| Seashells tour | docs/seashells-tour.html:118 | "Fraunces", serif | Not in system |
| Seashells tour | docs/seashells-tour.html:18-19 | --sand #f5ead7, --cream #fff9ef | Not in system |
| Seashells tour | docs/seashells-tour.html:20-21 | --shell #ffe3c0, --foam #d8f2ef | Not in system |
| Seashells tour | docs/seashells-tour.html:22-23 | --sea #1f6370, --deep #0d3742 | Not in system |
| Seashells tour | docs/seashells-tour.html:24-26 | --coral #e46a4c, --gold #d7a94b, --ink #17313a | Not in system |
| Landing (not tokenised) | docs/index.html:160 | #E8C87A | Not in system |
| Landing (not tokenised) | docs/index.html:202 | #B89850 | Not in system |
| Landing | docs/index.html:77, :81 | hero text #FFFFFF | System hero-text is #2A1F08 (Status 6) |
| Landing | docs/index.html:97 | button label #A67C00 | System btn-primary-text is #8B6914 (Status 7) |
| Landing | docs/index.html:49 | nav link #D4B456 | System nav-link is #FFD966 (Status 8) |
| Landing | docs/index.html:127 | eyebrow text #FFD966 (butter) | System eyebrow-text is #FFF3D4 (Status 9) |

Confirmed, not drift: docs/blog.html uses the same landing values (#8b6914 at blog.html:19, #ffd966 at blog.html:35, #6b4f10 at blog.html:26). Those are digest results; the lines were not reopened.

## Components

- `components/Hero/` — the landing first screen (see its README).
- `components/Cover/` — the cover card.
