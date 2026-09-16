# Vocalia para Windows 11 (Intel / AMD, 64 bits)

Versión preliminar independiente de la app nativa para Mac. Las compilaciones solo se publican si pasan las pruebas de historial, interfaz y transcripción local del ejecutable.

[Descargas de Windows](https://github.com/Francoocicchetti/Vocalia/releases/tag/windows-v0.1.0-preview) · [Pruebas y compilación](https://github.com/Francoocicchetti/Vocalia/actions)

Descomprime todo el ZIP y abre Vocalia.exe dentro de la carpeta Vocalia; conserva la carpeta _internal. No requiere Python instalado. Selecciona Español o English y descarga un modelo desde la app. Después, la transcripción funciona localmente sin subir tus archivos.

Incluye importación de varios archivos y carpetas, cola, texto completo, resaltado durante reproducción, cuñas con fuente, exportación TXT/SRT/VTT e historial con recuperación de eliminados. Usa Whisper en CPU. No incluye el motor Apple ni separación automática de voces; puedes asignar nombres manualmente a las cuñas. Límite inicial: archivos menores a dos horas.

El código está en Vocalia-Windows-source.zip. Descomprímelo y revisa README.md para compilar mediante build.ps1. Las pruebas automáticas usan un fragmento público del discurso de JFK de la suite de pruebas de OpenAI Whisper, nunca entrevistas personales.

Estado: preliminar, sin certificación de estabilidad en todos los equipos Windows 11. GitHub ejecuta las pruebas en Windows Server x64; todavía necesita pruebas de uso con equipos Windows 11 reales. El ejecutable no tiene firma Authenticode.
