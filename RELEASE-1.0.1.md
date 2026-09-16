# Vocalia 1.0.1 — Interactive in-app tour

## Download

### [↓ Windows 11 Intel/AMD — installer](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-Windows-x64-GuideFix-Setup.exe)
### [↓ Mac Apple Silicon, macOS 26+](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-macOS-AppleSilicon-GuideFix.zip)

Windows: run Setup.exe and follow the installer. Mac: extract the ZIP, move Vocalia.app to Applications and open it. [Mac first-launch guide](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.md). Do not download Source code to install the app.

## Interactive tour update

Download the **GuideFix** builds above for anchored speech bubbles inside the app, highlighted controls, Next, Back, Skip and replay from **How to use Vocalia**. The language picker remains before the workspace on first launch. Existing users see the new tour once. OPUS support is included.

## OPUS support added to 1.0.1

**Download the files with GuideFix in their name above.** Both platforms now import and transcribe `.opus`, including batch/folder import, plus `.ogg` files containing Opus. Mac bundles a local decoder for transcription and playback; no manual conversion or recording upload is required. Originals stay intact. Mac OPUS recordings must be under ten hours; Windows keeps its two-hour limit. Ogg/Vorbis is not supported.

Mac validation used real OPUS audio: import, local decoding, playable audio, native transcription and aligned timestamps passed. Windows checks use real OPUS through the Transcribe button and offline recognition tests. Windows checks run on Windows Server x64; physical Windows 11 confirmation remains pending.

Original 1.0.1 assets remain available. Updated source is in **Vocalia-1.0.1-GuideFix-source.zip** and the main branch; automatic Source code archives belong to the original tag. **SHA256SUMS-GuideFix.txt** verifies the updated packages.

## New in 1.0.1

- Choose English or Spanish before entering the workspace on first launch. Change the app language later inside Vocalia.
- A replayable tutorial explains adding recordings, preparing a model, transcribing, reviewing and copying the full text.
- Windows: **adding a recording does not transcribe it**. Click **Transcribe pending**. If the model is missing, accept its download; transcription then starts automatically.
- Clear empty-queue, missing-model and worker-failure messages. Playback stops when transcription is requested and is unavailable while a job is running.

## Validation and limits

Windows checks exercise the actual Transcribe button from an unprepared model through download, local recognition and copying the full transcript of a public test recording. Packaged tests also cover offline FLAC/MP3/MP4/MOV recognition, history, worker failures, Unicode paths, installation and data-preserving uninstall. These run on Windows Server x64; the reported colleague's Windows 11 computer still needs confirmation. We have not reproduced audio playback caused by the Transcribe button and do not claim all possible transcription failures are fixed.

Mac has core checks and a new first-run guide. Recordings stay on your computer. Downloading models needs internet. No Apple notarization or Windows Authenticode certificate; security prompts may remain. Recognition can make mistakes; review names, numbers and quotes. Windows supports recordings under two hours; Mac main engine under 24 hours, optional engines under two hours. Windows ARM and Intel Macs are unsupported. Existing history and models are retained.

SHA256SUMS-GuideFix.txt contains checksums for the updated OPUS downloads and their source bundle. SHA256SUMS.txt refers to the original downloads. [English guide](https://github.com/Francoocicchetti/Vocalia/blob/main/README.md).

---

## Español

**[Instalador Windows](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-Windows-x64-GuideFix-Setup.exe)** · **[Mac](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-macOS-AppleSilicon-GuideFix.zip)**

## Guía interactiva dentro de la app

Las descargas **GuideFix** incluyen globos junto a los controles, resaltado, Siguiente, Atrás, Omitir y la opción de repetir desde **Cómo usar Vocalia**. El idioma se sigue eligiendo antes de entrar la primera vez. Los usuarios existentes verán la guía nueva una vez. Incluye soporte OPUS.

## OPUS añadido a 1.0.1

**Descarga los archivos que incluyen GuideFix en el nombre.** Mac y Windows ahora admiten archivos `.opus` y Ogg con Opus (`.ogg`), individualmente o por lotes y carpetas. Mac incluye un decodificador local para transcribir y escuchar, sin conversión manual ni envío de grabaciones. Los originales se conservan. OPUS en Mac admite menos de diez horas; Windows mantiene menos de dos horas. No admite Ogg/Vorbis.

El código actualizado está en **Vocalia-1.0.1-GuideFix-source.zip** y main. Los archivos originales siguen disponibles; **SHA256SUMS-GuideFix.txt** corresponde a las descargas nuevas.

## Novedades de 1.0.1

- Elige español o inglés antes de entrar al área de trabajo la primera vez. Después puedes cambiar el idioma dentro de Vocalia.
- Tutorial que puedes volver a abrir: agregar audios, preparar el modelo, transcribir, revisar y copiar el texto completo.
- Windows: **agregar un audio no lo transcribe**. Pulsa **Transcribir pendientes**. Si falta el modelo, acepta descargarlo; al terminar empieza la transcripción automáticamente.
- Avisos claros si no hay pendientes, falta el modelo o falla el motor. Al solicitar una transcripción se detiene la reproducción; escuchar queda desactivado mientras hay un trabajo en curso.

En Windows, ejecuta Setup.exe y abre Vocalia desde Inicio. En Mac, descomprime y mueve Vocalia.app a Aplicaciones. [Guía de primera apertura para Mac](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.es.md).

Las pruebas de Windows usan el botón real y un audio público para comprobar descarga del modelo, generación del texto y copia. Se ejecutan en Windows Server x64; falta confirmar el resultado en el equipo Windows 11 que reportó el problema. No se ha reproducido que el botón Transcribir active la reproducción. Se conservan los límites indicados arriba, el historial y los modelos. Los avisos de seguridad pueden seguir apareciendo porque no hay certificados comerciales. [Guía en español](https://github.com/Francoocicchetti/Vocalia/blob/main/README.es.md).

## Startup and tour display fix

The **GuideFix** downloads restore the language picker once on first launch after this update, including existing installations. Your choice is remembered afterwards and remains changeable inside the app. Mac tutorial bubbles now use an opaque background and clear keyboard focus from underlying controls to prevent focus outlines crossing the tutorial. Background editing is paused during the tour and restored when it closes.

## Corrección del inicio y la guía

Las descargas **GuideFix** vuelven a mostrar la elección de idioma una vez al abrir esta actualización, también en instalaciones anteriores. Después se recuerda tu elección y puedes cambiarla dentro de la app. En Mac, los globos tienen fondo opaco y retiran el foco de los controles inferiores para impedir que sus bordes atraviesen el tutorial. La edición del fondo se pausa durante el recorrido y vuelve a activarse al cerrarlo.
