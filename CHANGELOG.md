## New in 1.0.1

- Choose English or Spanish before entering the workspace on first launch. Change the app language later inside Vocalia.
- A replayable tutorial explains adding recordings, preparing a model, transcribing, reviewing and copying the full text.
- Windows: **adding a recording does not transcribe it**. Click **Transcribe pending**. If the model is missing, accept its download; transcription then starts automatically.
- Clear empty-queue, missing-model and worker-failure messages. Playback stops when transcription is requested and is unavailable while a job is running.

# Release notes

## 1.0 — first unified public release

- One Mac/Windows Release with direct downloads and bilingual installation guides.
- Official Apple first-launch instructions.
- Public version 1.0; existing history and preferences retained.
- Windows: system-aware initial language, screen-aware window size, clearer errors and saved revisions before retrying.

[Español](CHANGELOG.es.md)

## Mac 2.2.1 / Windows 0.1.1 preview

- Replace oversized rectangular logo margins with a clean, rounded application icon, with native macOS and Windows size variants.
- Make English the primary repository language, with separate Spanish documentation.
- Include English-first Windows package instructions and updated download guidance.
- Recognition engines and existing user histories are unchanged by this branding/documentation update.

## Windows 0.1.0 preview

- Local CPU Whisper recognition in a separate worker process.
- Multiple-file import, full text, playback highlighting, quotes and TXT/SRT/VTT export.
- Transactional SQLite history with recoverable removal and ID-based editing.
- Packaged Windows regression tests: history, interrupted workers, Unicode paths, corrupt audio and offline FLAC/MP3/MP4/MOV recognition.
- Fix Windows file locking when a damaged history cannot be opened; read JSON consistently as UTF-8.

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

## OPUS support in 1.0.1

Use the downloads with **OPUS** in their filename. Both platforms accept `.opus` and Ogg files containing Opus (`.ogg`), including batch/folder import. No manual conversion or audio upload is needed. Windows uses its bundled decoder. Mac includes a local BSD-licensed Opus decoder and uses a temporary PCM copy for transcription and playback; normal app exit removes that copy and the original is preserved. Mac OPUS recordings must be under ten hours; Windows keeps its two-hour limit. Ogg/Vorbis is not included.

New downloads have checksums in **SHA256SUMS-GuideFix.txt**; the original 1.0.1 files remain available for reproducibility. The updated source is on the main branch and in **Vocalia-1.0.1-GuideFix-source.zip** in Releases. The tag's automatic Source code archives describe the original 1.0.1 build.
