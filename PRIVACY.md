# Privacidad / Privacy

Vocalia procesa el audio en el Mac. No implementa cuentas, analítica ni un servicio de transcripción remoto. Apple administra sus propios modelos de idioma; los complementos descargan modelos y archivos de tokenización desde sus proveedores. El funcionamiento de los servicios del sistema está sujeto a los ajustes y políticas de macOS.

El historial, las cuñas y los modelos se guardan en Application Support. Por compatibilidad con versiones anteriores, la carpeta de datos se llama `Franco Transcribe` y el identificador interno permanece sin cambios. Cambiar el nombre visible no elimina datos. Los originales no se modifican. La conversión usa archivos temporales que se eliminan al terminar normalmente; un cierre forzado puede dejar temporales.

Las exportaciones se guardan donde el usuario elija. Si esa carpeta está sincronizada, el servicio correspondiente puede sincronizarlas. El repositorio público no incluye ningún historial, grabación, transcripción real ni modelo descargado.

---

Vocalia processes audio on your Mac. It implements no accounts, analytics or remote transcription service. Apple manages its speech assets; additional engines download model and tokenizer files from their providers. System services are governed by macOS settings and policies.

History, quotes and models live in Application Support. For upgrade compatibility, the storage directory is still named `Franco Transcribe` and the internal app identifier is unchanged. Original recordings are not modified. Temporary conversions are removed on normal completion; force-quitting may leave temporary files.

Exports go to the destination you select. A synced destination may upload those exports through its own service. This public repository contains no personal recordings, real transcripts, user history or downloaded models.
