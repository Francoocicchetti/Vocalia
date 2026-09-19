# Vocalia 0.0.5 — Preview

Still in development, not a stable 1.0 release. Existing history is preserved.

## Download

- [Windows 11 Intel/AMD — installer](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.5/Vocalia-0.0.5-Windows-x64-Setup.exe)
- [Mac Apple Silicon — app ZIP](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.5/Vocalia-0.0.5-macOS-AppleSilicon.zip) — macOS 26 or later.

Use these downloads, not GitHub's generic “Source code” links. Windows portable ZIP and complete source are also under Assets.

## What's new on both platforms

- Update notifications, release notes and a user-initiated download/install path preserving local data.
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
