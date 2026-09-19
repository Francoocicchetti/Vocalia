# Vocalia 0.0.5 — Preview

Still in development, not a stable 1.0 release. Existing history is preserved.

## Download

- [Windows 11 Intel/AMD — installer](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.5/Vocalia-0.0.5-Windows-x64-Setup.exe)
- [Mac Apple Silicon — app ZIP](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.5/Vocalia-0.0.5-macOS-AppleSilicon.zip) — macOS 26 or later.

Use these downloads, not GitHub's generic “Source code” links. Windows portable ZIP and complete source are also under Assets.

## Installer revision — integrated updates

Mac build 18 · Windows file version 0.0.5.1. Public version remains 0.0.5. Download this revision once to get the integrated updater.

## What's new on both platforms

- In-app update downloads with progress, cancellation, SHA256 verification and installation preserving local data.
- Search every transcript and listen to matching segments; edited text is only timed when a reliable match exists.
- Projects, tags and editable recording dates, with library filters.
- A figures-only view to listen, correct and review numeric segments.
- Word (.docx) export: title, date, full edited transcript and selected saved quotes.

Six interface languages, automatic transcription and manual speaker analysis remain available. The app does not upload your recordings. Update checks contact GitHub and can be disabled. Older 1.x prototype tags are ignored by the update checker.

## Install / upgrade

Close Vocalia first. Windows: run the installer under the same user and location. Mac: replace Vocalia.app in Applications. Do not remove the separate history/data folders. On Mac, this ad-hoc signed build is not notarized; if blocked, follow [Privacy & Security → Open Anyway](https://github.com/Francoocicchetti/Vocalia/blob/main/INSTALL-MAC.md). Windows is not Authenticode-signed.

Automated release checks cover the packaged Windows GUI, history, library, Word export, update selection, real format transcription, comparison, speakers, installer upgrade, reinstall and uninstall preservation. Mac regression checks and Word render checks accompany the build. Windows CI uses a Windows Server x64 runner, not a physical Windows 11 PC; recognition still needs human review.

## Español

Avisos de nuevas versiones y sus cambios; búsqueda en todas las transcripciones con escucha del fragmento; proyectos, etiquetas y fechas; vista de revisión de cifras; exportación Word del texto completo editado con cuñas seleccionadas.

Versión preliminar, todavía en desarrollo. Descarga el instalador de Windows o el ZIP de Mac de los enlaces de arriba. Cierra Vocalia antes de instalar; conserva el mismo usuario y la carpeta de datos para mantener historial, cuñas, proyectos y modelos. La actualización no se instala sin tu intervención. Las grabaciones no se suben; las consultas de versiones contactan GitHub y se pueden desactivar.

[Guía en español](https://github.com/Francoocicchetti/Vocalia/blob/main/README.es.md) · [English guide](https://github.com/Francoocicchetti/Vocalia/blob/main/README.md)

## In-app updater — 0.0.5 installer revision

The **Update Vocalia** button now downloads the update inside the app, shows progress, supports cancellation and verifies its SHA256 digest against the official GitHub release metadata before installation. It never opens GitHub to download the app.

- **Windows:** after verification, choose **Install update**. Vocalia saves edits, closes and starts its local setup wizard in the current installation folder. Complete the wizard to reopen Vocalia. Installation is blocked while transcription or imports are running.
- **Mac:** choose **Install and restart**. Vocalia prepares and verifies the new application, saves history, replaces only the app and reopens it. A previous-app copy is kept beside the installed app for recovery. Vocalia must be in a writable Applications folder, outside a mounted image or an App Translocation location. System security protections are not disabled.
- History, quotes, projects, settings and model folders stay in their existing locations. Cancelling a download or failing verification does not change the installed app. Mac replacement failures attempt to restore the prior app.
- **One-time transition:** users of the original 0.0.5 must install this revised 0.0.5 once using the download links above. That original build cannot install this same-version revision itself. Future higher-numbered releases can be downloaded and installed through the new button.

The public version remains **0.0.5**. This revision uses Mac build **18** and Windows file version **0.0.5.1**. The current complete source is `Vocalia-0.0.5-source.zip`; the original `v0.0.5` Git tag and GitHub-generated “Source code” snapshots remain the initial release. See the linked build run for the exact revision used for these installers.

## Actualizador integrado — revisión de instaladores 0.0.5

El botón **Actualizar Vocalia** descarga dentro de la app, muestra el progreso, permite cancelar y verifica la suma SHA256 del archivo con los datos oficiales de GitHub antes de instalar. No abre GitHub para descargar la app.

- **Windows:** después de verificar, pulsa **Instalar actualización**. Vocalia guarda las ediciones, se cierra y abre el asistente local en la carpeta actual. Completa el asistente para volver a abrir Vocalia. No permite instalar mientras hay transcripciones o importaciones activas.
- **Mac:** pulsa **Instalar y reiniciar**. Vocalia prepara y verifica la nueva aplicación, guarda el historial, reemplaza solo la app y vuelve a abrirla. Guarda una copia de la aplicación anterior al lado para recuperación. La app debe estar en una carpeta Aplicaciones con permiso de escritura, fuera de imágenes montadas o ubicaciones de App Translocation. No se desactivan protecciones del sistema.
- El historial, las cuñas, proyectos, ajustes y modelos permanecen en sus ubicaciones habituales. Cancelar o fallar la verificación no modifica la app instalada. Si falla el reemplazo en Mac, intenta restaurar la app anterior.
- **Transición por única vez:** quien tenga la primera 0.0.5 debe instalar una vez esta revisión usando los enlaces de descarga. La primera 0.0.5 no puede instalar por sí sola una revisión con el mismo número. Las futuras versiones con numeración superior se podrán descargar e instalar con el nuevo botón.

Se mantiene la versión pública **0.0.5**: compilación **18** en Mac y versión de archivo **0.0.5.1** en Windows. El código completo actual está en `Vocalia-0.0.5-source.zip`; la etiqueta original `v0.0.5` y los archivos “Source code” que genera GitHub conservan la publicación inicial. La ejecución de compilación enlazada identifica el código exacto de estos instaladores.

