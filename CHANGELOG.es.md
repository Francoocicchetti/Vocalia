## Novedades de 1.0.1

- Elige español o inglés antes de entrar al área de trabajo la primera vez. Después puedes cambiar el idioma dentro de Vocalia.
- Tutorial que puedes volver a abrir: agregar audios, preparar el modelo, transcribir, revisar y copiar el texto completo.
- Windows: **agregar un audio no lo transcribe**. Pulsa **Transcribir pendientes**. Si falta el modelo, acepta descargarlo; al terminar empieza la transcripción automáticamente.
- Avisos claros si no hay pendientes, falta el modelo o falla el motor. Al solicitar una transcripción se detiene la reproducción; escuchar queda desactivado mientras hay un trabajo en curso.

# Notas de versión

## 1.0 — primera versión pública unificada

- Una Release para Mac y Windows, con descargas directas y guías bilingües.
- Instrucciones oficiales de Apple para la primera apertura.
- Numeración pública 1.0, conservando historial y preferencias.
- Windows: idioma inicial según el sistema, ventana adaptable, mensajes más claros y copia de revisiones antes de reintentar.

[English](CHANGELOG.md)

## Mac 2.2.1 / Windows 0.1.1 preliminar

- Icono recortado, con bordes redondeados y tamaños nativos para ambos sistemas.
- GitHub en inglés como idioma principal y documentación en español enlazada.
- Instrucciones de Windows en inglés y español.
- Esta actualización de imagen y documentación conserva los motores de reconocimiento y el historial existente.

## Windows 0.1.0 preliminar

- Whisper local en CPU, ejecutado en un proceso separado.
- Carga múltiple, texto completo, resaltado, cuñas y exportación TXT/SRT/VTT.
- Historial SQLite con eliminación recuperable y edición por identificadores.
- Pruebas del ejecutable: historial, fallos del proceso, rutas con tildes, archivos dañados y transcripción FLAC/MP3/MP4/MOV sin conexión.
- Corrección del bloqueo de archivos al abrir un historial dañado y lectura UTF-8.

## Mac 2.2 preliminar

- Corrección del cierre al quitar o reordenar entradas del historial.
- Interfaz español/inglés y selección independiente del idioma del audio.
- Descarga explícita de idiomas; Whisper utiliza el idioma registrado en cada transcripción.
- Nuevo logo y correcciones del seguimiento de audio.
- 48 comprobaciones del núcleo y funciones adicionales.

## Compatibilidad OPUS en 1.0.1

Descarga los archivos que incluyen **OPUS** en el nombre. Ambas versiones aceptan `.opus` y archivos Ogg que contienen Opus (`.ogg`), también por lotes y carpetas. No necesitas convertirlos ni subir el audio a un servidor. Mac incorpora un decodificador local y usa una copia PCM temporal para transcribir y escuchar; se elimina al cerrar normalmente la app y se conserva el original. OPUS en Mac admite grabaciones de menos de diez horas; Windows mantiene el límite de dos horas. No incluye Ogg/Vorbis.

Los nuevos archivos se verifican con **SHA256SUMS-GuideFix.txt**. El código actualizado está en main y en **Vocalia-1.0.1-GuideFix-source.zip** de Releases; el Source code automático de la etiqueta corresponde a la compilación inicial.
