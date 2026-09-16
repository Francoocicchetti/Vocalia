<p align="center"><img src="logo.png" alt="Vocalia" width="180"></p>

# Vocalia

**Transcripción local para periodistas, entrevistas y cuñas.**

[English](README.en.md) · [Guía completa](GUIA.md) · [Privacidad](PRIVACY.md)

Vocalia convierte audio y video en un texto completo y editable en tu Mac. Puedes copiar toda una entrevista, escuchar el fragmento resaltado mientras avanza el audio y guardar citas con su fuente y tiempo.

## Windows 11 (Intel / AMD)

Hay una versión independiente para Windows 11 x64: **[descargas e instrucciones](WINDOWS.md)**. Conserva la transcripción local, texto completo, cuñas y seguimiento del audio. Es preliminar y no incluye el motor Apple ni la separación automática de voces. Las secciones siguientes describen la app nativa para Mac.

## Descargar para Mac

**Versión de prueba 2.2 — Apple Silicon y macOS 26 o posterior.**

[Descargar Vocalia para Mac](https://github.com/Francoocicchetti/Vocalia/raw/refs/heads/main/Vocalia-2.2-macOS.zip)

Descomprime el ZIP y arrastra Vocalia.app a Aplicaciones. La aplicación tiene firma local, pero **todavía no está notarizada por Apple**; macOS puede bloquear su primera apertura. Consulta el [procedimiento de Apple para apps de desarrolladores no identificados](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac). No requiere desactivar las protecciones generales del Mac. Si prefieres, puedes compilarla desde este código.

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

- La app nativa para Mac requiere Apple Silicon y macOS 26; no admite Mac Intel. La edición Windows tiene sus propios [requisitos y límites](WINDOWS.md).
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

## Estado de la versión

2.2 corrige el cierre al limpiar el historial, añade idioma de interfaz y descarga explícita de idiomas, y estrena el logo de Vocalia. Se ejecutaron 48 comprobaciones del núcleo y las funciones adicionales. Esta es una versión de prueba: esas comprobaciones no garantizan ausencia de otros errores ni miden precisión del reconocimiento.

Para informar un fallo, abre un issue con los pasos, la versión de macOS y el formato y duración aproximada del archivo. **No publiques grabaciones, transcripciones, nombres de fuentes ni registros sin revisar su contenido.**

## Componentes y licencias

Usa Apple SpeechAnalyzer, WhisperKit y SpeakerKit. Las fuentes de Argmax se incluyen con su [licencia](THIRD_PARTY_LICENSE), [avisos](THIRD_PARTY_NOTICES) y [revisión de origen](THIRD_PARTY_ORIGIN.txt). Los modelos conservan las condiciones de sus respectivos proveedores. No se ha asignado una licencia de código abierto al código propio ni al logo de Vocalia.

Las bibliotecas de terceros, con sus fuentes completas y licencias, están en `Vendor.zip`. El script de compilación las extrae en una carpeta temporal. El código propio se puede consultar directamente en los archivos Swift de este repositorio.
