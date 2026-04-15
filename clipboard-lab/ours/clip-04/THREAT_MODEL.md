# Threat Model

## Goal
Reduce casual same-user disclosure compared with plaintext-at-rest clipboard
history while keeping the app local-only and lightweight.

## Assets
- Clipboard text and image payloads
- Clip metadata: timestamps, source bundle IDs, kinds, byte counts
- Search index data in `searchable_text`
- Key material used to encrypt/decrypt clip payloads

## Enforced Controls
- Store path is `~/Library/Application Support/clip-04/history.sqlite`.
- The app support directory is forced to `0700`.
- The SQLite file is forced to `0600`.
- Clipboard payloads are encrypted before `INSERT` and decrypted after
  `SELECT`.
- Concealed and transient pasteboard types are skipped.
- The app does not perform network requests or telemetry.

## Encryption Design
- Payload encryption uses `CryptoKit` `AES.GCM`.
- The AES key is not stored directly in SQLite.
- Instead, the app keeps two random secrets in the macOS Keychain via
  `Security.framework`:
  - `payload-passphrase` (32 random bytes)
  - `payload-salt` (16 random bytes)
- On launch or first encryption/decryption use, the app reads those values from
  the Keychain. If either one is missing, it creates a new random value and
  stores it in the Keychain.
- The runtime AES key is derived with `HKDF<SHA256>` from the passphrase plus
  salt and app-specific context string `clip-04 payload encryption`.
- The ciphertext stored in SQLite is a versioned blob:
  - byte 0: version marker (`1`)
  - remaining bytes: `AES.GCM.SealedBox.combined`

## Key Management Lifecycle
- Creation:
  - First launch generates a random passphrase and salt with
    `SecRandomCopyBytes`.
  - Both values are written to the Keychain as generic-password items.
- Storage:
  - Key material lives in the Keychain, not in the SQLite file or config file.
  - The database only stores ciphertext plus non-secret metadata.
- Use:
  - The derived AES key exists in process memory only while the app is running.
  - Payload plaintext is materialized only long enough to display or paste a
    clip.
- Rotation:
  - No automatic re-encryption rotation is implemented in this iteration.
  - Safe rotation would require decrypting existing rows with the old key and
    rewriting them with new ciphertext.
- Loss scenario:
  - If the Keychain entries are deleted or inaccessible while the database
    remains, existing ciphertext rows become unreadable.
  - The app will fail to decrypt those rows; there is no recovery path because
    no plaintext backup is kept.

## Residual Risks
- `searchable_text` remains plaintext to preserve substring search. This leaks
  copied text content into the database index even though the canonical payload
  column is encrypted.
- Timestamps, source app bundle IDs, kinds, and payload byte counts remain
  plaintext metadata.
- A fully compromised same-user session can still read decrypted clips from the
  running process or the user’s Keychain if the OS session itself is unlocked.
- Pasteboard polling still observes clipboard changes by design; this build
  reduces stored disclosure, not runtime observation.

## Out Of Scope
- Secure deletion or filesystem forensics resistance
- Protection against a root attacker or a fully compromised logged-in user
- Cross-device sync, telemetry, or update delivery
- Automatic key rotation tooling
