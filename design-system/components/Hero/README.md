The landing page first screen for pb: the header bar with the "pb" wordmark, then the butter gradient hero with the headline, lede and two buttons.

**When to use:** to show how the pb landing page opens, in a brand book or a component gallery.

**What the consumer supplies:** nothing. The copy is the real landing copy (docs/index.html:389-396). Change the text only when the landing page changes.

**Anatomy:** header (butter pat, wordmark, four links), hero (gradient from `--hero-start` to `--hero-end` at 135deg, headline 3rem weight 800, lede 1.25rem, primary button with `--btn-primary-bg`, secondary button with `--btn-secondary-bg`). Source lines: docs/index.html:25-98.

**Do:**
- Keep the headline and lede in the landing wording.
- Keep the 700px breakpoint, which drops the headline to 2rem (docs/index.html:363-364).

**Do not:**
- Do not put the 🧈 emoji decoration back in. It was left out on purpose (docs/index.html:62-69). See README.md Status item 3.
- Do not set the hero text back to #FFFFFF. On the gradient it is 2.17:1 and 2.60:1, which fails 4.5:1. The preview uses `--hero-text` (#2A1F08, 7.46:1 and 6.22:1). See README.md Status item 6.
