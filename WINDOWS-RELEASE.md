# Vocalia 0.0.4 for Windows

**Pre-release 0.0.4 · In development.** Vocalia is not a stable 1.0 release yet. This version replaces the previous 1.0.4 label while preserving features and data. Earlier table entries are historical prototype labels.

[Download the installer and read the Windows guide](WINDOWS.md).

Six interface languages, local Whisper transcription, segment review, comparison with a second model, optional speaker grouping, quotes, playback highlighting and speed controls. Windows 11 Intel/AMD x64; recordings under two hours. Initial model downloads need internet.

[Español: descarga e instrucciones](WINDOWS.es.md).

Seis idiomas de interfaz, transcripción local, revisión, comparación, voces, cuñas y reproducción sincronizada. Windows 11 Intel/AMD de 64 bits; grabaciones de menos de dos horas.

Automated release tests use Windows Server x64; physical Windows 11 testing remains pending. The installer is not Authenticode-signed.

## Automatic transcription in 0.0.4

New recordings start transcribing automatically when added or dropped. Files run sequentially; a missing model is downloaded first. Transcribe pending remains available to resume stopped files. Existing history and edits are not automatically reprocessed. Speaker analysis remains manual.
