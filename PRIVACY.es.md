# Privacidad

[English](PRIVACY.md) · [Inicio](README.es.md)

Vocalia procesa las grabaciones en tu computador. No incorpora cuentas de transcripción, analítica de la aplicación ni un servicio remoto de transcripción. La preparación descarga modelos desde sus proveedores. En Mac, los servicios de Apple están sujetos a los ajustes de macOS. En Windows, el reconocimiento carga modelos locales sin conexión; se desactiva la telemetría de Hugging Face y ONNX Runtime en el proceso de transcripción.

En Mac, el historial, las cuñas y los modelos están en `~/Library/Application Support/Franco Transcribe/`; el nombre y el identificador antiguos mantienen la compatibilidad. En Windows están en `%LOCALAPPDATA%\Vocalia`, con historial SQLite y modelos en `Models`. Las entradas quitadas del historial se conservan para recuperarlas; no se borran de forma segura. Al fallar o cancelar una transcripción se conserva el texto ya recibido por el editor.

Los originales no se modifican. Los temporales se eliminan al terminar normalmente; un cierre forzado puede dejarlos. Las exportaciones se guardan donde elijas; una carpeta sincronizada puede subirlas mediante su propio servicio.

El repositorio y las descargas no contienen historial, entrevistas personales, transcripciones del usuario ni modelos descargados. Las pruebas de Windows usan un fragmento público de JFK de las pruebas oficiales de OpenAI Whisper. Ese audio no se incluye en el ejecutable.

No publiques grabaciones sensibles, identidades de fuentes, transcripciones ni registros sin revisar en los issues.
