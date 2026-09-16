# Vocalia 1.0.3

[Instalación y avisos de macOS](INSTALL-MAC.es.md)

[English guide](GUIDE.md) · [Inicio en español](README.es.md)

Transcripciones completas y editables, con herramientas para preparar cuñas. Todo el reconocimiento se realiza en tu Mac. Los originales se conservan.

## Idiomas

El selector **Interfaz** cambia los controles entre español e inglés al momento. **Idioma del audio** es independiente: muestra los idiomas compatibles con el motor local de Apple en tu Mac. Elige el idioma hablado y pulsa **Descargar idioma** para prepararlo antes de transcribir. Si ya está instalado, aparece **Idioma listo**. La descarga se realiza desde Apple y no envía tus grabaciones. Puedes cancelar y volver a intentarlo.

Whisper utiliza el idioma registrado en cada transcripción, aunque después cambies el selector para otra grabación. No traduce el audio a otro idioma. Los mensajes técnicos de macOS pueden aparecer en el idioma del sistema.

## Empezar y cargar muchos archivos

1. Abre **Vocalia.app**.
2. Pulsa **Agregar archivos / carpetas** o arrastra grabaciones a la ventana. Selecciona varios archivos con ⌘ o Mayúsculas; también puedes elegir carpetas completas, incluidas sus subcarpetas. No agrega nuevamente un archivo de la misma ubicación. Omite enlaces y archivos incompatibles. Máximo 10.000 archivos por carga.
3. Deja **Español · Chile** para tus entrevistas. El motor Apple usa ese idioma cuando está disponible y, en su defecto, otro modelo de español compatible.
4. Pulsa **Transcribir pendientes**: procesa la lista uno por uno. Puedes agregar archivos durante el proceso. Un error en una grabación no impide continuar con las demás; revisa el estado de cada fila.
5. En **Texto completo** puedes editar toda la transcripción y pulsar **Copiar todo el texto** para pegarla de una vez. **Exportar → Texto (.txt)** guarda esa misma versión. La lista también permite exportar todas las transcripciones a TXT, sin sobrescribir archivos existentes.

## Seguir la voz mientras escuchas

Pulsa ▶ para escuchar el original. El texto se resalta en amarillo conforme avanza el audio. **Seguir audio** desplaza el documento para mantener visible el tramo activo; desmárcalo si prefieres moverte libremente. Al seleccionar texto para una cuña, el desplazamiento automático se suspende mientras mantengas la selección. Pausar conserva la posición para revisarla.

Las grabaciones con tiempos detallados siguen cada palabra o grupo reconocido; las anteriores se resaltan por fragmentos y no necesitan transcribirse de nuevo. En los silencios entre fragmentos desaparece el resaltado. En texto editado, solo se sigue un fragmento que permanezca intacto y sea inequívoco. El resaltado es visual: no modifica el texto, las cuñas ni lo que copies o exportes.

Vocalia conserva el identificador interno y la carpeta de datos de la versión anterior para mantener tu historial, preferencias y modelos. El nombre que aparece en la app y en el Finder es Vocalia.

## Las cinco mejoras

### Escuchar una frase seleccionada

Selecciona una frase en **Texto completo** y pulsa **Escuchar selección**. Se reproduce el fragmento de origen y se detiene al terminar. Las marcas corresponden a los fragmentos reconocidos, por lo que pueden incluir palabras anteriores o posteriores a la selección.

Si reescribes el texto, la app solo asigna tiempos cuando puede localizar la frase intacta y sin ambigüedad en el reconocimiento. No inventa tiempos para palabras añadidas. Usa **Revisar** para comprobar frases reescritas.

### Diccionario personal

Abre **Diccionario**, agrega nombres, apellidos, comunas, instituciones o siglas y guárdalos. Se conserva para próximas sesiones. El campo superior permite añadir contexto específico de una grabación. Se utilizan hasta 100 términos, de hasta 100 caracteres cada uno; Whisper recibe una versión limitada por su capacidad de contexto. Es una ayuda al reconocimiento, no una sustitución automática ni una garantía de ortografía.

### Cuñas

Selecciona una frase, indica el hablante si quieres y pulsa **Guardar cuña**. La pestaña **Cuñas** conserva el texto literal seleccionado, el archivo original, el hablante y los tiempos de origen. Puedes escucharla, copiar solo la cita, copiarla con su referencia o exportar las cuñas juntas a TXT. Una edición posterior del texto completo no reescribe las cuñas ya guardadas.

### Comparar Apple y Whisper

Activa **Comparar con Whisper** antes de transcribir, o pulsa **Analizar voces / comparar** sobre una transcripción existente. En **Comparación** verás las dos lecturas por intervalos de 20 segundos y podrás filtrar sus diferencias. Puedes copiar toda la lectura de Whisper.

Las diferencias indican qué escuchar: no demuestran cuál motor tiene razón. Una palabra situada en límites distintos de los intervalos también puede provocar una diferencia. La app no reemplaza automáticamente tu texto.

### Separar y nombrar voces

Activa **Separar voces**. En **Voces**, el modelo agrupa los hablantes como Voz 1, Voz 2… Puedes asignarles nombres. Si sabes cuántas personas hablan, indícalo antes del análisis; también hay detección automática. Los nombres son propios de cada grabación. Recalcular puede cambiar las etiquetas, por lo que conviene nombrarlas después del análisis final.

Los tramos superpuestos o sin correspondencia suficiente requieren revisión. No identifica personas por su voz ni garantiza separar correctamente ruido, música o hablantes simultáneos. Se guardan etiquetas y tiempos, no un registro de identidades por voz.

## Modelos locales y privacidad

Apple SpeechAnalyzer realiza la transcripción principal. WhisperKit ejecuta Whisper large-v3-turbo cuantizado como segunda lectura; SpeakerKit ejecuta los modelos de separación de voces. **Preparar modelos** descarga los dos complementos una vez. El tamaño depende de las versiones de los modelos, además del modelo de idioma de Apple y posibles cachés del sistema. Preparar o ejecutar por primera vez puede tardar.

Los archivos no se envían a servicios de transcripción. Las conexiones se utilizan para descargar modelos; una vez disponibles localmente, el reconocimiento funciona sin conexión. No requiere cuentas, claves ni suscripciones. Los modelos se guardan en `~/Library/Application Support/Franco Transcribe/Models`.

El historial, las correcciones y las cuñas se guardan en `~/Library/Application Support/Franco Transcribe/transcripciones.json`. El diccionario y las preferencias se guardan localmente en las preferencias de la app. Las conversiones temporales se eliminan al terminar normalmente; un cierre forzado puede dejar temporales. Tú decides dónde exportar: si eliges una carpeta sincronizada, ese servicio puede sincronizar tus exportaciones.

## Revisión, límites y recuperación

- El texto completo siempre se puede copiar como un solo documento. Puede contener párrafos y etiquetas de hablante.
- Las correcciones del texto completo se aplican a TXT y al portapapeles. Los subtítulos SRT/VTT utilizan los fragmentos de **Revisar**, con sus propios tiempos y correcciones.
- Los avisos de baja confianza de Apple son señales de revisión, no porcentajes de precisión medidos. Comprueba nombres, cifras y citas contra el audio antes de publicarlas.
- Acepta OPUS, MP3, MP4, MOV, M4A, WAV, AIFF, AAC, FLAC, CAF y M4V que macOS pueda decodificar. Analiza la primera pista de audio; un archivo sin audio o con protección puede fallar.
- La transcripción principal admite archivos de menos de 24 horas. **Whisper y la separación de voces requieren archivos de menos de 2 horas**. Si una función adicional falla, se conserva la transcripción principal y se intenta la otra función activada.
- **Cancelar** conserva lo reconocido hasta entonces y deja los pendientes sin procesar. Los modelos pueden tardar en responder a la cancelación mientras terminan una operación interna.
- Antes de volver a transcribir o recalcular voces se guarda una revisión JSON local. Quitar una entrada del historial no elimina el audio ni esas revisiones.
- Para reproducir, conecta el disco original. Si moviste el archivo, usa **Exportar → Vincular original…** y elige la misma grabación en su nueva ubicación. El texto y las cuñas se conservan.
- No se midió una tasa de error sobre un corpus chileno con transcripciones verificadas. Las pruebas realizadas verifican funcionamiento, no precisión perfecta.

## Abrir y recompilar

Abre la app de esta carpeta o descomprime **Vocalia-1.0.3-macOS-AppleSilicon.zip**. Puedes arrastrarla a Aplicaciones. Requiere Apple Silicon y macOS 26 o posterior. Está compilada localmente y firmada para uso local; no está notarizada para distribución pública. No necesita micrófono para transcribir archivos.

El código está en este repositorio. `build.sh` recompila con Swift Package Manager usando las bibliotecas incluidas, ejecuta las pruebas y genera el ZIP. Necesita las herramientas de desarrollo de Apple. Las licencias de las bibliotecas se incluyen en el código y dentro de la app.

Fuentes técnicas: [SpeechAnalyzer de Apple](https://developer.apple.com/documentation/speech/speechanalyzer), [Argmax: WhisperKit y SpeakerKit](https://github.com/argmaxinc/argmax-oss-swift), [SpeakerKit](https://www.argmaxinc.com/blog/speakerkit).


## Vocalia 1.0.3

La interfaz ofrece seis idiomas. El tutorial interactivo se puede repetir. Se conserva la compatibilidad con OPUS y Ogg/Opus. Consulta la [tabla de versiones y funciones](README.es.md).

## Voces y cifras en 1.0.3

Separar voces requiere una acción manual. En Mac, marca «Voces: análisis manual» y pulsa «Analizar voces / comparar» sobre la grabación terminada; no se ejecuta después de transcribir. En Windows, pulsa «Analizar voces» cuando lo necesites. Las etiquetas existentes se conservan.

La corrección de decimales usa el idioma del audio, no el de la interfaz. Reconoce cifras explícitas como «12 coma 75» y expresiones sencillas como «nueve coma cinco». Conserva los ceros decimales y el reconocimiento original para revisión. No cambia transcripciones anteriores ni interpreta fechas, listas o cantidades ambiguas. Las cifras se señalan para escucharlas y revisarlas: un formato correcto no demuestra que el motor haya oído el número correcto. No se ha medido una mejora global de precisión con entrevistas reales.
