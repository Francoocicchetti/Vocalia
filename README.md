<p align="center"><img src="logo.png" width="128" alt="Vocalia app icon"></p>

# Vocalia 0.0.6

**Pre-release 0.0.6 · In development.** Vocalia is not a stable 1.0 release yet. Earlier 1.x entries are historical prototype labels from before the numbering reset; existing history and features are preserved.

**Local transcription for journalists: complete transcripts, quotes and highlighted playback.**

**English** · [Español](README.es.md)

## Download

### [↓ Windows 11 — Intel / AMD installer](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.6/Vocalia-0.0.6-Windows-x64-Setup.exe)

### [↓ MacBook / Mac — Apple Silicon](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.6/Vocalia-0.0.6-macOS-AppleSilicon.zip)

[All 0.0.6 downloads and checksums](https://github.com/Francoocicchetti/Vocalia/releases/tag/v0.0.6)

| Computer | Requirements | What to download |
| --- | --- | --- |
| Windows PC | Windows 11, Intel/AMD 64-bit | `Vocalia-0.0.6-Windows-x64-Setup.exe` |
| MacBook / Mac | Apple Silicon M1 or later, macOS 26+ | `Vocalia-0.0.6-macOS-AppleSilicon.zip` |

Find the downloads under **Assets**, below the release notes. **Use the installer or Mac ZIP, not “Source code”.** No Python, Xcode, account or API key is needed to run the app. Windows ARM and Intel Macs are not supported by these builds.

## Install and start

1. **Windows:** run the installer and open Vocalia from the Start menu. A desktop shortcut is optional. If you use the portable ZIP instead, extract **the whole folder** before opening `Vocalia.exe`; keep `_internal` beside it. [Windows instructions](WINDOWS.md).
2. **Mac:** unzip, drag Vocalia.app to Applications and open it. This release is not Apple-notarized. If macOS blocks first launch, follow [System Settings → Privacy & Security → Open Anyway](INSTALL-MAC.md). Do not disable system-wide protection.
3. Choose one of **six interface languages before entering the workspace**: English, Spanish, German, French, Simplified Chinese or Portuguese. The choice appears before the workspace on first launch and can be changed inside the app later.
4. Choose the **spoken language**, then add or drop recordings: transcription starts automatically. If a model is missing, complete its download and transcription continues.
5. Follow the anchored tutorial bubbles. Reopen the tour from **How to use Vocalia**. Copy the whole transcript at once, or listen and review it before saving quotes.

The interface language and recording language are independent. Initial model downloads require internet. Recordings and transcripts are processed locally; the app does not upload them.

## Version history

| Version | Changes |
| --- | --- |
| **1.0** | First unified Mac/Windows public release; local recognition, multiple files, complete editable text, highlighted playback, source-linked quotes, TXT/SRT/VTT export and saved history. |
| **1.0.1** | Windows installer and missing-model/transcription guidance; language selection before the workspace; OPUS and Ogg/Opus import; interactive tutorial bubbles, replay/skip, restored startup language choice and Mac focus/overlay fixes. Includes the OPUS, Tour and GuideFix updates published under 1.0.1. |
| **1.0.2** | Six interface languages on both platforms. Windows gains segment review, a second-model comparison, optional local speaker grouping and naming, quote listening/plain copy/export, playback speed and dictionary editor. Also adds drag-and-drop, deferred imports while the queue runs, and retranscription of a selected recording with a saved revision. Updated bilingual guides and regression checks. |
| **1.0.3** | Speaker separation is manual only, disabled at startup on Mac. Explicit spoken Spanish decimals such as “9, coma, 5” become “9,5”; original recognition is retained, timing is preserved and figures are flagged for listening/review. |
| **0.0.4** | New recordings start transcribing automatically when added or dropped. Files run sequentially; a missing model is downloaded first. Transcribe pending remains available to resume stopped files. Existing history and edits are not automatically reprocessed. Speaker analysis remains manual. |
| **0.0.5** | In-app update notices and release notes; cross-transcript search with timed playback; projects, tags and recording dates; a figures-only review view; Word export with the complete edited text and selected quotes. |
| **0.0.6** | Click timed words to play; whole-recording or selection loops; gentle local cleanup in a separate copy; optional Whisper large-v3 and more word-confidence review flags on Windows. |

[Detailed changelog](CHANGELOG.md) · [Historial en español](CHANGELOG.es.md)

## Features by platform

| Feature | Mac | Windows |
| --- | --- | --- |
| Six interface languages; startup chooser; interactive tour | Yes | Yes |
| Multiple files/folders, drag-and-drop, sequential queue | Yes | Yes; imports requested during a job are added after the queue finishes |
| Complete editable text, playback highlighting, speed controls | Yes | Yes |
| Segment review, original segment text, review marks | Yes | Yes |
| Quotes with source/time, listen, copy, export | Yes | Yes |
| Personal dictionary and TXT/SRT/VTT exports | Yes | Yes |
| Independent transcript comparison | Apple Speech vs Whisper | Two different local Whisper models |
| Optional speaker grouping, timed turns and editable names | SpeakerKit | sherpa-onnx on CPU |
| Main recognition engine | Apple Speech | Whisper on CPU |
| Duration limit | Main engine under 24 h; OPUS under 10 h; extra engines under 2 h | Under 2 h per recording |

Windows speaker grouping downloads approximately 47 MB once from the model provider. Choose **Prepare speaker models**, then **Analyze speakers** on a completed recording. Automatic grouping is an estimate; check overlapping speech and names. Windows comparison needs a second, different model prepared first. These tools preserve independently edited full text; segment edits remain available separately for review/subtitles.

MP3, MP4, MOV, M4A, WAV, FLAC, OPUS and other supported formats can be imported. `.ogg` support here means Ogg containing Opus. Models, performance and some controls differ between platforms; Apple Speech is only available on macOS. Highlighting is shown only where the app can align text with recorded timing. Always check quotations, names and figures against the audio.

## Guides, privacy and source

- [Mac guide](GUIDE.md) · [Windows guide](WINDOWS.md) · [Privacy](PRIVACY.md)
- [Guía para Mac](GUIA.md) · [Guía para Windows](WINDOWS.es.md) · [Privacidad](PRIVACY.es.md)
- [Build and test runs](https://github.com/Francoocicchetti/Vocalia/actions/workflows/windows.yml)

Mac source is in the Swift files and `ui-translations.json`. Run `zsh build.sh` using Apple's development tools and a macOS 26 SDK. Windows source is in the `Vocalia-Windows/` folder: run `powershell -File build.ps1` on Windows x64 with Python 3.12. `build_installer.ps1` additionally requires Inno Setup 6. The complete source bundle is attached to the release.

Windows release checks run on Windows Server x64, including the packaged app, six-language tour, history editing, canceled/failed workers, real offline recognition of FLAC/MP3/MP4/MOV/OPUS/Ogg, second-model comparison, a public four-speaker recording, installer hashes, shortcuts and reinstall/uninstall data preservation. They do not replace testing on physical Windows 11 Intel/AMD machines. Mac checks cover history bindings, playback alignment, imports, localization and transcript features. These checks do not guarantee perfect recognition or absence of bugs.

Mac uses an ad-hoc local signature, without Apple notarization. Windows has no Authenticode signature. Keep the previous app until you have checked the new version with your own workflow; updates preserve the existing history location.

## Report a problem

[Open an issue](https://github.com/Francoocicchetti/Vocalia/issues) with the OS, app version, reproduction steps, file format and approximate duration. Do not post private recordings, transcripts or unreviewed logs.

## Components and licensing

Mac includes WhisperKit/SpeakerKit and a local Opus decoder; dependency source, licenses and notices are included. Windows includes PySide6, faster-whisper, CTranslate2, PyAV, ONNX Runtime and sherpa-onnx. Optional speaker models use pyannote segmentation (MIT) and 3D-Speaker embeddings (Apache-2.0); their notices and exact model download hashes are included in the source/package.

No general open-source license has been assigned to Vocalia's own code or supplied logo. Third-party licenses apply to their respective components.

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
- **One-time transition:** users of the original 0.0.5 must install the current preview once using the download links above. That original build cannot install this same-version revision itself. Future higher-numbered releases can be downloaded and installed through the new button.

Current preview: **0.0.6**, Mac build **19**, Windows file version **0.0.6.0**. The release includes the exact source used for both packages.

