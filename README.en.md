# Vocalia

**On-device transcription for journalists, interviews and quotations.**

[Español](README.md) · [Privacy](PRIVACY.md)

Vocalia turns audio and video into a complete, editable transcript on your Mac. Follow playback with synchronized highlighting, save verbatim quotes with source timestamps, and export TXT, SRT or VTT.

## Windows 11 (Intel / AMD)

A separate Windows x64 preview is available: **[downloads and instructions](WINDOWS.md)**. It includes local transcription, full text, quotations and playback highlighting. It does not include Apple Speech or automatic speaker separation. The following sections describe the native Mac app.

## Download for Mac

[Download Vocalia 2.2 for Mac](https://github.com/Francoocicchetti/Vocalia/raw/refs/heads/main/Vocalia-2.2-macOS.zip)

**Preview release. Requires Apple Silicon and macOS 26 or later.** Unzip and drag Vocalia.app to Applications. This build is locally signed and **not notarized by Apple**. macOS may block its first launch. See [Apple’s instructions](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac), or build from source. You do not need to disable system-wide security protections.

## Features

- Batch import of audio, video and folders.
- Full editable text, audio-follow highlighting and subtitle exports.
- Personal vocabulary and source-linked quotations.
- Optional local Whisper comparison and automatic speaker grouping.
- English or Spanish interface, independent audio-language selection and explicit model download.

Choose **App language**, then **Audio language**. Use **Download language** if needed, add your files and choose **Transcribe pending files**. Models are downloaded when required. Audio is processed on your Mac, without an account or API key. System menus and technical messages follow macOS language settings.

Main transcription accepts files shorter than 24 hours. Comparison and speaker analysis require files shorter than 2 hours. Recognition and speaker labels can be wrong; check names, numbers and publishable quotes against the recording. Existing transcripts without word timestamps highlight whole segments. Rewritten text may no longer align with audio.

## Build

Install Apple development tools with a macOS 26+ SDK and compatible Swift compiler, then run:

```sh
zsh build.sh
```

The build runs synthetic tests and produces `dist/Vocalia.zip`. No personal recordings or downloaded models are included in this repository. Version 2.2 passed 48 checks; these do not measure transcription accuracy or guarantee that no other defects remain.

Report reproducible issues without uploading sensitive recordings, transcripts or unreviewed crash logs. Argmax source licenses and notices are retained in `Vendor/Argmax`. No open-source license has been assigned to Vocalia’s own code or logo.

Third-party libraries, full source and licenses are bundled in `Vendor.zip`. The build script extracts them into a temporary directory. Vocalia’s own Swift files can be browsed directly in this repository.
