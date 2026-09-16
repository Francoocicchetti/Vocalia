# Vocalia — English

The English documentation is now the main page: **[Read the README](README.md)**.

[Español](README.es.md)

## New in 1.0.1

- Choose English or Spanish before entering the workspace on first launch. Change the app language later inside Vocalia.
- A replayable tutorial explains adding recordings, preparing a model, transcribing, reviewing and copying the full text.
- Windows: **adding a recording does not transcribe it**. Click **Transcribe pending**. If the model is missing, accept its download; transcription then starts automatically.
- Clear empty-queue, missing-model and worker-failure messages. Playback stops when transcription is requested and is unavailable while a job is running.


## OPUS support in 1.0.1

Use the downloads with **OPUS** in their filename. Both platforms accept `.opus` and Ogg files containing Opus (`.ogg`), including batch/folder import. No manual conversion or audio upload is needed. Windows uses its bundled decoder. Mac includes a local BSD-licensed Opus decoder and uses a temporary PCM copy for transcription and playback; normal app exit removes that copy and the original is preserved. Mac OPUS recordings must be under ten hours; Windows keeps its two-hour limit. Ogg/Vorbis is not included.

New downloads have checksums in **SHA256SUMS-GuideFix.txt**; the original 1.0.1 files remain available for reproducibility. The updated source is on the main branch and in **Vocalia-1.0.1-GuideFix-source.zip** in Releases. The tag's automatic Source code archives describe the original 1.0.1 build.

## Interactive in-app tour

Anchored speech bubbles explain the actual controls. Use Next, Back or Skip; reopen the tour with **How to use Vocalia**. First launch still asks for your language before entering the workspace. The tour does not start jobs or modify recordings. Downloads marked **GuideFix** also include OPUS support.

## Startup and tour display fix

The **GuideFix** downloads restore the language picker once on first launch after this update, including existing installations. Your choice is remembered afterwards and remains changeable inside the app. Mac tutorial bubbles now use an opaque background and clear keyboard focus from underlying controls to prevent focus outlines crossing the tutorial. Background editing is paused during the tour and restored when it closes.
