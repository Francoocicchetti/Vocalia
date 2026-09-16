import SwiftUI

struct VocaliaStartView: View {
    @AppStorage("onboarding101") private var completed = false
    var body: some View {
        if completed { TranscribeView() }
        else { VocaliaTutorial { completed = true } }
    }
}

struct VocaliaTutorial: View {
    @AppStorage("uiLanguage") private var language = Locale.preferredLanguages.first?.hasPrefix("es") == true ? "es" : "en"
    @State private var page = 0
    var onFinish: () -> Void
    private var es: Bool { language == "es" }
    private func text(_ spanish: String, _ english: String) -> String { es ? spanish : english }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 16) {
                Image(nsImage: NSImage(named: "TranscribeIcon") ?? NSImage(systemSymbolName: "waveform", accessibilityDescription: "Vocalia")!)
                    .resizable().scaledToFit().frame(width: 64, height: 64)
                Text("Vocalia").font(.system(size: 32, weight: .bold, design: .rounded))
            }
            if page == 0 {
                Text("Welcome / Bienvenido").font(.title2.bold())
                Text("Choose your language before starting.\nElige tu idioma antes de comenzar.").foregroundStyle(.secondary)
                Picker("Language / Idioma", selection: $language) {
                    Text("Español").tag("es")
                    Text("English").tag("en")
                }.pickerStyle(.segmented).frame(maxWidth: 360)
                Spacer()
            } else {
                Text(text("Tu primera transcripción", "Your first transcript")).font(.title2.bold())
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        step("1", text("Prepara el idioma del audio", "Prepare the audio language"), text("Elige el idioma que habla la persona y pulsa «Descargar idioma» si aún no está listo. La primera descarga requiere internet; tus grabaciones no se envían.", "Choose the language the person speaks and click “Download language” if it is not ready. The first download needs internet; your recordings are not uploaded."))
                        step("2", text("Agrega grabaciones", "Add recordings"), text("Pulsa «Agregar archivos o carpetas…» o arrastra tus audios y videos. Puedes cargar muchos a la vez. Agregar archivos todavía no genera texto.", "Choose “Add files or folders…” or drop audio and video files. You can add many at once. Adding files does not generate text yet."))
                        step("3", text("Pulsa «Transcribir pendientes»", "Click “Transcribe pending files”"), text("Espera mientras aparece el progreso y se genera el texto. El botón de reproducción solo sirve para escuchar el original; no transcribe.", "Wait for progress and the recognized text. The playback button only lets you listen to the original; it does not transcribe."))
                        step("4", text("Revisa y copia el texto completo", "Review and copy the full text"), text("Revisa nombres, cifras y citas. Pulsa «Copiar todo el texto» o exporta TXT. Al escuchar, el resaltado indica la posición del audio. Selecciona una frase para guardar una cuña.", "Check names, numbers and quotes. Choose “Copy full text” or export TXT. Highlighting follows the audio as you listen. Select a passage to save a quote."))
                        Text(text("Todo se procesa en tu Mac y los originales se conservan. Puedes volver a abrir esta guía y cambiar el idioma desde la pantalla principal.", "Everything is processed on your Mac and originals are kept. You can reopen this guide and change the app language from the main screen.")).foregroundStyle(.secondary)
                    }.padding(.trailing, 12)
                }
            }
            HStack {
                if page > 0 { Button(text("Atrás", "Back")) { page = 0 } }
                Spacer()
                Button(page == 0 ? "Continue / Continuar" : text("Empezar a usar Vocalia", "Start using Vocalia")) {
                    if page == 0 { page = 1 } else { onFinish() }
                }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
            }
        }.padding(32).frame(minWidth: 600, minHeight: 580)
        .background(Color(red: 0.97, green: 0.97, blue: 0.99))
        .environment(\.locale, Locale(identifier: language))
    }
    private func step(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.title3.bold()).foregroundStyle(.indigo).frame(width: 26)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(detail).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
