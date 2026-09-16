# Vocalia 1.0 — Mac and Windows

English · [Español](https://github.com/Francoocicchetti/Vocalia/blob/v1.0.0/README.es.md)

## Download

### [↓ Windows 11 — Intel / AMD x64](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.0/Vocalia-1.0-Windows-x64.zip)
### [↓ MacBook / Mac — Apple Silicon, macOS 26+](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.0/Vocalia-1.0-macOS-AppleSilicon.zip)

Or expand **Assets** below and download the corresponding app ZIP. **Do not choose “Source code” to install the app.**

## Install

- **Windows:** extract the entire ZIP, open the Vocalia folder and run **Vocalia.exe**. Keep `_internal` beside it. No Python installation required.
- **Mac:** extract the ZIP, drag **Vocalia.app** to **Applications** and open it. The app is locally signed but not notarized. **[Mac installation and Apple's per-app “Open Anyway” procedure](https://github.com/Francoocicchetti/Vocalia/blob/v1.0.0/INSTALL-MAC.md)**.

Choose English or Español, select the spoken language and download/prepare the local model. Then add your audio/video files and transcribe the queue. Recordings stay on your computer.

## Included

Batch import, complete editable transcripts, highlighted playback, source-linked quotes, vocabulary and TXT/SRT/VTT export. Mac uses Apple Speech with optional Whisper comparison and speaker grouping. Windows uses Whisper on CPU and manual speaker names for quotes; automatic speaker separation is not included.

## Validation and limits

- Mac: 48 core/feature checks and local signature verification.
- Windows: packaged executable tests for history, worker failures, cancellation, Unicode paths, corrupt media and offline FLAC/MP3/MP4/MOV recognition.
- Windows tests run on Windows Server x64; real Windows 11 hardware validation is still pending.
- Mac requires Apple Silicon and macOS 26+. Windows requires Windows 11 Intel/AMD x64. Mac Intel and Windows ARM are not supported.
- Windows files must be shorter than two hours; Mac main transcription accepts files shorter than 24 hours, with a two-hour limit for extra engines.
- No Apple notarization or Windows Authenticode certificate. Version 1.0 is not a certification of universal stability or recognition accuracy. Review publishable quotes against the original.

The **SHA256SUMS.txt** asset contains checksums for both app ZIPs. This public version number replaces earlier development labels; existing history locations are retained. [Full English guide](https://github.com/Francoocicchetti/Vocalia/blob/v1.0.0/README.md).

---

## Español — descarga e instalación

**[Descargar Windows](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.0/Vocalia-1.0-Windows-x64.zip)** · **[Descargar MacBook/Mac](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.0/Vocalia-1.0-macOS-AppleSilicon.zip)**

En **Assets**, elige el ZIP de tu equipo; “Source code” es código fuente, no la app.

- **Windows:** usa Extraer todo, abre la carpeta Vocalia y ejecuta Vocalia.exe. Conserva `_internal`.
- **Mac:** descomprime, arrastra Vocalia.app a Aplicaciones y ábrela. **[Guía para instalarla y usar Abrir igualmente si macOS la bloquea](https://github.com/Francoocicchetti/Vocalia/blob/v1.0.0/INSTALL-MAC.es.md)**.

Elige el idioma de interfaz y audio, prepara el modelo y carga tus archivos. El reconocimiento es local. Ambas versiones incluyen texto completo, cuñas, carga múltiple y resaltado. Windows no incluye separación automática de voces.

Se mantienen el historial y los límites indicados arriba. Las pruebas de Windows se hicieron en Windows Server x64, no en un PC Windows 11 real. Mac no está notarizada y Windows no tiene firma Authenticode. Revisa nombres, cifras y citas. **[Guía en español](https://github.com/Francoocicchetti/Vocalia/blob/v1.0.0/README.es.md)**.
