# Vocalia 0.0.6 — local validation

Status: preview candidate. Publication is gated on both native GitHub build jobs. No installed user application was changed.

## Completed on an Apple Silicon Mac

- Release build of the native Mac app, ad-hoc code signature verification, existing transcript/history/import/Word/update checks.
- New audio checks: word and decimal timestamps, ambiguous edits, precise selection bounds, 48 kHz stereo to 16 kHz mono without duration drift, reduced low-frequency rumble, preserved voice band, bounded gain, no clipping, unchanged source bytes and old-history decoding.
- 56 Python unit tests, including real Qt mouse clicks, edit-mode toggle, loop boundary/pause/end handling and cleanup worker integration.
- Offscreen GUI smoke tests, six interface languages, existing history/update dialogs and exports. Screenshots inspected for layout.
- Real local transcription through the Windows engine code with a public English speech fixture, using the tiny model: FLAC, MP3, MP4, MOV, OPUS and OGG; malformed audio rejected without terminating the editor.
- Mac update-package test checks checksum, extraction, signature, replacement, backup and preservation of separate history in an isolated directory. It never replaces a user's installed app.

## Remaining before release

- Run the committed GitHub workflow on Windows 11 x64 and macOS 26; it builds both packages and tests Windows installation/upgrade/uninstall.
- Exercise native playback on Windows hardware. Offscreen Qt tests on Mac do not establish Windows hardware compatibility.
- Evaluate recognition on representative Chilean Spanish interviews with verified reference transcripts. The optional large-v3 model has not been benchmarked in this update; no measured accuracy improvement is claimed.
- Publish only after both platform jobs pass. The workflow publishes a preview from main only.

## Scope

Cleanup reduces low-frequency rumble and adjusts overall level by at most 6 dB of boost. It does not remove conversations, repair clipping, or shorten silences. It can make some recordings worse; compare with the original. Processing is local and original recordings remain untouched.

Exact word seeking requires recognition timestamps and unchanged, unambiguous text. Unsupported edited spans show a message instead of inventing timing. Speaker separation remains manual; importing still starts ordinary transcription automatically.
