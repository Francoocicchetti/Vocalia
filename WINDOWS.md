# Vocalia for Windows 11 — Intel / AMD x64

[Español](WINDOWS.es.md) · [Overview](README.md)

**[Download Windows 0.1.1 preview](https://github.com/Francoocicchetti/Vocalia/releases/tag/windows-v0.1.1-preview)**

Source: `Vocalia-Windows-source.zip`. Extract it before running the build script.

An independent preview of Vocalia for Windows. Whisper recognition runs locally on your CPU. Model preparation downloads model assets; subsequent transcription loads local files in offline mode. Recordings are not uploaded.

## Install and use

1. Extract the **entire ZIP**. Keep the `_internal` folder next to Vocalia.exe.
2. Open **Vocalia.exe**. Python and administrator privileges are not required.
3. Choose English or Español for the interface, and select the spoken language separately.
4. Choose a model and click **Download / prepare model**. Start with `small`; `medium` and `large-v3-turbo` require more memory and processing time. For larger models, a computer with at least 16 GB RAM is a practical starting point, not a measured minimum or performance guarantee.
5. Add multiple MP3, MP4, MOV, M4A or other supported files, or import a folder. Click **Transcribe pending**.
6. Copy the complete transcript, follow the highlighted text while listening, or select a passage to save a quote. Export TXT, SRT or VTT.

## History, quotes and privacy

History, settings and models are stored under `%LOCALAPPDATA%\Vocalia`. **Restore last removed** recovers removed history entries. Original recordings are never deleted. Only one app instance can open the same history. Cancellation preserves text already recognized; pending files can be restarted from the beginning.

Vocabulary provides hints, not automatic corrections. Timing follows the original recognized text. Rewriting a passage can break its alignment. TXT preserves full-text edits; SRT/VTT use the original timed segments. Speaker names on quotes are entered manually.

Exports go to your chosen folder. A cloud-synced destination may upload exported documents through that separate service. The app has no transcription account or application analytics service. Model downloads contact the model provider.

## Stability and current limits

- CPU inference: no NVIDIA GPU or CUDA driver is required.
- Recognition runs in a child process, so a recognition failure can be reported without taking down the editor.
- Transactional SQLite history, recoverable removal and ID-based editing.
- Up to 10,000 files per import; recordings must have a readable duration below two hours. Protected, corrupt and audio-less files are rejected.
- Speed and memory use depend on the processor, model and recording. No verified error rate for Chilean interviews is claimed.
- No Apple Speech, Apple/Whisper comparison or automatic speaker separation in this edition.
- Packaged tests run on Windows Server x64. They do not replace use testing on real Windows 11 hardware. This is a preview, not a certified stable release.
- The executable has no Authenticode signature; Windows may show a reputation warning. Do not disable system-wide protections.

## Build and test

On Windows x64 with Python 3.12 from python.org, run `powershell -File build.ps1` in the extracted source directory. The script installs pinned direct dependencies, runs core tests, packages the application, tests the packaged interface and offline recognition, then produces a ZIP and SHA-256 checksum.

Tests cover history removal, interrupted workers, cancellation, Unicode import paths, corrupt media and FLAC/MP3/MP4/MOV recognition with word timestamps. The public `test-speech.flac` fixture is the JFK speech excerpt from the official OpenAI Whisper tests. It is not a personal interview and is not bundled with the executable. Never use private recordings in public CI.

Dependency notices and license files are included in the packaged application.
