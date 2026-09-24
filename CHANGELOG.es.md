# Vocalia changelog

## 0.0.6 — Preliminar

- Pulsar palabras para escuchar; repetir el audio completo o una selección.
- Limpieza local opcional de retumbes y volumen, conservando originales y tiempos.
- Whisper large-v3 opcional; diccionario y revisión por baja confianza de palabras en Windows.
- Conversión PCM directa en Mac y controles en seis idiomas.
- La publicación requiere que pasen las compilaciones nativas de ambos sistemas.


**Versión preliminar 0.0.5 · En desarrollo.** Vocalia todavía no es una versión 1.0 estable. Las entradas 1.x son etiquetas históricas anteriores al cambio de numeración; se conservan las funciones y el historial.

## Tabla de actualizaciones

| Versión | Actualizaciones |
| --- | --- |
| **1.0** | Primera versión pública conjunta para Mac y Windows: transcripción local, varios archivos, texto completo editable, resaltado al reproducir, cuñas con fuente, exportación TXT/SRT/VTT e historial. |
| **1.0.1** | Instalador de Windows y mejor guía para descargar el modelo e iniciar la transcripción; elección de idioma antes de entrar; OPUS y Ogg/Opus; tutorial con globos interactivos, repetir/omitir, restauración del selector inicial y corrección de superposición en Mac. Incluye las revisiones OPUS, Tour y GuideFix publicadas bajo 1.0.1. |
| **1.0.2** | Seis idiomas de interfaz. Windows incorpora revisión de fragmentos, comparación con otro modelo, agrupación local de voces y nombres, escuchar/copiar/exportar cuñas, velocidad de reproducción y editor de diccionario. También permite arrastrar archivos, agregarlos al terminar una cola activa y volver a transcribir una selección guardando una copia previa. Documentación bilingüe y nuevas pruebas. |
| **1.0.3** | Separación de voces solo manual, desactivada al iniciar Mac. Decimales explícitos en español como «9, coma, 5» pasan a «9,5»; se conserva el original, los tiempos y se marcan las cifras para revisión con audio. |
| **0.0.4** | Las grabaciones nuevas se transcriben automáticamente al agregarlas o arrastrarlas. Se procesan una a una; si falta el modelo, se descarga primero. Transcribir pendientes permite retomar archivos detenidos. No se reprocesan automáticamente el historial ni las ediciones. El análisis de voces sigue siendo manual. |
| **0.0.5** | Avisos de nuevas versiones y sus cambios; búsqueda en todas las transcripciones con escucha del fragmento; proyectos, etiquetas y fechas; vista de revisión de cifras; exportación Word del texto completo editado con cuñas seleccionadas. |

[Historial detallado](CHANGELOG.es.md)


## Actualizador integrado — revisión de instaladores 0.0.5

El botón **Actualizar Vocalia** descarga dentro de la app, muestra el progreso, permite cancelar y verifica la suma SHA256 del archivo con los datos oficiales de GitHub antes de instalar. No abre GitHub para descargar la app.

- **Windows:** después de verificar, pulsa **Instalar actualización**. Vocalia guarda las ediciones, se cierra y abre el asistente local en la carpeta actual. Completa el asistente para volver a abrir Vocalia. No permite instalar mientras hay transcripciones o importaciones activas.
- **Mac:** pulsa **Instalar y reiniciar**. Vocalia prepara y verifica la nueva aplicación, guarda el historial, reemplaza solo la app y vuelve a abrirla. Guarda una copia de la aplicación anterior al lado para recuperación. La app debe estar en una carpeta Aplicaciones con permiso de escritura, fuera de imágenes montadas o ubicaciones de App Translocation. No se desactivan protecciones del sistema.
- El historial, las cuñas, proyectos, ajustes y modelos permanecen en sus ubicaciones habituales. Cancelar o fallar la verificación no modifica la app instalada. Si falla el reemplazo en Mac, intenta restaurar la app anterior.
- **Transición por única vez:** quien tenga la primera 0.0.5 debe instalar una vez esta revisión usando los enlaces de descarga. La primera 0.0.5 no puede instalar por sí sola una revisión con el mismo número. Las futuras versiones con numeración superior se podrán descargar e instalar con el nuevo botón.

Se mantiene la versión pública **0.0.5**: compilación **18** en Mac y versión de archivo **0.0.5.1** en Windows. El código completo actual está en `Vocalia-0.0.5-source.zip`; la etiqueta original `v0.0.5` y los archivos “Source code” que genera GitHub conservan la publicación inicial. La ejecución de compilación enlazada identifica el código exacto de estos instaladores.

