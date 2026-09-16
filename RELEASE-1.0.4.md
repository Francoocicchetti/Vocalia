# Vocalia 1.0.4 — automatic transcription

## Download

- **Windows 11 · Intel/AMD:** choose **Vocalia-1.0.4-Windows-x64-Setup.exe** under Assets.
- **Mac · Apple Silicon · macOS 26+:** choose **Vocalia-1.0.4-macOS-AppleSilicon.zip**.
- The Windows portable ZIP must be fully extracted before opening Vocalia.exe. “Source code” is for developers.

## What changed

New recordings start transcribing automatically when added or dropped. Files run sequentially; a missing model is downloaded first. Transcribe pending remains available to resume stopped files. Existing history and edits are not automatically reprocessed. Speaker analysis remains manual.

Choose the audio language before adding files. On Windows, accept the one-time model download if prompted; the imported batch then starts without pressing Transcribe. Mac prepares the selected Apple speech model when needed. Cancel stops the queue; retrying partial text saves a revision. Tutorial bubbles and guidance are updated in all six interface languages.

The app processes recordings locally. Model downloads require internet. Mac remains ad-hoc signed, without Apple notarization: move Vocalia.app to Applications; if blocked, use System Settings → Privacy & Security → Open Anyway. Windows remains unsigned. Do not disable system-wide security. [Installation guide](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.md).

Checks cover Mac import/cancel/history behavior, Windows packaged import → model download → actual OPUS transcription, batch imports, duplicate detection, six languages, offline formats, optional voices/comparison, installer and preserved data. Windows CI runs on Windows Server x64, not physical Windows 11 hardware. Speech recognition still requires review of quotations, names and figures.

---

# Español

## Descarga

- **Windows 11 · Intel/AMD:** **Vocalia-1.0.4-Windows-x64-Setup.exe**, en Assets.
- **Mac · Apple Silicon · macOS 26+:** **Vocalia-1.0.4-macOS-AppleSilicon.zip**.

Las grabaciones nuevas se transcriben automáticamente al agregarlas o arrastrarlas. Se procesan una a una; si falta el modelo, se descarga primero. Transcribir pendientes permite retomar archivos detenidos. No se reprocesan automáticamente el historial ni las ediciones. El análisis de voces sigue siendo manual.

Elige el idioma del audio antes de agregar archivos. En Windows, acepta la descarga inicial del modelo si se solicita; después comienza la transcripción sin pulsar Transcribir. En Mac se prepara el modelo de Apple cuando hace falta. Cancelar detiene la cola. Los globos del tutorial y las indicaciones están actualizados en los seis idiomas.

Los audios se procesan localmente. Para instalar en Mac, mueve Vocalia.app a Aplicaciones y, si macOS la bloquea, usa Ajustes del Sistema → Privacidad y seguridad → Abrir igualmente. No desactives las protecciones del sistema. [Guía de instalación](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.es.md). Revisa nombres, cifras y cuñas escuchando el original.
