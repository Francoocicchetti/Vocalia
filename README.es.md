<p align="center"><img src="logo.png" width="128" alt="Icono de Vocalia"></p>

# Vocalia 1.0.1

**Transcripción local para periodistas: texto completo, cuñas y audio resaltado.**

[English](README.md) · **Español**

## Descargar la aplicación

### [↓ Descargar para Windows 11 — Intel / AMD](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-Windows-x64-Setup.exe)

### [↓ Descargar para MacBook / Mac — Apple Silicon](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-macOS-AppleSilicon.zip)

**[Ver la Release oficial 1.0 y todas las descargas](https://github.com/Francoocicchetti/Vocalia/releases/tag/v1.0.1)**

En la página de la Release, abre **Assets** y elige el instalador **Setup.exe** para Windows o el ZIP para Mac. **No descargues “Source code” para instalar la app.**

- **Windows:** Windows 11 Intel/AMD de 64 bits. Descarga y ejecuta **Vocalia-1.0.1-Windows-x64-Setup.exe**, sigue el asistente y abre **Vocalia** desde Inicio. Puedes crear un acceso directo en el escritorio. [Guía Windows](WINDOWS.es.md).
- **MacBook/Mac:** Apple Silicon M1 o posterior y macOS 26+. No admite Mac Intel. Descomprime y arrastra **Vocalia.app** a **Aplicaciones**. **[Cómo instalarla y usar “Abrir igualmente” si macOS la bloquea](INSTALL-MAC.es.md)**.

No necesitas Python, Xcode, una cuenta de transcripción ni claves de API para usar las descargas. Elige el idioma de interfaz y audio, prepara los modelos y agrega tus archivos. Los modelos necesitan internet para descargarse; después el reconocimiento es local.

## Estado de la versión

1.0 unifica la numeración pública; las anteriores eran versiones de desarrollo. No implica certificación de Apple/Microsoft ni precisión perfecta. Mac tiene firma local sin notarización; Windows no tiene firma Authenticode. Las pruebas de Windows se ejecutan en Windows Server x64; falta validación de uso en Windows 11 real. Revisa nombres, cifras y citas contra el original.

## Funciones según la plataforma

Ambas versiones incluyen carga múltiple, texto completo, resaltado, cuñas, diccionario y exportación TXT/SRT/VTT. Windows utiliza Whisper en CPU, acepta archivos de menos de dos horas y no incluye separación automática de voces ni comparación con Apple. [Guía Windows](WINDOWS.es.md).

Las secciones siguientes describen las funciones de la edición nativa para Mac.

## Qué incluye

- MP3, MP4, MOV, M4A, WAV y otros formatos compatibles con macOS.
- Carga de muchos archivos o carpetas y procesamiento por cola.
- Texto completo editable y exportación TXT, SRT y VTT.
- Resaltado sincronizado y seguimiento de la reproducción.
- Diccionario de nombres, instituciones y siglas.
- Cuñas literales con fuente, hablante y tiempos.
- Comparación opcional entre Apple Speech y Whisper.
- Agrupación automática de voces con nombres editables.
- Interfaz en español e inglés; selección independiente del idioma del audio.
- Descarga del idioma antes de transcribir y modelos adicionales locales.

## Primer uso

1. Elige el idioma de los controles en **Interfaz**.
2. Elige el idioma hablado en **Idioma del audio** y pulsa **Descargar idioma** si hace falta.
3. Agrega archivos o carpetas y pulsa **Transcribir pendientes**.
4. Revisa el texto y las citas contra el original antes de publicarlas.

Los modelos se descargan una vez cuando sean necesarios. Las grabaciones no se envían a servicios de transcripción. La app no necesita una cuenta ni una clave de API. Compartir este repositorio no comparte tu historial local.

## Límites claros

- La app nativa para Mac requiere Apple Silicon y macOS 26; no admite Mac Intel. La edición Windows tiene sus propios [requisitos y límites](WINDOWS.es.md).
- La transcripción principal acepta grabaciones de menos de 24 horas; comparación y voces, de menos de 2 horas.
- No promete precisión perfecta: revisa especialmente nombres, cifras y voces superpuestas.
- Los fragmentos antiguos sin tiempos por palabra se resaltan por fragmento.
- El texto completamente reescrito puede perder su correspondencia con el audio.
- Los mensajes del sistema y sus menús nativos siguen el idioma de macOS.

## Compilar

Necesitas las herramientas de desarrollo de Apple con SDK de macOS 26 o posterior y Swift 6.3 o compatible.

```sh
zsh build.sh
```

El script compila las bibliotecas incluidas, ejecuta las pruebas y genera `dist/Vocalia.zip`. Las pruebas usan datos sintéticos y no requieren grabaciones personales ni descargar modelos. No se incluyen modelos de aprendizaje automático en este repositorio.

## Componentes y licencias

Usa Apple SpeechAnalyzer, WhisperKit y SpeakerKit. Las fuentes de Argmax se incluyen con su [licencia](THIRD_PARTY_LICENSE), [avisos](THIRD_PARTY_NOTICES) y [revisión de origen](THIRD_PARTY_ORIGIN.txt). Los modelos conservan las condiciones de sus respectivos proveedores. No se ha asignado una licencia de código abierto al código propio ni al logo de Vocalia.

Las bibliotecas de terceros, con sus fuentes completas y licencias, están en `Vendor.zip`. El script de compilación las extrae en una carpeta temporal. El código propio se puede consultar directamente en los archivos Swift de este repositorio.

## Novedades de 1.0.1

- Elige español o inglés antes de entrar al área de trabajo la primera vez. Después puedes cambiar el idioma dentro de Vocalia.
- Tutorial que puedes volver a abrir: agregar audios, preparar el modelo, transcribir, revisar y copiar el texto completo.
- Windows: **agregar un audio no lo transcribe**. Pulsa **Transcribir pendientes**. Si falta el modelo, acepta descargarlo; al terminar empieza la transcripción automáticamente.
- Avisos claros si no hay pendientes, falta el modelo o falla el motor. Al solicitar una transcripción se detiene la reproducción; escuchar queda desactivado mientras hay un trabajo en curso.

