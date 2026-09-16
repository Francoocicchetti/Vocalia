# Vocalia 1.0.1 — OPUS support

## OPUS support in 1.0.1

Use the downloads with **OPUS** in their filename. Both platforms accept `.opus` and Ogg files containing Opus (`.ogg`), including batch/folder import. No manual conversion or audio upload is needed. Windows uses its bundled decoder. Mac includes a local BSD-licensed Opus decoder and uses a temporary PCM copy for transcription and playback; normal app exit removes that copy and the original is preserved. Mac OPUS recordings must be under ten hours; Windows keeps its two-hour limit. Ogg/Vorbis is not included.

New downloads have checksums in **SHA256SUMS-Tour.txt**; the original 1.0.1 files remain available for reproducibility. The updated source is on the main branch and in **Vocalia-1.0.1-Tour-source.zip** in Releases. The tag's automatic Source code archives describe the original 1.0.1 build.

Mac validation: real Ogg Opus decoding, playable PCM, native speech recognition and aligned timestamps. Windows validation: real OPUS through the GUI Transcribe button; packaged engine tests cover OPUS and Ogg Opus alongside existing formats. Windows CI runs on Windows Server x64; physical Windows 11 confirmation remains pending.

## Compatibilidad OPUS en 1.0.1

Descarga los archivos que incluyen **OPUS** en el nombre. Ambas versiones aceptan `.opus` y archivos Ogg que contienen Opus (`.ogg`), también por lotes y carpetas. No necesitas convertirlos ni subir el audio a un servidor. Mac incorpora un decodificador local y usa una copia PCM temporal para transcribir y escuchar; se elimina al cerrar normalmente la app y se conserva el original. OPUS en Mac admite grabaciones de menos de diez horas; Windows mantiene el límite de dos horas. No incluye Ogg/Vorbis.

Los nuevos archivos se verifican con **SHA256SUMS-Tour.txt**. El código actualizado está en main y en **Vocalia-1.0.1-Tour-source.zip** de Releases; el Source code automático de la etiqueta corresponde a la compilación inicial.
