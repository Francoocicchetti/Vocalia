<p align="center"><img src="logo.png" width="128" alt="Icono de Vocalia"></p>

# Vocalia 1.0.4

**Transcripción local para periodistas: texto completo, cuñas y reproducción con resaltado.**

[English](README.md) · **Español**

## Descargar

### [↓ Instalador para Windows 11 — Intel / AMD](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.4/Vocalia-1.0.4-Windows-x64-Setup.exe)

### [↓ MacBook / Mac — Apple Silicon](https://github.com/Francoocicchetti/Vocalia/releases/download/v1.0.4/Vocalia-1.0.4-macOS-AppleSilicon.zip)

[Todos los archivos y verificaciones de la versión 1.0.3](https://github.com/Francoocicchetti/Vocalia/releases/tag/v1.0.4)

| Equipo | Requisitos | Archivo |
| --- | --- | --- |
| Windows | Windows 11, Intel/AMD de 64 bits | `Vocalia-1.0.4-Windows-x64-Setup.exe` |
| MacBook / Mac | Apple Silicon M1 o posterior, macOS 26+ | `Vocalia-1.0.4-macOS-AppleSilicon.zip` |

Los archivos están en **Assets**, debajo de las notas de la versión. Descarga el instalador o el ZIP para Mac, no «Source code». No necesitas Python, Xcode, cuenta ni clave de API. Estos archivos no son compatibles con Mac Intel ni Windows ARM.

## Instalar y comenzar

1. **Windows:** ejecuta el instalador y abre Vocalia desde Inicio. El acceso directo de escritorio es opcional. Si eliges el ZIP portátil, extrae **toda la carpeta** y conserva `_internal` junto a `Vocalia.exe`. [Instrucciones](WINDOWS.es.md).
2. **Mac:** descomprime el ZIP, arrastra Vocalia.app a Aplicaciones y ábrela. La app no está notarizada por Apple. Si macOS bloquea la primera apertura, sigue [Configuración del Sistema → Privacidad y seguridad → Abrir de todos modos](INSTALL-MAC.es.md). No desactives la protección general del sistema.
3. Antes de entrar, elige **español, inglés, alemán, francés, chino simplificado o portugués**. La selección aparece antes de entrar en el primer inicio. Luego puedes cambiarla dentro de la app.
4. Elige el **idioma hablado** y agrega o arrastra grabaciones: la transcripción comienza automáticamente. Si falta un modelo, completa su descarga y la transcripción continúa.
5. Los globos del tutorial señalan los controles reales. Puedes repetirlos desde **Cómo usar Vocalia**. Copia el texto completo o revísalo escuchando el audio antes de guardar cuñas.

Internet se usa para descargar modelos. Las grabaciones y transcripciones se procesan localmente: Vocalia no las sube.

## Tabla de actualizaciones

| Versión | Actualizaciones |
| --- | --- |
| **1.0** | Primera versión pública conjunta para Mac y Windows: transcripción local, varios archivos, texto completo editable, resaltado al reproducir, cuñas con fuente, exportación TXT/SRT/VTT e historial. |
| **1.0.1** | Instalador de Windows y mejor guía para descargar el modelo e iniciar la transcripción; elección de idioma antes de entrar; OPUS y Ogg/Opus; tutorial con globos interactivos, repetir/omitir, restauración del selector inicial y corrección de superposición en Mac. Incluye las revisiones OPUS, Tour y GuideFix publicadas bajo 1.0.1. |
| **1.0.2** | Seis idiomas de interfaz. Windows incorpora revisión de fragmentos, comparación con otro modelo, agrupación local de voces y nombres, escuchar/copiar/exportar cuñas, velocidad de reproducción y editor de diccionario. También permite arrastrar archivos, agregarlos al terminar una cola activa y volver a transcribir una selección guardando una copia previa. Documentación bilingüe y nuevas pruebas. |
| **1.0.3** | Separación de voces solo manual, desactivada al iniciar Mac. Decimales explícitos en español como «9, coma, 5» pasan a «9,5»; se conserva el original, los tiempos y se marcan las cifras para revisión con audio. |
| **1.0.4** | Las grabaciones nuevas se transcriben automáticamente al agregarlas o arrastrarlas. Se procesan una a una; si falta el modelo, se descarga primero. Transcribir pendientes permite retomar archivos detenidos. No se reprocesan automáticamente el historial ni las ediciones. El análisis de voces sigue siendo manual. |

[Historial detallado](CHANGELOG.es.md)

## Funciones por plataforma

| Función | Mac | Windows |
| --- | --- | --- |
| Seis idiomas, selector inicial y tutorial interactivo | Sí | Sí |
| Varios archivos/carpetas, arrastrar y soltar, cola | Sí | Sí; lo agregado durante un proceso se incorpora al terminar la cola |
| Texto completo, resaltado y velocidad de reproducción | Sí | Sí |
| Revisión por fragmentos, originales y marcas de revisión | Sí | Sí |
| Cuñas con fuente/tiempo, escuchar, copiar y exportar | Sí | Sí |
| Diccionario y exportación TXT/SRT/VTT | Sí | Sí |
| Comparación de transcripciones | Apple Speech y Whisper | Dos modelos Whisper locales diferentes |
| Agrupación opcional de voces, intervalos y nombres | SpeakerKit | sherpa-onnx en CPU |
| Motor principal | Apple Speech | Whisper en CPU |
| Duración máxima por archivo | Principal: menos de 24 h; OPUS: menos de 10 h; motores adicionales: menos de 2 h | Menos de 2 h |

En Windows, la agrupación de voces descarga aproximadamente 47 MB una vez. Pulsa **Preparar modelos de voces** y luego **Analizar voces** sobre una grabación terminada. Revisa los resultados cuando hay ruido o voces superpuestas. Para comparar, prepara un segundo modelo diferente. Estas funciones conservan el texto completo editado de forma independiente; los fragmentos se mantienen separados para revisión y subtítulos.

Se admiten MP3, MP4, MOV, M4A, WAV, FLAC, OPUS y otros formatos compatibles. Aquí `.ogg` significa Ogg con audio Opus. Los motores, rendimiento y algunos controles difieren: Apple Speech solo existe en macOS. El resaltado requiere texto que pueda alinearse con los tiempos. Revisa siempre nombres, cifras y citas contra el audio.

## Documentación y pruebas

[Guía Mac](GUIA.md) · [Guía Windows](WINDOWS.es.md) · [Privacidad](PRIVACY.es.md) · [Compilaciones y pruebas](https://github.com/Francoocicchetti/Vocalia/actions/workflows/windows.yml)

Las pruebas de Windows se ejecutan en Windows Server x64: app empaquetada, seis idiomas y tutorial, historial, errores/cancelación, reconocimiento real sin conexión de seis formatos, comparación, una grabación pública de cuatro voces, instalación, accesos directos y conservación de datos al reinstalar/desinstalar. Falta validación en equipos físicos Windows 11 Intel/AMD. En Mac se comprueban historial, sincronización, importación, traducciones y funciones de transcripción. Las pruebas no garantizan precisión perfecta ni ausencia de fallos.

La app de Mac tiene firma local y no está notarizada. Windows no tiene firma Authenticode. Las actualizaciones conservan la ubicación del historial. Guarda la versión anterior hasta probar la nueva con tu forma de trabajar.

## Código y licencias

El código para Mac está en los archivos Swift y `ui-translations.json`; se compila con `zsh build.sh` y las herramientas de Apple con SDK macOS 26. El de Windows está en `Vocalia-Windows-source.zip`; requiere Python 3.12 x64 y `build.ps1`, además de Inno Setup 6 para el instalador. La versión incluye un paquete con todo el código.

Las dependencias incluyen sus licencias y avisos. Los modelos opcionales de voces de Windows usan segmentación pyannote (MIT) y embeddings 3D-Speaker (Apache-2.0). El código y logo propios de Vocalia aún no tienen una licencia general de código abierto.

Para reportar un problema, [abre un issue](https://github.com/Francoocicchetti/Vocalia/issues) con sistema, versión, pasos, formato y duración aproximada. No publiques audios privados, transcripciones ni registros sin revisar.

## Voces y cifras en 1.0.3

Separar voces requiere una acción manual. En Mac, marca «Voces: análisis manual» y pulsa «Analizar voces / comparar» sobre la grabación terminada; no se ejecuta después de transcribir. En Windows, pulsa «Analizar voces» cuando lo necesites. Las etiquetas existentes se conservan.

La corrección de decimales usa el idioma del audio, no el de la interfaz. Reconoce cifras explícitas como «12 coma 75» y expresiones sencillas como «nueve coma cinco». Conserva los ceros decimales y el reconocimiento original para revisión. No cambia transcripciones anteriores ni interpreta fechas, listas o cantidades ambiguas. Las cifras se señalan para escucharlas y revisarlas: un formato correcto no demuestra que el motor haya oído el número correcto. No se ha medido una mejora global de precisión con entrevistas reales.

## Transcripción automática en 1.0.4

Las grabaciones nuevas se transcriben automáticamente al agregarlas o arrastrarlas. Se procesan una a una; si falta el modelo, se descarga primero. Transcribir pendientes permite retomar archivos detenidos. No se reprocesan automáticamente el historial ni las ediciones. El análisis de voces sigue siendo manual.
