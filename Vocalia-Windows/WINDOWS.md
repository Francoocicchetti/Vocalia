# Vocalia for Windows 11 — Intel / AMD x64

**Pre-release 0.0.6 · In development.** Vocalia is not a stable 1.0 release yet. Earlier 1.x entries are historical prototype labels from before the numbering reset; existing history and features are preserved.

[Español](WINDOWS.es.md) · [Overview](README.md)

**[Download Vocalia 0.0.6 for Windows](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.6/Vocalia-0.0.6-Windows-x64-Setup.exe)**

Source: the `Vocalia-Windows/` folder in the repository or the complete source archive attached to the release.

Vocalia 0.0.6 for Windows. Whisper recognition runs locally on your CPU. Model preparation downloads model assets; subsequent transcription loads local files in offline mode. Recordings are not uploaded.

## Install and use

1. Download and run **Vocalia-0.0.6-Windows-x64-Setup.exe**. Follow the English/Spanish installer.
2. Open **Vocalia** from the Start menu. A desktop shortcut is optional. Python and administrator privileges are not required.
3. Choose English, Spanish, German, French, Simplified Chinese or Portuguese for the interface, and select the spoken language separately.
4. Choose a model and click **Download / prepare model**. Start with `small`; `medium` and `large-v3-turbo` require more memory and processing time. For larger models, a computer with at least 16 GB RAM is a practical starting point, not a measured minimum or performance guarantee.
5. Add multiple OPUS, MP3, MP4, MOV, M4A or other supported files, or import a folder. Transcription starts automatically.
6. Copy the complete transcript, follow the highlighted text while listening, or select a passage to save a quote. Export TXT, SRT or VTT.

## History, quotes and privacy

History, settings and models are stored under `%LOCALAPPDATA%\Vocalia`. **Restore last removed** recovers removed history entries. Original recordings are never deleted. Only one app instance can open the same history. Cancellation preserves text already recognized; pending files can be restarted from the beginning.

Vocabulary provides hints, not automatic corrections. Timing follows the original recognized text. Rewriting a passage can break its alignment. TXT preserves full-text edits; SRT/VTT use the timed segments, including corrections made in Review. Speaker labels can be assigned by optional local analysis and renamed.

Exports go to your chosen folder. A cloud-synced destination may upload exported documents through that separate service. The app has no transcription account or application analytics service. Model downloads contact the model provider.

## Stability and current limits

- CPU inference: no NVIDIA GPU or CUDA driver is required.
- Recognition runs in a child process, so a recognition failure can be reported without taking down the editor.
- Transactional SQLite history, recoverable removal and ID-based editing.
- Up to 10,000 files per import; recordings must have a readable duration below two hours. Protected, corrupt and audio-less files are rejected.
- Speed and memory use depend on the processor, model and recording. No verified error rate for Chilean interviews is claimed.
- Apple Speech is Mac-only. Windows compares two local Whisper models and uses optional sherpa-onnx speaker grouping.
- Packaged tests run on Windows Server x64. They do not replace use testing on real Windows 11 hardware. Version 1.0 is not a certification of universal stability.
- The executable has no Authenticode signature; Windows may show a reputation warning. Do not disable system-wide protections.

## Build and test

On Windows x64 with Python 3.12 from python.org, run `powershell -File build.ps1` in the extracted source directory. The script installs pinned direct dependencies, runs core tests, packages the application, tests the packaged interface and offline recognition, then produces a ZIP and SHA-256 checksum.

Tests cover history removal, interrupted workers, cancellation, Unicode import paths, corrupt media and FLAC/MP3/MP4/MOV recognition with word timestamps. The public `test-speech.flac` fixture is the JFK speech excerpt from the official OpenAI Whisper tests. It is not a personal interview and is not bundled with the executable. Never use private recordings in public CI.

Dependency notices and license files are included in the packaged application.

Before retrying a partial transcription, a JSON revision is saved under `%LOCALAPPDATA%\Vocalia\Revisions`.

## Installer and ZIP launch errors

Use the Setup.exe installer to avoid missing `python312.dll` errors caused by opening Vocalia directly inside the ZIP. It installs the complete app under `%LOCALAPPDATA%\Programs\Vocalia` and creates a Start menu shortcut. Uninstall through Windows Settings → Apps; history and downloaded models under `%LOCALAPPDATA%\Vocalia` are retained. The portable ZIP remains available for experienced users who extract every file first.

The installer remains unsigned and Windows may show a reputation warning. Do not disable system-wide protections. If the error persists after using Setup.exe, report the exact error and Windows version; missing dependencies or security software may require separate diagnosis. Installer source and automated checks are in `.github/workflows/windows.yml`.


## Vocalia 0.0.5

The interface offers six languages. The interactive tour can be replayed. OPUS and Ogg/Opus remain supported. See the [version table and feature matrix](README.md).

Use **Review** to edit timed segments, mark them reviewed or restore their original wording. **Comparison** requires a second model different from the original; prepare it, then compare. **Speakers** downloads approximately 47 MB once; analyze a completed recording, listen to timed turns and assign names. Full text edited separately is preserved. The dictionary accepts up to 100 terms. Quote actions include plain copy, listening and TXT export. Speed can be changed from 0.75× to 2×. Drag files into the window; files added while processing are imported after the queue finishes and are then transcribed automatically. **Transcribe selected again** saves a JSON revision before replacing the text.

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

