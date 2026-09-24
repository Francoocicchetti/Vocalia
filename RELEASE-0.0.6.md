# Vocalia 0.0.6 — Preview

Local audio review for journalists. Your recordings stay on your computer.

## Downloads

- **[Download for Windows 11 — Intel/AMD](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.6/Vocalia-0.0.6-Windows-x64-Setup.exe).** Run the installer; it preserves your history and models.
- **[Download for Mac — Apple Silicon, macOS 26+](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.6/Vocalia-0.0.6-macOS-AppleSilicon.zip).** Extract and move Vocalia to Applications. If macOS blocks this unsigned preview, follow [the Mac installation guide](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.md).
- Existing revised 0.0.5 installations: choose **Update Vocalia** inside the app.

## Changes

- Click a timed word to start playback there. Turn off **Click words to play** when editing. Modified or ambiguous text never receives invented timestamps.
- Repeat the recording or select timed words and choose **Repeat selection**. Pause or stop repeating whenever needed.
- **Clean audio** creates a separate local copy with gentle low-frequency rumble reduction and bounded volume normalization. **Use cleaned audio** switches listening and deliberate retranscription to that copy. Originals and existing text stay intact. Cleanup supports recordings under two hours; it does not remove other speakers, repair clipping, or guarantee better recognition.
- Optional Whisper large-v3: available as a full architecture comparison model on Mac (compressed weights) and as a transcription/comparison model on Windows. More memory and time are required. It is not automatically selected or downloaded.
- Windows dictionary terms also feed the decoder's hotword hints; low word confidence flags the segment for review. Names and figures still require checking against the original.
- Direct PCM reading improves WAV/CAF/AIFF preparation on Mac.
- Controls translated into Spanish, English, German, French, Chinese and Portuguese.

This is a preview. No measured universal accuracy gain is claimed; model choice and cleanup can help some recordings and hurt others. Compare with the original before quoting.

## Validation

Publication requires both native [build and test jobs](https://github.com/Francoocicchetti/Vocalia/actions/workflows/windows.yml) to pass. Checks cover actual packaged Windows transcription in six audio/video formats, Qt interactions, audio review, history compatibility, Mac OPUS decoding/cleanup, and installation/update preservation. The Windows runner is Windows Server 2025 x64; physical Windows 11 Intel/AMD playback and recognition on representative Chilean Spanish interviews still need field evaluation.

## Español

Pulsa una palabra para escuchar desde ahí; desactiva esa opción para editar. Repite el audio completo o una selección. **Limpiar audio** crea una copia local que reduce retumbes y ajusta el volumen. **Usar audio limpio** permite escuchar o volver a transcribir esa copia; conserva el original y el texto anterior hasta que decidas transcribir de nuevo. La limpieza admite grabaciones de menos de dos horas.

Whisper large-v3 es opcional y consume más memoria y tiempo. Las palabras de baja confianza se señalan para revisión en Windows. Revisa nombres y cifras con el original: ninguna configuración garantiza una transcripción perfecta.
