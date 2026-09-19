# Vocalia changelog

**Pre-release 0.0.5 · In development.** Vocalia is not a stable 1.0 release yet. Earlier 1.x entries are historical prototype labels from before the numbering reset; existing history and features are preserved.

## Version history

| Version | Changes |
| --- | --- |
| **1.0** | First unified Mac/Windows public release; local recognition, multiple files, complete editable text, highlighted playback, source-linked quotes, TXT/SRT/VTT export and saved history. |
| **1.0.1** | Windows installer and missing-model/transcription guidance; language selection before the workspace; OPUS and Ogg/Opus import; interactive tutorial bubbles, replay/skip, restored startup language choice and Mac focus/overlay fixes. Includes the OPUS, Tour and GuideFix updates published under 1.0.1. |
| **1.0.2** | Six interface languages on both platforms. Windows gains segment review, a second-model comparison, optional local speaker grouping and naming, quote listening/plain copy/export, playback speed and dictionary editor. Also adds drag-and-drop, deferred imports while the queue runs, and retranscription of a selected recording with a saved revision. Updated bilingual guides and regression checks. |
| **1.0.3** | Speaker separation is manual only, disabled at startup on Mac. Explicit spoken Spanish decimals such as “9, coma, 5” become “9,5”; original recognition is retained, timing is preserved and figures are flagged for listening/review. |
| **0.0.4** | New recordings start transcribing automatically when added or dropped. Files run sequentially; a missing model is downloaded first. Transcribe pending remains available to resume stopped files. Existing history and edits are not automatically reprocessed. Speaker analysis remains manual. |
| **0.0.5** | In-app update notices and release notes; cross-transcript search with timed playback; projects, tags and recording dates; a figures-only review view; Word export with the complete edited text and selected quotes. |

[Detailed changelog](CHANGELOG.md) · [Historial en español](CHANGELOG.es.md)


## In-app updater — 0.0.5 installer revision

The **Update Vocalia** button now downloads the update inside the app, shows progress, supports cancellation and verifies its SHA256 digest against the official GitHub release metadata before installation. It never opens GitHub to download the app.

- **Windows:** after verification, choose **Install update**. Vocalia saves edits, closes and starts its local setup wizard in the current installation folder. Complete the wizard to reopen Vocalia. Installation is blocked while transcription or imports are running.
- **Mac:** choose **Install and restart**. Vocalia prepares and verifies the new application, saves history, replaces only the app and reopens it. A previous-app copy is kept beside the installed app for recovery. Vocalia must be in a writable Applications folder, outside a mounted image or an App Translocation location. System security protections are not disabled.
- History, quotes, projects, settings and model folders stay in their existing locations. Cancelling a download or failing verification does not change the installed app. Mac replacement failures attempt to restore the prior app.
- **One-time transition:** users of the original 0.0.5 must install this revised 0.0.5 once using the download links above. That original build cannot install this same-version revision itself. Future higher-numbered releases can be downloaded and installed through the new button.

The public version remains **0.0.5**. This revision uses Mac build **18** and Windows file version **0.0.5.1**. The current complete source is `Vocalia-0.0.5-source.zip`; the original `v0.0.5` Git tag and GitHub-generated “Source code” snapshots remain the initial release. See the linked build run for the exact revision used for these installers.

