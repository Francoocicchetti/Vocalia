# Vocalia for Mac — user guide

**Pre-release 0.0.5 · In development.** Vocalia is not a stable 1.0 release yet. Earlier 1.x entries are historical prototype labels from before the numbering reset; existing history and features are preserved.

[Installation and macOS security prompts](INSTALL-MAC.md)

[English overview](README.md) · [Español](GUIA.md) · [Windows guide](WINDOWS.md)

## Install and choose languages

Requires Apple Silicon and macOS 26 or later. Extract the Mac ZIP and move Vocalia.app to Applications. This release is locally signed and not notarized. If macOS blocks it, consult [Apple's instructions for apps from unidentified developers](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac); do not disable system-wide protections. File transcription does not need microphone access.

Choose English, Spanish, German, French, Simplified Chinese or Portuguese in **App language**. **Audio language** is independent: it lists the speech locales supported on your Mac. Select the spoken language and use **Download language** before transcribing. Apple manages that download. Whisper uses the language stored with each transcript, even if you later select another language for another recording. This is transcription, not translation. Native system messages follow macOS settings.

## Import and transcribe

Add multiple files or folders, or drag recordings into the window. Subfolders are included. Duplicate paths, symbolic links and unsupported files are skipped; each import is limited to 10,000 files. New recordings start automatically and are processed sequentially. An individual failure does not stop the remaining recordings. Cancellation preserves recognized text, although a model may need to finish an internal operation first.

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


## Vocalia 0.0.5

The interface offers six languages. The interactive tour can be replayed. OPUS and Ogg/Opus remain supported. See the [version table and feature matrix](README.md).

## Speakers and numbers in 1.0.3

Speaker separation requires a manual action. On Mac, select “Speaker analysis: manual” and click “Analyze speakers / compare” on a completed recording; it never runs after transcription. On Windows, click “Analyze speakers” when needed. Existing speaker labels are preserved.

Decimal formatting follows the audio language, not the interface language. It handles explicit Spanish figures such as “12 coma 75” and simple spoken forms such as “nueve coma cinco”, preserving decimal zeros and original recognition for review. Existing transcripts are not rewritten; dates, lists and ambiguous quantities are not inferred. Figures are flagged for listening and review: correct formatting does not prove the recognizer heard the right number. No overall accuracy improvement on real interviews has been measured.

## Automatic transcription in 0.0.4

New recordings start transcribing automatically when added or dropped. Files run sequentially; a missing model is downloaded first. Transcribe pending remains available to resume stopped files. Existing history and edits are not automatically reprocessed. Speaker analysis remains manual.

## Library, review, Word and updates in 0.0.5

- **Library and projects:** search a word or phrase across your local transcripts. Select a result and choose **Open result and listen**. Playback uses the matching segment interval; rewritten text without a reliable timing match is labeled **No exact audio position** and opens without inventing a timestamp. Up to 200 matches appear; narrow the search if necessary.
- Assign a **Project**, comma-separated **Tags** and a **Recording date** (`YYYY-MM-DD`) to a selected recording, then **Save organization**. Filter by project, tag or date range. These are history metadata, not folders that move your recordings. Older recordings remain available; their creation/import date is used until a recording date is assigned.
- **Review figures / Figures only:** collect the segments containing digits in the recognized or original text. Listen, correct and mark them reviewed using the existing review controls. This does not certify a number as correct or detect every number written as a word. An independently edited full transcript remains separate from segment edits; update that text too when necessary.
- **Export Word:** select a transcript, choose its document title and date, tick the saved quotes to include, and save a `.docx`. The document contains the full edited transcript, project/tags if present, and chosen quotes with speaker, source filename and time. It does not include the private path to the original recording. No Word subscription is needed to export.
- **Updates:** enable or disable automatic checks, or choose **Check now**. An anonymous GitHub release check runs at most once per day while the app is running, and only reports releases with a matching platform download. The dialog shows release notes, a download button and the release page. Recordings, transcript text, project names and history are never sent.
- Use **Update Vocalia** to download verified updates within the app and start installation. See the installer revision instructions below.


## In-app updater — 0.0.5 installer revision

The **Update Vocalia** button now downloads the update inside the app, shows progress, supports cancellation and verifies its SHA256 digest against the official GitHub release metadata before installation. It never opens GitHub to download the app.

- **Windows:** after verification, choose **Install update**. Vocalia saves edits, closes and starts its local setup wizard in the current installation folder. Complete the wizard to reopen Vocalia. Installation is blocked while transcription or imports are running.
- **Mac:** choose **Install and restart**. Vocalia prepares and verifies the new application, saves history, replaces only the app and reopens it. A previous-app copy is kept beside the installed app for recovery. Vocalia must be in a writable Applications folder, outside a mounted image or an App Translocation location. System security protections are not disabled.
- History, quotes, projects, settings and model folders stay in their existing locations. Cancelling a download or failing verification does not change the installed app. Mac replacement failures attempt to restore the prior app.
- **One-time transition:** users of the original 0.0.5 must install this revised 0.0.5 once using the download links above. That original build cannot install this same-version revision itself. Future higher-numbered releases can be downloaded and installed through the new button.

The public version remains **0.0.5**. This revision uses Mac build **18** and Windows file version **0.0.5.1**. The current complete source is `Vocalia-0.0.5-source.zip`; the original `v0.0.5` Git tag and GitHub-generated “Source code” snapshots remain the initial release. See the linked build run for the exact revision used for these installers.


## Audio review in 0.0.6 (preview)

- Leave **Click words to play** on to listen from a timed word. Switch it off to edit without starting playback. Dragging to select text does not start playback.
- Choose **Repeat audio** for the whole recording, or select timed words and choose **Repeat selection**. Pause or turn repetition off when finished. Changing recordings clears the loop.
- **Clean audio** creates a separate local copy. Enable **Use cleaned audio** to listen to it, or deliberately transcribe the selected recording again. Existing text stays in place until retranscription; normal revision backups still apply.
- On Mac, **Whisper large-v3 (slower)** selects the larger comparison model. On Windows, choose **large-v3** in the model list. Download it using the existing model preparation controls. Model size alone does not guarantee better names or figures.

See [validation status](QA-0.0.6.md). The 0.0.6 release is gated on both native platform build jobs.
