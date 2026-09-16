# 2.2 — Preview

- Fix retained SwiftUI text and segment bindings after deleting or reordering history entries. Bindings resolve recording and segment IDs instead of retaining array positions.
- Use value snapshots in detail panes and reset editor identity when switching recordings or UI language.
- English and Spanish interface with persistent selection.
- Independent selection of all audio locales supported by Apple on the current Mac.
- Explicit language download with cancellation; stale language checks cannot overwrite a newer selection.
- Whisper uses the transcript’s recorded language for subsequent comparison.
- Update icon using the image supplied for Vocalia.
- Ignore stale playback seek completions after pause or selection change.
- 48 synthetic checks, including deleted-history binding regressions and localization.
