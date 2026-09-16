<p align="center"><img src="logo.png" width="128" alt="Vocalia app icon"></p>

# Vocalia

**Local audio transcription for journalists. Full transcripts, source-linked quotes and synchronized playback.**

**English** · [Español](README.es.md)

Turn interviews and recordings into one complete, editable document. Import multiple files, follow the highlighted transcript while listening, and collect quotations with source timestamps. Audio stays on your computer; models are downloaded separately.

## Download

| Platform | Download | Requirements |
| --- | --- | --- |
| macOS | [Vocalia 2.2.1 for Mac](https://github.com/Francoocicchetti/Vocalia/raw/refs/heads/main/Vocalia-2.2.1-macOS.zip) | Apple Silicon, macOS 26 or later |
| Windows | [Vocalia 0.1.1 preview for Windows](https://github.com/Francoocicchetti/Vocalia/releases/tag/windows-v0.1.1-preview) | Windows 11, Intel/AMD x64 |

Both are **preview releases**. The Mac app is locally signed but not notarized by Apple; the Windows app has no Authenticode signature. See the platform guides for installation and current limits.

### Get started

1. Download the package for your computer and extract it completely.
2. **Mac:** move Vocalia.app to Applications. **Windows:** open Vocalia.exe and keep its `_internal` folder beside it.
3. Choose **English** or **Español** for the interface. Select the spoken language separately.
4. Prepare the language/model, add your recordings, then transcribe pending files.
5. Copy or export the complete transcript. Check names, numbers and quotations against the original audio before publication.

No transcription account, API key or subscription is required. An internet connection is needed for the initial model downloads; recognition then runs locally.

## Features by platform

| Feature | Mac | Windows preview |
| --- | --- | --- |
| Multiple files and folders; sequential queue | Yes | Yes |
| Full editable transcript; TXT, SRT and VTT export | Yes | Yes |
| Playback highlighting and source-linked quotations | Yes | Yes |
| Personal vocabulary; English/Spanish interface | Yes | Yes |
| Recognition engine | Apple Speech; optional Whisper comparison | Whisper on CPU |
| Automatic speaker grouping | Optional | Not included; quote speakers are entered manually |
| Recording duration | Main engine: under 24 h; extra engines: under 2 h | Under 2 h |

MP3, MP4, MOV, M4A and other supported audio/video formats are accepted. Protected, corrupt or unsupported files may fail. Edited text can lose its alignment with the audio. Transcription accuracy is not guaranteed, and no measured error rate for Chilean interviews is claimed.

## Guides, privacy and source

- [Mac guide](GUIDE.md) · [Windows guide](WINDOWS.md)
- [Privacy](PRIVACY.md) · [Release notes](CHANGELOG.md)
- [Guía para Mac en español](GUIA.md) · [Guía para Windows en español](WINDOWS.es.md)
- [Windows build and regression tests](https://github.com/Francoocicchetti/Vocalia/actions/workflows/windows.yml)

Mac source is in the Swift files; run `zsh build.sh` with Apple's development tools and a macOS 26 SDK. The script extracts the bundled dependencies, builds the app and runs its checks. Windows source is in `Vocalia-Windows-source.zip`; extract it and run `powershell -File build.ps1` on Windows x64 with Python 3.12. Builds include dependency notices.

Windows automated checks run on Windows Server x64 and cover the packaged interface, history handling, worker failures, Unicode paths and offline MP3/MP4/MOV/FLAC recognition. They do not replace testing on real Windows 11 hardware. The Mac app has 48 core and feature checks. Tests demonstrate specific behavior, not universal stability or perfect recognition.

## Report a problem

Open an issue with your OS, app version, steps to reproduce and the file format/approximate duration. **Do not post private recordings, transcripts, source names or unreviewed logs.**

## Components and licensing

Mac uses Apple SpeechAnalyzer, WhisperKit and SpeakerKit; dependency sources are in `Vendor.zip`, with [license](THIRD_PARTY_LICENSE), [notices](THIRD_PARTY_NOTICES) and [origin](THIRD_PARTY_ORIGIN.txt). Windows uses PySide6, faster-whisper, CTranslate2, PyAV and ONNX Runtime; its package includes `licenses/` and third-party notices. Model providers retain their respective terms.

No general open-source license has been assigned to Vocalia's own code or supplied logo. Third-party licenses apply to their respective components.
