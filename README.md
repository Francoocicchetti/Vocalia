<p align="center"><img src="logo.png" width="128" alt="Vocalia app icon"></p>

# Vocalia 1.0.1

**Local transcription for journalists: complete transcripts, quotes and highlighted playback.**

**English** · [Español](README.es.md)

## Download the app

### [↓ Download for Windows 11 — Intel / AMD](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-Windows-x64-GuideFix-Setup.exe)

### [↓ Download for MacBook / Mac — Apple Silicon](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-macOS-AppleSilicon-GuideFix.zip)

**[View the official 1.0 Release and all downloads](https://github.com/Francoocicchetti/Vocalia/releases/tag/v1.0.1)**

| Your computer | Download this file | Requirements |
| --- | --- | --- |
| Windows PC | `Vocalia-1.0.1-Windows-x64-GuideFix-Setup.exe` | Windows 11, Intel/AMD 64-bit |
| MacBook or Mac | `Vocalia-1.0.1-macOS-AppleSilicon-GuideFix.zip` | Apple Silicon M1 or later, macOS 26+ |

On the Release page, the files are under **Assets**. **Download the Windows installer or the Mac ZIP, not “Source code”.** No Python, Xcode, transcription account or API key is required to run the downloaded app.

## Install and start

- **Windows:** download and run **Vocalia-1.0.1-Windows-x64-GuideFix-Setup.exe**, follow the installer, then open **Vocalia** from the Start menu. A desktop shortcut is optional. No manual extraction is needed. [Windows guide](WINDOWS.md).
- **Mac:** extract the ZIP, drag **Vocalia.app** to **Applications**, then open it. The app is not notarized by Apple; macOS may block its first launch. **[Mac installation and “Open Anyway” instructions](INSTALL-MAC.md)**.

Choose your interface language and the spoken language, prepare/download a model, add recordings and start the queue. Model downloads need internet; subsequent recognition is local. Copy the full transcript at once or review it with audio highlighting.

## What 1.0 means

This is the first unified public release number for both platforms. It does not imply Apple/Microsoft certification or perfect recognition. Mac has a local signature, without Apple notarization. Windows has no Authenticode signature. Windows automated tests run on Windows Server x64; validation on real Windows 11 hardware is still pending. Review names, numbers and quotations against the original audio.

## Features by platform

| Feature | Mac | Windows |
| --- | --- | --- |
| Multiple files and folders; sequential queue | Yes | Yes |
| Full editable transcript; TXT, SRT and VTT export | Yes | Yes |
| Playback highlighting and source-linked quotations | Yes | Yes |
| Personal vocabulary; English/Spanish interface | Yes | Yes |
| Recognition engine | Apple Speech; optional Whisper comparison | Whisper on CPU |
| Automatic speaker grouping | Optional | Not included; quote speakers are entered manually |
| Recording duration | Main engine: under 24 h; extra engines: under 2 h | Under 2 h |

OPUS, MP3, MP4, MOV, M4A and other supported audio/video formats are accepted. Protected, corrupt or unsupported files may fail. Edited text can lose its alignment with the audio. Transcription accuracy is not guaranteed, and no measured error rate for Chilean interviews is claimed.

## Guides, privacy and source

- [Mac guide](GUIDE.md) · [Windows guide](WINDOWS.md)
- [Privacy](PRIVACY.md) · [Release notes](CHANGELOG.md)
- [Guía para Mac en español](GUIA.md) · [Guía para Windows en español](WINDOWS.es.md)
- [Windows build and regression tests](https://github.com/Francoocicchetti/Vocalia/actions/workflows/windows.yml)

The public version is 1.0 on both platforms; earlier labels were development builds. Mac source is in the Swift files; run `zsh build.sh` with Apple's development tools and a macOS 26 SDK. The script extracts the bundled dependencies, builds the app and runs its checks. Windows source is in `Vocalia-Windows-source.zip`; extract it and run `powershell -File build.ps1` on Windows x64 with Python 3.12. Builds include dependency notices.

Windows automated checks run on Windows Server x64 and cover the packaged interface, history handling, worker failures, Unicode paths and offline MP3/MP4/MOV/FLAC recognition. They do not replace testing on real Windows 11 hardware. The Mac app has 48 core and feature checks. Tests demonstrate specific behavior, not universal stability or perfect recognition.

## Report a problem

Open an issue with your OS, app version, steps to reproduce and the file format/approximate duration. **Do not post private recordings, transcripts, source names or unreviewed logs.**

## Components and licensing

Mac uses Apple SpeechAnalyzer, WhisperKit and SpeakerKit; dependency sources are in `Vendor.zip`, with [license](THIRD_PARTY_LICENSE), [notices](THIRD_PARTY_NOTICES) and [origin](THIRD_PARTY_ORIGIN.txt). Windows uses PySide6, faster-whisper, CTranslate2, PyAV and ONNX Runtime; its package includes `licenses/` and third-party notices. Model providers retain their respective terms.

No general open-source license has been assigned to Vocalia's own code or supplied logo. Third-party licenses apply to their respective components.

## New in 1.0.1

- Choose English or Spanish before entering the workspace on first launch. Change the app language later inside Vocalia.
- A replayable tutorial explains adding recordings, preparing a model, transcribing, reviewing and copying the full text.
- Windows: **adding a recording does not transcribe it**. Click **Transcribe pending**. If the model is missing, accept its download; transcription then starts automatically.
- Clear empty-queue, missing-model and worker-failure messages. Playback stops when transcription is requested and is unavailable while a job is running.


## OPUS support in 1.0.1

Use the downloads with **OPUS** in their filename. Both platforms accept `.opus` and Ogg files containing Opus (`.ogg`), including batch/folder import. No manual conversion or audio upload is needed. Windows uses its bundled decoder. Mac includes a local BSD-licensed Opus decoder and uses a temporary PCM copy for transcription and playback; normal app exit removes that copy and the original is preserved. Mac OPUS recordings must be under ten hours; Windows keeps its two-hour limit. Ogg/Vorbis is not included.

New downloads have checksums in **SHA256SUMS-GuideFix.txt**; the original 1.0.1 files remain available for reproducibility. The updated source is on the main branch and in **Vocalia-1.0.1-GuideFix-source.zip** in Releases. The tag's automatic Source code archives describe the original 1.0.1 build.

## Interactive in-app tour

Anchored speech bubbles explain the actual controls. Use Next, Back or Skip; reopen the tour with **How to use Vocalia**. First launch still asks for your language before entering the workspace. The tour does not start jobs or modify recordings. Downloads marked **GuideFix** also include OPUS support.

## Startup and tour display fix

The **GuideFix** downloads restore the language picker once on first launch after this update, including existing installations. Your choice is remembered afterwards and remains changeable inside the app. Mac tutorial bubbles now use an opaque background and clear keyboard focus from underlying controls to prevent focus outlines crossing the tutorial. Background editing is paused during the tour and restored when it closes.
