# Vocalia 1.0.3 — manual speaker analysis and decimal formatting

## Download

- **[Windows 11 · Intel/AMD installer](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.3/Vocalia-1.0.3-Windows-x64-Setup.exe)**
- **[Mac · Apple Silicon, macOS 26+](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.3/Vocalia-1.0.3-macOS-AppleSilicon.zip)**

Use these app downloads under Assets, not the automatic Source code files.

### Changes

- **Speaker separation is manual only.** Mac starts with it off, ignoring the previous automatic preference. Select it and click Analyze speakers / compare on a completed recording. It never runs after transcription. Windows remains explicitly user-triggered.
- **Spanish decimal formatting:** “9, coma, 5” → “9,5”; “12 coma 75 por ciento” → “12,75 por ciento”; “cero coma cero cinco” → “0,05”. This applies to clear decimal expressions across figures, percentages and amounts, based on the audio language.
- Original recognizer text is kept for review. Corrected decimals retain their audio interval and are used in full-text copying and subtitle exports.
- Figures are marked for listening/review even when recognition confidence is high. Reviewed marks are respected. Dates, lists and ambiguous expressions are not guessed; saved history is not rewritten.

This improves formatting and review, not a demonstrated overall speech-recognition accuracy rate. Review figures against the recording.

Six interface languages, OPUS, batch processing, comparison and the interactive tutorial remain available. Mac requires Apple Silicon and macOS 26+. Windows requires Windows 11 Intel/AMD x64; automated checks run on Windows Server, not physical Windows 11 PCs.

[Mac installation / Open Anyway](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.md). Mac is not notarized; Windows is not Authenticode-signed. Checksums: `SHA256SUMS-1.0.3.txt`.

---

## Español

**Separar voces ahora es una decisión manual.** Mac abre con esa opción desactivada, aunque estuviera activada en una versión anterior. Marca «Voces: análisis manual» y pulsa «Analizar voces / comparar» cuando lo necesites. No se ejecuta al terminar de transcribir. En Windows se inicia con «Analizar voces».

Los decimales explícitos en español se presentan como cifras: «9, coma, 5» → **9,5**, «12 coma 75 por ciento» → **12,75 por ciento**, «cero coma cero cinco» → **0,05**. Se conserva el texto original y el intervalo de audio; copiar y exportar usan el formato corregido. Las cifras se destacan para escuchar y revisar. No se modifican transcripciones antiguas ni se adivinan fechas, listas o cantidades ambiguas.

Un formato correcto no garantiza que el motor haya oído bien una cifra. No se ha medido una mejora global de precisión con entrevistas reales.

**Descarga Windows o Mac desde los enlaces de arriba o Assets.** [Instalación en Mac](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.es.md) · [Guía Windows](https://github.com/Francoocicchetti/Vocalia/blob/main/WINDOWS.es.md).
