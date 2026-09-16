# Vocalia 1.0.2 — six languages and Windows feature update

## Download the application

- **[Windows 11 · Intel/AMD installer](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.2/Vocalia-1.0.2-Windows-x64-Setup.exe)**
- **[MacBook / Mac · Apple Silicon, macOS 26+](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.2/Vocalia-1.0.2-macOS-AppleSilicon.zip)**

Files are under **Assets**. Use the installer or Mac ZIP, not “Source code”. The Windows portable ZIP must be completely extracted before launch.

Choose English, Spanish, German, French, Simplified Chinese or Portuguese before entering the app. The interactive tutorial remains available inside it. Recording language is selected separately.

Windows now includes segment review, independent comparison using two Whisper models, optional local speaker grouping and naming, timed voice review, more quote actions, speed controls, a dictionary editor, drag-and-drop and selected retranscription with a saved revision. Imports requested during transcription are added after the active queue finishes. Download required models once; recordings stay on your computer.

Mac uses Apple Speech with optional Whisper/SpeakerKit. Windows uses CPU Whisper and sherpa-onnx. Engines and duration limits differ; [see the feature matrix and 1.0 → 1.0.2 update table](https://github.com/Francoocicchetti/Vocalia/blob/main/README.md).

**Mac first launch:** extract and move Vocalia.app to Applications. If blocked, follow [Apple's Open Anyway flow](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.md). This app is not notarized; Windows is not Authenticode-signed.

Automated Windows checks cover packaged recognition, comparison, a public four-speaker recording, the six-language interface/tour, history and installation. They run on Windows Server x64; physical Windows 11 validation is still pending. Review all quotations against the audio.

Checksums: `SHA256SUMS-1.0.2.txt`. Complete source: `Vocalia-1.0.2-source.zip`. Installation validation: `Windows-1.0.2-Validation.txt`.

---

## Español

**Descarga el instalador de Windows o el ZIP para Mac en los enlaces de arriba o en Assets.** No elijas «Source code» para instalar.

La versión 1.0.2 incorpora español, inglés, alemán, francés, chino simplificado y portugués, con elección antes de entrar y cambio posterior dentro de la app. El idioma del audio se configura por separado.

Windows suma revisión de fragmentos, comparación entre dos modelos, agrupación local de voces y nombres, revisión con tiempos, más acciones para cuñas, velocidad, diccionario, arrastrar archivos y volver a transcribir guardando una copia previa. Los archivos agregados durante una transcripción se incorporan al terminar la cola. Los modelos se descargan una vez; tus grabaciones se quedan en el equipo.

[Tabla de actualizaciones 1.0, 1.0.1 y 1.0.2](https://github.com/Francoocicchetti/Vocalia/blob/main/README.es.md) · [Instalación en Mac y Abrir de todos modos](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.es.md) · [Guía Windows](https://github.com/Francoocicchetti/Vocalia/blob/main/WINDOWS.es.md)

Mac requiere Apple Silicon y macOS 26+. Windows requiere Windows 11 Intel/AMD de 64 bits. Los motores y límites difieren según plataforma. Las pruebas automatizadas de Windows se realizan en Windows Server; falta validación en hardware Windows 11 real. Revisa nombres, cifras y cuñas con el audio.
