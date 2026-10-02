# Vocalia 0.0.7 — Preview · Bulk actions

Select several recordings and work with them together, on Mac and Windows.

## Download

- **[Windows 11 — Intel/AMD installer](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.7/Vocalia-0.0.7-Windows-x64-Setup.exe)**
- **[Mac — Apple Silicon, macOS 26+](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.7/Vocalia-0.0.7-macOS-AppleSilicon.zip)**
- Already using Vocalia? Choose **Update Vocalia** in the app. History and downloaded models are preserved.
- Mac installation: extract the ZIP, move Vocalia to Applications and follow the [first-launch guide](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.md) if macOS blocks this non-notarized preview.

## What changed

- Check individual recordings or choose **Select all**. A counter shows how many recordings are selected; the × button clears the selection.
- Opening a recording or advancing the transcription queue does not change the checked group.
- **Actions for selection:** transcribe selected pending recordings, transcribe the group again, assign a project, export separate TXT/SRT/VTT/Word documents, or remove the group from history.
- Removal asks for confirmation with the selected count. **Original audio/video files are never deleted.** Restore the last removed group, including edits and quotes, even after restarting the app.
- Retranscription asks for confirmation and saves previous text as revisions. Exports keep existing files instead of overwriting them. Word exports include each recording's saved quotes.
- Bulk actions are disabled during importing or processing. All new controls are available in the six interface languages.

Both native build jobs must pass before publication, including batch recovery, stale editor callbacks, selected-only exports, existing transcription/audio checks and installer upgrades. The Windows CI machine runs Windows Server 2025 x64; this remains a preview and does not guarantee compatibility with every Windows 11 device.

## Español

Marca las casillas de las grabaciones o pulsa **Seleccionar todos**. El contador muestra cuántas están marcadas; la **×** desmarca el grupo. Abrir un audio no cambia la selección.

En **Acciones para la selección** puedes transcribir pendientes, volver a transcribir el grupo, asignar un proyecto, exportar TXT/SRT/VTT/Word o quitar grabaciones del historial. **Los archivos originales se conservan.** La eliminación pide confirmación y puedes usar **Restaurar último grupo** incluso después de cerrar la app.

Actualiza desde **Actualizar Vocalia** o utiliza los enlaces de descarga de arriba. Se conservan el historial y los modelos descargados.
