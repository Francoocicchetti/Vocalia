# Vocalia para Windows 11 · Intel / AMD x64

**Versión preliminar 0.0.4 · En desarrollo.** Vocalia todavía no es una versión 1.0 estable. La numeración actual sustituye a la etiqueta anterior 1.0.4; conserva sus funciones y datos. Las entradas anteriores de la tabla son etiquetas históricas de prototipos.

[English](WINDOWS.md) · [Inicio](README.es.md)

**[Descargar Vocalia 0.0.4 para Windows](https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.4/Vocalia-0.0.4-Windows-x64-Setup.exe)**

Código: `Vocalia-Windows-source.zip`. Descomprímelo antes de ejecutar el script de compilación.

Vocalia 0.0.4 para Windows. Transcripción local con Whisper: no envía grabaciones a un servidor. La primera preparación descarga el modelo; después la transcripción usa únicamente archivos locales.

## Uso

1. Descarga y ejecuta **Vocalia-0.0.4-Windows-x64-Setup.exe**. Sigue el instalador en español o inglés; al abrir la app podrás elegir entre seis idiomas.
2. Abre **Vocalia** desde Inicio. El acceso directo en el escritorio es opcional. No necesita Python ni permisos de administrador.
3. Elige español, inglés, alemán, francés, chino simplificado o portugués para la interfaz y el idioma hablado para el audio.
4. Elige el modelo y pulsa Descargar / preparar modelo. `small` es la opción inicial equilibrada; `medium` y `large-v3-turbo` consumen más memoria y tiempo. Se recomienda probar small primero; para los modelos mayores conviene tener al menos 16 GB de RAM disponibles en el equipo. Esto es una orientación, no un mínimo de rendimiento medido.
5. Agrega varios OPUS, MP3, MP4, MOV, M4A u otros archivos, o una carpeta. La transcripción comienza automáticamente.
6. Copia el texto completo, revísalo escuchando el original con resaltado o selecciona una frase para guardar una cuña. Puedes exportar TXT, SRT y VTT.

El historial y los modelos están en `%LOCALAPPDATA%\Vocalia`. Quitar una entrada es recuperable con **Recuperar última eliminada**; el original nunca se elimina. La app impide abrir dos instancias contra el mismo historial. Al cancelar se conserva lo que ya se reconoció. Puedes volver a procesar los pendientes desde el comienzo.

Los nombres del diccionario sirven de contexto: no corrigen automáticamente. Los tiempos se corresponden con el texto reconocido; si reescribes una frase puede dejar de ser posible localizarla. TXT conserva las ediciones completas, mientras que SRT/VTT usan los fragmentos reconocidos con tiempos.

## Estabilidad y límites

- Motor CPU: no depende de una tarjeta NVIDIA ni de controladores CUDA.
- El motor se ejecuta en un proceso independiente; un fallo o cancelación no debe cerrar el editor.
- Guardado transaccional en SQLite y recuperación de entradas quitadas del historial.
- Máximo 10.000 archivos por importación y grabaciones de menos de 2 horas con duración legible. Los archivos protegidos, corruptos o sin pista de audio mostrarán un error.
- La velocidad y el consumo de memoria dependen del procesador, el modelo y el audio. No se ha medido precisión sobre entrevistas chilenas verificadas.
- Apple Speech solo existe en Mac. Windows compara dos modelos Whisper locales e incorpora agrupación opcional de voces con sherpa-onnx.
- Las pruebas automatizadas de Windows Server x64 verifican compilación y funcionamiento, pero no sustituyen una prueba en el Windows 11 de tus colegas. La numeración 1.0 no constituye una certificación de estabilidad en todos los equipos.
- El ejecutable no está firmado con un certificado Authenticode: Windows puede mostrar un aviso de reputación. No desactives las protecciones generales del equipo.

## Compilar y probar

En Windows x64 con Python 3.12 de python.org, ejecuta `powershell -File build.ps1` desde esta carpeta. Se instalan las versiones fijadas, corren las pruebas del núcleo, se empaqueta la app, se prueban la interfaz y el reconocimiento con un audio público de prueba, y se crea un ZIP. Nunca uses una grabación privada para las pruebas públicas de GitHub.

`test-speech.flac` es un fragmento público del discurso de JFK de las pruebas oficiales de OpenAI Whisper. No contiene datos del usuario y no se incluye en la aplicación.


Antes de reintentar una transcripción parcial, se conserva una revisión JSON en `%LOCALAPPDATA%\Vocalia\Revisions`.

## Instalador y errores al abrir el ZIP

Usa Setup.exe para evitar el error de `python312.dll` causado por abrir Vocalia dentro del ZIP. Instala la app completa en `%LOCALAPPDATA%\Programs\Vocalia` y crea el acceso en Inicio. Puedes desinstalarla en Configuración → Aplicaciones; se conservan el historial y los modelos de `%LOCALAPPDATA%\Vocalia`. El ZIP portátil sigue disponible para quienes extraigan todos sus archivos primero.

El instalador no tiene firma comercial y Windows puede mostrar un aviso de reputación. No desactives las protecciones del sistema. Si el error persiste después de usar Setup.exe, informa el mensaje exacto y tu versión de Windows: puede requerir otro diagnóstico. El código y las pruebas del instalador están en `.github/workflows/windows.yml`.


## Vocalia 0.0.4

La interfaz ofrece seis idiomas. El tutorial interactivo se puede repetir. Se conserva la compatibilidad con OPUS y Ogg/Opus. Consulta la [tabla de versiones y funciones](README.es.md).

En **Revisar** puedes corregir fragmentos, marcarlos como revisados y recuperar sus palabras originales. **Comparación** requiere preparar otro modelo diferente del original. **Voces** descarga unos 47 MB una vez; analiza una grabación terminada, escucha sus intervalos y asigna nombres. El texto completo editado de forma independiente se conserva. El diccionario acepta hasta 100 términos. Puedes copiar cuñas sin atribución, escucharlas o exportarlas en TXT. La velocidad va de 0,75× a 2×. Arrastra archivos a la ventana; si hay una cola activa, se incorporan al terminar y después puedes transcribirlos. **Volver a transcribir selección** guarda una revisión JSON antes de sustituir el texto.

## Voces y cifras en 1.0.3

Separar voces requiere una acción manual. En Mac, marca «Voces: análisis manual» y pulsa «Analizar voces / comparar» sobre la grabación terminada; no se ejecuta después de transcribir. En Windows, pulsa «Analizar voces» cuando lo necesites. Las etiquetas existentes se conservan.

La corrección de decimales usa el idioma del audio, no el de la interfaz. Reconoce cifras explícitas como «12 coma 75» y expresiones sencillas como «nueve coma cinco». Conserva los ceros decimales y el reconocimiento original para revisión. No cambia transcripciones anteriores ni interpreta fechas, listas o cantidades ambiguas. Las cifras se señalan para escucharlas y revisarlas: un formato correcto no demuestra que el motor haya oído el número correcto. No se ha medido una mejora global de precisión con entrevistas reales.

## Transcripción automática en 0.0.4

Las grabaciones nuevas se transcriben automáticamente al agregarlas o arrastrarlas. Se procesan una a una; si falta el modelo, se descarga primero. Transcribir pendientes permite retomar archivos detenidos. No se reprocesan automáticamente el historial ni las ediciones. El análisis de voces sigue siendo manual.
