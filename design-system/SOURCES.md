# Sources

Every file read to build this system, and what came from it. Paths are relative to the project root (the `pb` repo), except `../design-systems/`, which is the ashcode folder beside it.

| File | Lines read | What came from it |
|---|---|---|
| ../design-systems/profiles/pb.json | whole file | Surfaces, palette candidates, classification, v2 case |
| ../design-systems/SPEC.md | whole file | Folder layout, tokens grammar, preview contract, build rules |
| ../design-systems/evidence/pb.json (via extract/digest.py) | digest output | Scan of 60 files: colours, fonts, custom properties. Used to find candidates; each value was then checked in the source |
| docs/index.html | 1-140, 376-400, 405-421, 433-459, 514-545, 549, 566 read; rules at 19-197 confirmed line by line | Landing palette, type, header, hero copy, anatomy |
| docs/clipboard-lab-review.html | 1-30, 45 | Page-specific dark palette (Drift only) |
| docs/seashells-tour.html | 15-40, 118 | Page-specific sea and sand palette and fonts (Drift only) |
| docs/blog.html | digest only | Confirms landing values appear on the blog page; not reopened |
| README.md (project root) | 1-12 | Product description and the "No selecting. No highlighting. No dragging." line |
| specs/2026-07-01-pb-rename-design.md | grep for hex values and font names | No colour or font rules found. Not used for values |

Files not used: `.git`, `.wrangler`, `.superpowers`, `commands/`, `skills/`, `snippets/`, `clipboard-lab/`, `.claude-plugin/`, `docs/*.md`, `docs/*.txt`, `docs/sitemap.xml`, `docs/robots.txt`. No secrets, env files or personal data were read or copied.

Derived by hand: contrast ratios in README.md (WCAG 2.x formula on the hex values). Line-height px values in tokens.json are the source unitless value times the source font size.
