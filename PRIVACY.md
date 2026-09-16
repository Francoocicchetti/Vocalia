# Privacy

[Español](PRIVACY.es.md) · [Overview](README.md)

Vocalia processes recordings on your computer. It has no transcription account, application analytics service or cloud transcription endpoint. Model preparation downloads assets from their providers. On Mac, Apple's system services remain subject to macOS settings and policies. On Windows, transcription loads local model files in offline mode; Hugging Face and ONNX Runtime telemetry are disabled in the worker.

## Local data

- **Mac:** history, quotes and models are stored under `~/Library/Application Support/Franco Transcribe/`. The legacy name and app identifier preserve upgrade compatibility.
- **Windows:** history and settings are stored in SQLite under `%LOCALAPPDATA%\Vocalia`; models are in its `Models` folder. Removed history entries are retained for recovery and are not securely erased. A process failure or cancellation preserves text already received by the editor.

Original recordings are not modified. Temporary files are removed after normal completion; a forced exit may leave temporary files. Exported documents go to the location you choose. A cloud-synced folder can upload exports through its own service.

The public repository and app downloads contain no user history, personal interviews, real user transcripts or downloaded model weights. Windows tests use a public JFK speech excerpt from the official OpenAI Whisper test suite. That fixture is test-only and is not bundled with the executable.

Do not attach sensitive recordings, source identities, transcripts or unreviewed logs to public issues.
