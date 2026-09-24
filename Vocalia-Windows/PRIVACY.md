# Privacy

[Español](PRIVACY.es.md) · [Overview](README.md)

Vocalia processes recordings on your computer. It has no transcription account, application analytics service or cloud transcription endpoint. Model preparation downloads assets from their providers. On Mac, Apple's system services remain subject to macOS settings and policies. On Windows, transcription loads local model files in offline mode; Hugging Face and ONNX Runtime telemetry are disabled in the worker.

## Local data

- **Mac:** history, quotes and models are stored under `~/Library/Application Support/Franco Transcribe/`. The legacy name and app identifier preserve upgrade compatibility.
- **Windows:** history and settings are stored in SQLite under `%LOCALAPPDATA%\Vocalia`; models are in its `Models` folder. Removed history entries are retained for recovery and are not securely erased. A process failure or cancellation preserves text already received by the editor.

Original recordings are not modified. Temporary files are removed after normal completion; a forced exit may leave temporary files. Exported documents go to the location you choose. A cloud-synced folder can upload exports through its own service.

The public repository and app downloads contain no user history, personal interviews, real user transcripts or downloaded model weights. Windows tests use a public JFK speech excerpt from the official OpenAI Whisper test suite. That fixture is test-only and is not bundled with the executable.

Do not attach sensitive recordings, source identities, transcripts or unreviewed logs to public issues.

Windows optional speaker models are downloaded from the sherpa-onnx public release assets on GitHub. Speaker analysis and transcript comparison run locally. The additional speaker test downloads a public four-speaker fixture from the same provider, never user recordings.

## Update checks

Starting with 0.0.5, optional release checks contact the public GitHub API once a day and when you choose Check now. GitHub receives the normal network request (including your IP address) and app version, never recordings, transcript text, project names or history. Disable automatic checks in Updates. Opening release details uses your browser; update packages download inside the app. Projects, tags and recording dates are stored in the same local history. Word exports are written only to your chosen destination.

When you choose Update now, Vocalia downloads the official GitHub package inside the app and verifies its SHA256 digest. No history or recordings are sent. Only the application is replaced after you choose to install; the data folder is preserved.
