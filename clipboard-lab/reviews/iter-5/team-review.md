# Team Review

## Security reviewer
Compared with Maccy, Clipy, and Flycut, `clip-05` now has the strongest
publicly inspectable at-rest story in the whole lab set: encrypted payloads,
encrypted OCR metadata, HMAC-based search terms, and an explicit threat model.
It is now ahead of `clip-04` by removing the plaintext search leak entirely.
Compared with Alfred and Paste/Pastebot, `clip-05` is more transparent about
its storage model because the implementation is local and reviewable, but it
still trails mature commercial tools in OS integration hardening and battle
testing. Compared with Raycast, the story is narrower but more inspectable:
Raycast publicly promises encrypted local storage and password-manager respect,
while `clip-05` can show exactly how its database and Keychain design work.
The main remaining security weakness is unchanged in class even if reduced in
scope: same-user live-memory exposure and plaintext metadata are still in play.

## UX reviewer
Compared with Flycut and Clipy, `clip-05` is now much more modern. The split
history/preview layout, thumbnails, material background, and hover/arrow-key
selection feel closer to Paste's visual polish than to older menu-only tools.
Compared with Maccy, the UI is richer and more discoverable for image-heavy
history, though Maccy still feels leaner and more instantly minimal. Compared
with Raycast and Alfred, `clip-05` is still a single-purpose app rather than a
full productivity shell, but that focus helps it avoid the “clipboard buried
inside a launcher” feeling. Paste still likely wins pure visual delight, and
Pastebot still wins in “history as workflow surface” because of filters,
sequential paste, and custom pasteboards.

## Performance reviewer
Compared with `clip-04`, this is a better-shaped runtime: search is debounced,
rows are paged in 20 at a time, image decode is backgrounded, and startup
defers non-critical work until after the menu item appears. The encrypted HMAC
index is also the right performance choice; it avoids the decrypt-and-scan
fallback that would have become the obvious scaling weak point. Compared with
Raycast and Alfred, `clip-05` should still benefit from tighter scope and a
smaller process model. Compared with Maccy, it now does more work per clip
because of encryption, OCR hooks, and richer UI, so Maccy may still have the
edge on absolute lightness. OCR is the main new performance risk, but it is
correctly off the main thread and only paid for image clips.

## Power-user reviewer
Compared with Maccy, Flycut, and Clipy, `clip-05` has the best focused query
surface in the lab: `type:`, `app:`, `after:`, `encrypted:`, and image alias
search compose cleanly and now also reach OCR text. Compared with Paste, it
still lacks Pinboards and cross-device sync. Compared with Pastebot, it still
lacks the killer “act on clipboard data” layer: filters, shell-backed custom
actions, sequential paste, and durable custom pasteboards. Compared with Alfred
and Raycast, it still lacks snippets, actions, workflow ecosystems, and the
broader automation story. As a pure local clipboard-history tool it is now
competitive; as a power-user clipboard platform it still trails the commercial
leaders.
