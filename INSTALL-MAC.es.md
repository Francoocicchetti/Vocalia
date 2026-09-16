# Instalar Vocalia 1.0.1 en Mac

**Versión preliminar 0.0.4 · En desarrollo.** Vocalia todavía no es una versión 1.0 estable. La numeración actual sustituye a la etiqueta anterior 1.0.4; conserva sus funciones y datos. Las entradas anteriores de la tabla son etiquetas históricas de prototipos.

[English](INSTALL-MAC.md) · [Descargas](https://github.com/Francoocicchetti/Vocalia/releases/tag/v0.0.4)

## Compatibilidad

Requiere **Apple Silicon (M1 o posterior) y macOS 26 o posterior**. Compruébalo en el menú Apple → Acerca de este Mac. No funciona en MacBook Intel ni en versiones anteriores de macOS. Se descarga directamente; no se instala desde App Store.

## Descargar e instalar

1. Descarga **Vocalia-0.0.4-macOS-AppleSilicon.zip** desde la Release oficial de Vocalia en GitHub.
2. Abre el ZIP y arrastra **Vocalia.app** a **Aplicaciones**.
3. Abre Vocalia desde Aplicaciones.

## Si macOS no puede verificar al desarrollador

Vocalia tiene firma local, pero **no está notarizada por Apple**. Si confías en esta descarga y el Mac la bloquea:

1. Intenta abrir Vocalia una vez y cierra el aviso.
2. Entra a **Configuración del Sistema → Privacidad y seguridad**.
3. Busca el aviso de la app bloqueada y pulsa **Abrir igualmente**.
4. Autentícate si lo solicita y confirma **Abrir**.

Es la excepción por aplicación que documenta Apple; depende del aviso y de las políticas del equipo. No desactives Gatekeeper ni el antivirus. Si el aviso indica malware o daños, o el equipo administrado prohíbe excepciones, detente y consulta el aviso o al administrador. [Instrucciones oficiales de Apple](https://support.apple.com/es-cl/102445).

## Primera transcripción

Elige uno de los seis idiomas de interfaz y después el idioma hablado. Pulsa **Descargar idioma** para preparar el modelo local de Apple. La comparación con Whisper y la separación de voces requieren sus propios modelos. Agrega grabaciones para iniciar la transcripción automáticamente. Revisa el texto completo escuchando el original antes de publicar cuñas.

La descarga inicial de modelos necesita internet. Después el reconocimiento funciona localmente. Se conservan los originales y no se suben al preparar modelos. [Guía completa](GUIA.md) · [Privacidad](PRIVACY.es.md).

## Actualizar una versión de desarrollo

Cierra la app anterior y reemplaza Vocalia.app en Aplicaciones. Conserva la carpeta Application Support. El identificador y la ubicación del historial no cambian. **1.0 es la numeración pública**, que reemplaza etiquetas de desarrollo como 2.2.1; no borra tu historial. Conserva una copia de tus exportaciones importantes antes de actualizar.

## Transcripción automática en 0.0.4

Las grabaciones nuevas se transcriben automáticamente al agregarlas o arrastrarlas. Se procesan una a una; si falta el modelo, se descarga primero. Transcribir pendientes permite retomar archivos detenidos. No se reprocesan automáticamente el historial ni las ediciones. El análisis de voces sigue siendo manual.
