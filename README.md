<p align="center"><img src="logo.png" width="128" alt="Vocalia app icon"></p>

# Vocalia 1.0.2

**Local transcription for journalists: complete transcripts, quotes and highlighted playback.**

**English** · [Español](README.es.md)

## Download

### [↓ Windows 11 — Intel / AMD installer](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.2/Vocalia-1.0.2-Windows-x64-Setup.exe)

### [↓ MacBook / Mac — Apple Silicon](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.2/Vocalia-1.0.2-macOS-AppleSilicon.zip)

[All 1.0.2 downloads and checksums](https://github.com/Francoocicchetti/Vocalia/releases/tag/v1.0.2)

| Computer | Requirements | What to download |
| --- | --- | --- |
| Windows PC | Windows 11, Intel/AMD 64-bit | `Vocalia-1.0.2-Windows-x64-Setup.exe` |
| MacBook / Mac | Apple Silicon M1 or later, macOS 26+ | `Vocalia-1.0.2-macOS-AppleSilicon.zip` |

Find the downloads under **Assets**, below the release notes. **Use the installer or Mac ZIP, not “Source code”.** No Python, Xcode, account or API key is needed to run the app. Windows ARM and Intel Macs are not supported by these builds.

## Install and start

1. **Windows:** run the installer and open Vocalia from the Start menu. A desktop shortcut is optional. If you use the portable ZIP instead, extract **the whole folder** before opening `Vocalia.exe`; keep `_internal` beside it. [Windows instructions](WINDOWS.md).
2. **Mac:** unzip, drag Vocalia.app to Applications and open it. This release is not Apple-notarized. If macOS blocks first launch, follow [System Settings → Privacy & Security → Open Anyway](INSTALL-MAC.md). Do not disable system-wide protection.
3. Choose one of **six interface languages before entering the workspace**: English, Spanish, German, French, Simplified Chinese or Portuguese. The choice appears once after this update and can be changed inside the app later.
4. Choose the **spoken language**, prepare/download a recognition model, add recordings, then click **Transcribe pending**. Adding a file or playing it does not transcribe it.
5. Follow the anchored tutorial bubbles. Reopen the tour from **How to use Vocalia**. Copy the whole transcript at once, or listen and review it before saving quotes.

The interface language and recording language are independent. Initial model downloads require internet. Recordings and transcripts are processed locally; the app does not upload them.

## Version history

| Version | Changes |
| --- | --- |
| **1.0** | First unified Mac/Windows public release; local recognition, multiple files, complete editable text, highlighted playback, source-linked quotes, TXT/SRT/VTT export and saved history. |
| **1.0.1** | Windows installer and missing-model/transcription guidance; language selection before the workspace; OPUS and Ogg/Opus import; interactive tutorial bubbles, replay/skip, restored startup language choice and Mac focus/overlay fixes. Includes the OPUS, Tour and GuideFix updates published under 1.0.1. |
| **1.0.2** | Six interface languages on both platforms. Windows gains segment review, a second-model comparison, optional local speaker grouping and naming, quote listening/plain copy/export, playback speed and dictionary editor. Also adds drag-and-drop, deferred imports while the queue runs, and retranscription of a selected recording with a saved revision. Updated bilingual guides and regression checks. |

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

Mac source is in the Swift files and `ui-translations.json`. Run `zsh build.sh` using Apple's development tools and a macOS 26 SDK. Windows source is in `Vocalia-Windows-source.zip`: extract it and run `powershell -File build.ps1` on Windows x64 with Python 3.12. `build_installer.ps1` additionally requires Inno Setup 6. The complete source bundle is attached to the release.

Windows release checks run on Windows Server x64, including the packaged app, six-language tour, history editing, canceled/failed workers, real offline recognition of FLAC/MP3/MP4/MOV/OPUS/Ogg, second-model comparison, a public four-speaker recording, installer hashes, shortcuts and reinstall/uninstall data preservation. They do not replace testing on physical Windows 11 Intel/AMD machines. Mac checks cover history bindings, playback alignment, imports, localization and transcript features. These checks do not guarantee perfect recognition or absence of bugs.

Mac uses an ad-hoc local signature, without Apple notarization. Windows has no Authenticode signature. Keep the previous app until you have checked the new version with your own workflow; updates preserve the existing history location.

## Report a problem

[Open an issue](https://github.com/Francoocicchetti/Vocalia/issues) with the OS, app version, reproduction steps, file format and approximate duration. Do not post private recordings, transcripts or unreviewed logs.

## Components and licensing

Mac includes WhisperKit/SpeakerKit and a local Opus decoder; dependency source, licenses and notices are included. Windows includes PySide6, faster-whisper, CTranslate2, PyAV, ONNX Runtime and sherpa-onnx. Optional speaker models use pyannote segmentation (MIT) and 3D-Speaker embeddings (Apache-2.0); their notices and exact model download hashes are included in the source/package.

No general open-source license has been assigned to Vocalia's own code or supplied logo. Third-party licenses apply to their respective components.
