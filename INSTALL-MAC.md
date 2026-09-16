# Install Vocalia 1.0.1 on Mac

[Español](INSTALL-MAC.es.md) · [Downloads](https://github.com/Francoocicchetti/Vocalia/releases/tag/v1.0.4)

## Check compatibility

Requires **Apple Silicon (M1 or later) and macOS 26 or later**. Check Apple menu → About This Mac. Intel MacBooks and older macOS versions are not supported. This is a direct download, not an App Store installation.

## Download and install

1. Download **Vocalia-1.0.4-macOS-AppleSilicon.zip** from the official Vocalia GitHub Release.
2. Open the ZIP and drag **Vocalia.app** to **Applications**.
3. Open Vocalia from Applications.

## If macOS cannot verify the developer

Vocalia is locally signed, but **not notarized by Apple**. If you trust this download and macOS blocks it:

1. Attempt to open Vocalia once, then dismiss the warning.
2. Open **System Settings → Privacy & Security**.
3. Find the blocked-app notice and choose **Open Anyway**.
4. Authenticate if requested, then confirm **Open**.

This is Apple's per-app exception procedure; availability depends on the warning and your Mac's policies. Do not disable Gatekeeper or antivirus. If macOS reports malware or damage, or a managed Mac prevents exceptions, stop and consult the warning/administrator instead of bypassing it. [Apple's official instructions](https://support.apple.com/en-us/102445).

## First transcription

Choose one of the six interface languages, then select the spoken language. Use **Download language** to prepare Apple's local speech model. Optional Whisper comparison and speaker grouping have their own model preparation. Add recordings to start transcription automatically. Review the full text against the highlighted audio before publishing quotes.

An internet connection is needed for initial model downloads. Recognition runs locally afterwards. Original recordings are preserved; model preparation does not upload them. [Full Mac guide](GUIDE.md) · [Privacy](PRIVACY.md).

## Updating an earlier development build

Quit the old app, then replace Vocalia.app in Applications with this one. Keep your Application Support folder. The app identifier and history location are unchanged. **1.0 is the public release number**, replacing earlier development labels such as 2.2.1; it does not reset your history. Keep a backup of important exports before any upgrade.

## Automatic transcription in 1.0.4

New recordings start transcribing automatically when added or dropped. Files run sequentially; a missing model is downloaded first. Transcribe pending remains available to resume stopped files. Existing history and edits are not automatically reprocessed. Speaker analysis remains manual.
