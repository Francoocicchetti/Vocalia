# Privacidad

[English](PRIVACY.md) · [Inicio](README.es.md)

Vocalia procesa las grabaciones en tu computador. No incorpora cuentas de transcripción, analítica de la aplicación ni un servicio remoto de transcripción. La preparación descarga modelos desde sus proveedores. En Mac, los servicios de Apple están sujetos a los ajustes de macOS. En Windows, el reconocimiento carga modelos locales sin conexión; se desactiva la telemetría de Hugging Face y ONNX Runtime en el proceso de transcripción.

En Mac, el historial, las cuñas y los modelos están en `~/Library/Application Support/Franco Transcribe/`; el nombre y el identificador antiguos mantienen la compatibilidad. En Windows están en `%LOCALAPPDATA%\Vocalia`, con historial SQLite y modelos en `Models`. Las entradas quitadas del historial se conservan para recuperarlas; no se borran de forma segura. Al fallar o cancelar una transcripción se conserva el texto ya recibido por el editor.

Los originales no se modifican. Los temporales se eliminan al terminar normalmente; un cierre forzado puede dejarlos. Las exportaciones se guardan donde elijas; una carpeta sincronizada puede subirlas mediante su propio servicio.

El repositorio y las descargas no contienen historial, entrevistas personales, transcripciones del usuario ni modelos descargados. Las pruebas de Windows usan un fragmento público de JFK de las pruebas oficiales de OpenAI Whisper. Ese audio no se incluye en el ejecutable.

No publiques grabaciones sensibles, identidades de fuentes, transcripciones ni registros sin revisar en los issues.

Los modelos opcionales de voces de Windows se descargan de las versiones públicas de sherpa-onnx en GitHub. El análisis y la comparación se ejecutan localmente. La prueba de voces usa una grabación pública de cuatro hablantes del mismo proveedor, nunca entrevistas privadas.

## Actualizaciones

Desde 0.0.5, la app consulta opcionalmente las versiones públicas de GitHub una vez al día y al pulsar Buscar ahora. GitHub recibe la solicitud de red habitual (incluida tu dirección IP) y la versión de la app; no recibe grabaciones, texto, nombres de proyectos ni historial. Puedes desactivar las consultas automáticas en Actualizaciones. Abrir la página de una versión utiliza tu navegador; los paquetes se descargan dentro de la app. Proyectos, etiquetas y fechas se guardan en el mismo historial local. Los documentos Word se guardan únicamente donde tú elijas.

Al pulsar Actualizar ahora, Vocalia descarga el paquete oficial de GitHub dentro de la app y verifica su suma SHA256. No envía historial ni archivos de audio. Solo se sustituye la aplicación después de elegir instalar; la carpeta de datos se conserva.
