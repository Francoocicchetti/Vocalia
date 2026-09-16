# Vocalia para Windows 11 · Intel / AMD x64

[English](WINDOWS.md) · [Inicio](README.es.md)

**[Descargar Vocalia 1.0.1 para Windows](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.1/Vocalia-1.0.1-Windows-x64-OPUS-Setup.exe)**

Código: `Vocalia-Windows-source.zip`. Descomprímelo antes de ejecutar el script de compilación.

Vocalia 1.0.1 para Windows. Transcripción local con Whisper: no envía grabaciones a un servidor. La primera preparación descarga el modelo; después la transcripción usa únicamente archivos locales.

## Uso

1. Descarga y ejecuta **Vocalia-1.0.1-Windows-x64-OPUS-Setup.exe**. Sigue el asistente en español o inglés.
2. Abre **Vocalia** desde Inicio. El acceso directo en el escritorio es opcional. No necesita Python ni permisos de administrador.
3. Elige Español o English para la interfaz y el idioma hablado para el audio.
4. Elige el modelo y pulsa Descargar / preparar modelo. `small` es la opción inicial equilibrada; `medium` y `large-v3-turbo` consumen más memoria y tiempo. Se recomienda probar small primero; para los modelos mayores conviene tener al menos 16 GB de RAM disponibles en el equipo. Esto es una orientación, no un mínimo de rendimiento medido.
5. Agrega varios OPUS, MP3, MP4, MOV, M4A u otros archivos, o una carpeta. Pulsa Transcribir pendientes.
6. Copia el texto completo, revísalo escuchando el original con resaltado o selecciona una frase para guardar una cuña. Puedes exportar TXT, SRT y VTT.

El historial y los modelos están en `%LOCALAPPDATA%\Vocalia`. Quitar una entrada es recuperable con **Recuperar última eliminada**; el original nunca se elimina. La app impide abrir dos instancias contra el mismo historial. Al cancelar se conserva lo que ya se reconoció. Puedes volver a procesar los pendientes desde el comienzo.

Los nombres del diccionario sirven de contexto: no corrigen automáticamente. Los tiempos se corresponden con el texto reconocido; si reescribes una frase puede dejar de ser posible localizarla. TXT conserva las ediciones completas, mientras que SRT/VTT usan los fragmentos reconocidos con tiempos.

## Estabilidad y límites

- Motor CPU: no depende de una tarjeta NVIDIA ni de controladores CUDA.
- El motor se ejecuta en un proceso independiente; un fallo o cancelación no debe cerrar el editor.
- Guardado transaccional en SQLite y recuperación de entradas quitadas del historial.
- Máximo 10.000 archivos por importación y grabaciones de menos de 2 horas con duración legible. Los archivos protegidos, corruptos o sin pista de audio mostrarán un error.
- La velocidad y el consumo de memoria dependen del procesador, el modelo y el audio. No se ha medido precisión sobre entrevistas chilenas verificadas.
- Esta edición **no tiene el motor de Apple, comparación Apple/Whisper ni separación automática de hablantes**. Puedes nombrar manualmente a los hablantes de las cuñas.
- Las pruebas automatizadas de Windows Server x64 verifican compilación y funcionamiento, pero no sustituyen una prueba en el Windows 11 de tus colegas. La numeración 1.0 no constituye una certificación de estabilidad en todos los equipos.
- El ejecutable no está firmado con un certificado Authenticode: Windows puede mostrar un aviso de reputación. No desactives las protecciones generales del equipo.

## Compilar y probar

En Windows x64 con Python 3.12 de python.org, ejecuta `powershell -File build.ps1` desde esta carpeta. Se instalan las versiones fijadas, corren las pruebas del núcleo, se empaqueta la app, se prueban la interfaz y el reconocimiento con un audio público de prueba, y se crea un ZIP. Nunca uses una grabación privada para las pruebas públicas de GitHub.

`test-speech.flac` es un fragmento público del discurso de JFK de las pruebas oficiales de OpenAI Whisper. No contiene datos del usuario y no se incluye en la aplicación.


Antes de reintentar una transcripción parcial, se conserva una revisión JSON en `%LOCALAPPDATA%\Vocalia\Revisions`.

## Instalador y errores al abrir el ZIP

Usa Setup.exe para evitar el error de `python312.dll` causado por abrir Vocalia dentro del ZIP. Instala la app completa en `%LOCALAPPDATA%\Programs\Vocalia` y crea el acceso en Inicio. Puedes desinstalarla en Configuración → Aplicaciones; se conservan el historial y los modelos de `%LOCALAPPDATA%\Vocalia`. El ZIP portátil sigue disponible para quienes extraigan todos sus archivos primero.

El instalador no tiene firma comercial y Windows puede mostrar un aviso de reputación. No desactives las protecciones del sistema. Si el error persiste después de usar Setup.exe, informa el mensaje exacto y tu versión de Windows: puede requerir otro diagnóstico. El código y las pruebas del instalador están en `.github/workflows/windows-installer.yml`.

## Novedades de 1.0.1

- Elige español o inglés antes de entrar al área de trabajo la primera vez. Después puedes cambiar el idioma dentro de Vocalia.
- Tutorial que puedes volver a abrir: agregar audios, preparar el modelo, transcribir, revisar y copiar el texto completo.
- Windows: **agregar un audio no lo transcribe**. Pulsa **Transcribir pendientes**. Si falta el modelo, acepta descargarlo; al terminar empieza la transcripción automáticamente.
- Avisos claros si no hay pendientes, falta el modelo o falla el motor. Al solicitar una transcripción se detiene la reproducción; escuchar queda desactivado mientras hay un trabajo en curso.


## Compatibilidad OPUS en 1.0.1

Descarga los archivos que incluyen **OPUS** en el nombre. Ambas versiones aceptan `.opus` y archivos Ogg que contienen Opus (`.ogg`), también por lotes y carpetas. No necesitas convertirlos ni subir el audio a un servidor. Mac incorpora un decodificador local y usa una copia PCM temporal para transcribir y escuchar; se elimina al cerrar normalmente la app y se conserva el original. OPUS en Mac admite grabaciones de menos de diez horas; Windows mantiene el límite de dos horas. No incluye Ogg/Vorbis.

Los nuevos archivos se verifican con **SHA256SUMS-OPUS.txt**. El código actualizado está en main y en **Vocalia-1.0.1-OPUS-source.zip** de Releases; el Source code automático de la etiqueta corresponde a la compilación inicial.
