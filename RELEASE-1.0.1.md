# Vocalia 1.0.1 — Getting started made clearer

## Download

### [↓ Windows 11 Intel/AMD — installer](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-Windows-x64-Setup.exe)
### [↓ Mac Apple Silicon, macOS 26+](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-macOS-AppleSilicon.zip)

Windows: run Setup.exe and follow the installer. Mac: extract the ZIP, move Vocalia.app to Applications and open it. [Mac first-launch guide](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.md). Do not download Source code to install the app.

## New in 1.0.1

- Choose English or Spanish before entering the workspace on first launch. Change the app language later inside Vocalia.
- A replayable tutorial explains adding recordings, preparing a model, transcribing, reviewing and copying the full text.
- Windows: **adding a recording does not transcribe it**. Click **Transcribe pending**. If the model is missing, accept its download; transcription then starts automatically.
- Clear empty-queue, missing-model and worker-failure messages. Playback stops when transcription is requested and is unavailable while a job is running.

## Validation and limits

Windows checks exercise the actual Transcribe button from an unprepared model through download, local recognition and copying the full transcript of a public test recording. Packaged tests also cover offline FLAC/MP3/MP4/MOV recognition, history, worker failures, Unicode paths, installation and data-preserving uninstall. These run on Windows Server x64; the reported colleague's Windows 11 computer still needs confirmation. We have not reproduced audio playback caused by the Transcribe button and do not claim all possible transcription failures are fixed.

Mac has core checks and a new first-run guide. Recordings stay on your computer. Downloading models needs internet. No Apple notarization or Windows Authenticode certificate; security prompts may remain. Recognition can make mistakes; review names, numbers and quotes. Windows supports recordings under two hours; Mac main engine under 24 hours, optional engines under two hours. Windows ARM and Intel Macs are unsupported. Existing history and models are retained.

SHA256SUMS.txt contains checksums for the three application downloads. [English guide](https://github.com/Francoocicchetti/Vocalia/blob/main/README.md).

---

## Español

**[Instalador Windows](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-Windows-x64-Setup.exe)** · **[Mac](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-macOS-AppleSilicon.zip)**

## Novedades de 1.0.1

- Elige español o inglés antes de entrar al área de trabajo la primera vez. Después puedes cambiar el idioma dentro de Vocalia.
- Tutorial que puedes volver a abrir: agregar audios, preparar el modelo, transcribir, revisar y copiar el texto completo.
- Windows: **agregar un audio no lo transcribe**. Pulsa **Transcribir pendientes**. Si falta el modelo, acepta descargarlo; al terminar empieza la transcripción automáticamente.
- Avisos claros si no hay pendientes, falta el modelo o falla el motor. Al solicitar una transcripción se detiene la reproducción; escuchar queda desactivado mientras hay un trabajo en curso.

En Windows, ejecuta Setup.exe y abre Vocalia desde Inicio. En Mac, descomprime y mueve Vocalia.app a Aplicaciones. [Guía de primera apertura para Mac](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.es.md).

Las pruebas de Windows usan el botón real y un audio público para comprobar descarga del modelo, generación del texto y copia. Se ejecutan en Windows Server x64; falta confirmar el resultado en el equipo de Michelson. No se ha reproducido que el botón Transcribir active la reproducción. Se conservan los límites indicados arriba, el historial y los modelos. Los avisos de seguridad pueden seguir apareciendo porque no hay certificados comerciales. [Guía en español](https://github.com/Francoocicchetti/Vocalia/blob/main/README.es.md).
