# Vocalia for Mac — user guide

[Installation and macOS security prompts](INSTALL-MAC.md)

[English overview](README.md) · [Español](GUIA.md) · [Windows guide](WINDOWS.md)

## Install and choose languages

Requires Apple Silicon and macOS 26 or later. Extract the Mac ZIP and move Vocalia.app to Applications. This release is locally signed and not notarized. If macOS blocks it, consult [Apple's instructions for apps from unidentified developers](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac); do not disable system-wide protections. File transcription does not need microphone access.

Choose English or Español in **App language**. **Audio language** is independent: it lists the speech locales supported on your Mac. Select the spoken language and use **Download language** before transcribing. Apple manages that download. Whisper uses the language stored with each transcript, even if you later select another language for another recording. This is transcription, not translation. Native system messages follow macOS settings.

## Import and transcribe

Add multiple files or folders, or drag recordings into the window. Subfolders are included. Duplicate paths, symbolic links and unsupported files are skipped; each import is limited to 10,000 files. Choose **Transcribe pending files** to process the queue sequentially. An individual failure does not stop the remaining recordings. Cancellation preserves recognized text, although a model may need to finish an internal operation first.

The main engine accepts recordings shorter than 24 hours. Whisper comparison and speaker analysis require recordings shorter than two hours. OPUS, MP3, MP4, MOV, M4A, WAV, AIFF, AAC, FLAC, CAF and M4V are accepted when macOS can decode them. The first audio track is used.

## Full text and playback

**Full text** is one editable document. Copy the entire interview at once or export TXT. Batch export writes all transcripts without replacing existing files. Full-text edits affect TXT and the clipboard; SRT/VTT use the timed review segments and their own corrections.

Play the original to see the active words or segment highlighted. **Follow audio** keeps it visible and pauses automatic scrolling while text is selected. Older transcripts without word timestamps highlight entire segments. Edited passages are followed only when an unchanged segment can be located unambiguously. Highlighting never changes your text or exports.

Select a phrase and choose **Listen to selection** to hear the source passage. Segment-level timings can include neighboring words. Added or rewritten phrases do not receive invented timestamps.

## Vocabulary and quotes

Save names, places, organizations and acronyms in the personal dictionary. Up to 100 terms of up to 100 characters are used, subject to Whisper's shorter prompt limit. Vocabulary is a recognition hint, not an automatic correction or a spelling guarantee.

Select an exact passage, optionally name the speaker, and save a quote. Quotes retain the selected wording, source filename and timestamps. Later edits to the full transcript do not rewrite saved quotes. Listen, copy with or without attribution, or export your quotes together.

## Optional engines

**Compare with Whisper** adds a second local reading. Comparison groups readings into 20-second windows and can filter differences. Differences are prompts to listen again; they do not prove either engine is correct and never automatically replace your text.

**Separate speakers** groups voices under editable labels. Provide an expected speaker count or use automatic detection. Name speakers after the final analysis because recalculation can change labels. Overlapping speech, noise and music can cause errors. It does not identify people by voice.

**Prepare models** downloads the Whisper and speaker-analysis assets. Downloads and first initialization can take time. Model sizes vary by version and system cache. Recognition stays on-device after preparation.

## History and recovery

For compatibility, data remains under `~/Library/Application Support/Franco Transcribe/`. History, edits and quotes are in `transcripciones.json`; additional models are under `Models`. The app name is Vocalia, but the original internal identifier is retained to preserve existing data.

Retranscription and speaker recalculation create local JSON revisions. Removing a history entry does not delete the original recording or those revisions. To play a file moved elsewhere, reconnect its drive or use **Link original** to select the same recording in its new location.

Temporary conversions are cleaned up after normal completion; a forced exit may leave temporary files. Exports go wherever you choose, including folders that other services might sync.

## Validation and limits

Review names, figures, overlapping voices and publishable quotations against the recording. Confidence indicators are review hints, not measured accuracy percentages. There is no verified benchmark for Chilean interviews. Tests cover application behavior, not perfect recognition.

To build from source, run `zsh build.sh` with compatible Apple development tools and the macOS 26 SDK. The script builds the bundled dependencies, runs checks and produces a ZIP with license notices.

## OPUS support in 1.0.1

Use the downloads with **OPUS** in their filename. Both platforms accept `.opus` and Ogg files containing Opus (`.ogg`), including batch/folder import. No manual conversion or audio upload is needed. Windows uses its bundled decoder. Mac includes a local BSD-licensed Opus decoder and uses a temporary PCM copy for transcription and playback; normal app exit removes that copy and the original is preserved. Mac OPUS recordings must be under ten hours; Windows keeps its two-hour limit. Ogg/Vorbis is not included.

New downloads have checksums in **SHA256SUMS-GuideFix.txt**; the original 1.0.1 files remain available for reproducibility. The updated source is on the main branch and in **Vocalia-1.0.1-GuideFix-source.zip** in Releases. The tag's automatic Source code archives describe the original 1.0.1 build.
