# Threat Model

## Goal
Raise the floor for at-rest privacy compared with a plaintext clipboard manager
while keeping the app local-only, fast enough for daily use, and operationally
small.

This iteration explicitly closes the earlier plaintext-search-index gap. The
database should no longer contain clipboard cleartext purely for searchability.

## Assets
- clipboard text payloads
- clipboard image payloads
- OCR-derived text from image clips
- source-app metadata and timestamps
- encryption/search key material
- queryable search index entries

## Trust Boundary
- Trusted:
  - the logged-in user session
  - the app process while it is running
  - the macOS Keychain for secret storage
- Not trusted:
  - the SQLite file by itself
  - other local processes without the user session context
  - future forensic access to files after app exit

## Enforced Controls
- App support directory: `0700`
- SQLite file: `0600`
- Clipboard payloads encrypted before `INSERT`
- OCR text encrypted before storage
- Search terms stored only as HMAC digests of normalized token prefixes
- Concealed/transient pasteboard types skipped
- Local-only operation; no telemetry or cloud sync

## Encryption Design
- Payload encryption uses `AES.GCM` from `CryptoKit`.
- The app stores two Keychain-backed random values:
  - `payload-passphrase` (`32` random bytes)
  - `payload-salt` (`16` random bytes)
- Two runtime keys are derived with `HKDF<SHA256>`:
  - payload key via context string `clip-05 payload encryption`
  - search key via context string `clip-05 search index`
- Payload ciphertext format:
  - byte `0`: version marker `1`
  - remaining bytes: `AES.GCM.SealedBox.combined`

This separation keeps the search HMAC key distinct from the payload encryption
key even though both come from the same passphrase/salt root material.

## Key Management Lifecycle
### Creation
- On first use, the app generates random passphrase/salt material with
  `SecRandomCopyBytes`.
- It stores those values in the Keychain as generic-password items with
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.

### Storage
- Key material is never written to `history.sqlite` or `config.toml`.
- The database stores ciphertext, HMAC search digests, and non-secret metadata.

### Use
- Keys are derived in-process when needed.
- Decrypted plaintext exists only transiently while:
  - rendering a selected clip
  - re-copying a clip to the pasteboard
  - running OCR insertion/update flows

### Rotation
- No automatic key rotation exists in this iteration.
- Correct rotation would require decrypting every stored row and re-encrypting
  it with newly derived keys, then rebuilding the HMAC search index.

### Loss
- If Keychain material is deleted or becomes inaccessible while the database
  remains, existing encrypted rows become unreadable.
- There is no recovery path because no plaintext backup is retained.

## Encrypted Search Design
`clip-05` uses encrypted token-prefix search instead of a plaintext
`searchable_text` column.

Pipeline:
- normalize input with case/diacritic folding
- tokenize into alphanumeric terms
- derive all prefixes up to length `24` for each token
- HMAC each prefix with the derived search key
- store only the HMAC digests in `search_terms`

Query behavior:
- user text is normalized and tokenized the same way
- each query term becomes an HMAC lookup
- all terms are combined with `AND`

Security win:
- the database no longer holds raw searchable text for text clips or OCR data

Trade-off:
- this supports token-prefix match, not arbitrary infix substring match
- `port` can match `portal`
- `rtal` cannot match `portal`

Why this design was chosen:
- it removes the most obvious plaintext leak from iter-4
- it keeps search responsive without decrypting every row on every keystroke
- it is a better blind-review story than a decrypt-and-scan fallback

## OCR Data Handling
- OCR runs on-device through `Vision` using `VNRecognizeTextRequest`.
- No OCR text is sent to a server.
- Recognized text is encrypted before it is stored in `metadata_payload`.
- OCR searchability comes from the same HMAC prefix-index pipeline used for text
  clips.
- OCR completes asynchronously, so a new image can appear before its recognized
  text is indexed.

## Memory Residency
- At-rest encryption does not prevent plaintext from appearing in memory.
- The app decrypts payloads when a row is fetched for display or reuse.
- Image decode and preview generation necessarily materialize image bytes in
  process memory.
- OCR handling also places image bytes and recognized strings in memory
  temporarily.

This build protects the database better than iter-4, but it does not claim
defense against a same-user live-memory attacker.

## Pasteboard Type Exclusions
The poller skips:
- `org.nspasteboard.ConcealedType`
- `org.nspasteboard.TransientType`

It also supports explicit app-level exclusions through `excluded_bundle_ids`,
which is the primary user-facing control for password managers and sensitive
tools that should never be recorded.

## File Permission Enforcement
- The app creates `~/Library/Application Support/clip-05/` and forces `0700`.
- It creates `history.sqlite` and forces `0600`.
- If permissions do not match the expected SQLite mode, store initialization
  fails rather than continuing silently.

## What Is Not Protected
- plaintext present in the live pasteboard while another app owns it
- plaintext in process memory while the app is rendering, decoding, or copying
- plaintext shown on screen in the history/preview UI
- non-secret metadata:
  - timestamps
  - source bundle identifiers
  - clip kind
  - byte counts
  - image dimensions
- root attackers or a fully compromised logged-in user session
- secure deletion / disk forensics after files have existed on disk

These are not protected because the app is intentionally lightweight and local,
and because full protection in those areas would require a very different
product shape with tighter OS integration and far more complexity.

## Residual Risk Summary
- A logged-in attacker acting as the same user can still reach the Keychain and
  inspect the running process.
- Search leaks token equality/prefix equality through repeated HMAC values,
  though not raw token content without the search key.
- OCR increases the amount of sensitive text the app may store for image clips,
  even though that text is encrypted at rest.
- There is no key rotation or secure wipe path in this iteration.

## Out Of Scope
- secure deletion guarantees
- forensic resistance after disk writes
- root-level compromise
- cloud sync and multi-device trust
- anti-screenshot/anti-shoulder-surfing controls
- full password-manager-style process isolation
