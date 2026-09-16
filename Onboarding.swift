import SwiftUI

struct VocaliaStartView: View {
    @AppStorage("languageChoice102Release") private var completed = false
    var body: some View {
        if completed { TranscribeView() }
        else { VocaliaLanguageChoice { completed = true } }
    }
}

struct VocaliaLanguageChoice: View {
    @AppStorage("uiLanguage") private var language = AppLanguage.system
    var onFinish: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Vocalia").font(.system(size: 32, weight: .bold, design: .rounded))
            Text(T("Welcome")).font(.title2.bold())
            Text(T("Choose your language before starting.")).foregroundStyle(.secondary)
            Picker(T("App language"), selection: $language) {
                ForEach(AppLanguage.options,id:\.code) { option in Text(option.name).tag(option.code) }
            }.pickerStyle(.menu)
            HStack { Spacer(); Button(T("Continue"), action: onFinish).buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction) }
        }.padding(40).frame(width: 480)
    }
}

struct TourAnchors: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
extension View {
    func tourTarget(_ key: String) -> some View {
        transformAnchorPreference(key: TourAnchors.self, value: .bounds) { values, anchor in values[key] = anchor }
    }
}

struct VocaliaCoachMarks: View {
    var anchors: [String: Anchor<CGRect>]
    var language: String
    var onFinish: () -> Void
    @State private var index = 0
    private func text(_ value:String)->String {AppLanguage.interface(value,language:language)}
    private let steps: [(String,String,String,String,String)] = [
        ("add", "Agrega tus grabaciones", "Agrega o arrastra grabaciones para iniciar la transcripción automáticamente. Los archivos se procesan uno a uno, incluidos OPUS.", "Add your recordings", "Add or drop recordings to start transcription automatically. Multiple files are processed one at a time, including OPUS."),
        ("audio", "Idioma de la grabación", "Elige el idioma que habla la persona. Este ajuste es independiente del idioma de los botones.", "Recording language", "Choose the audio language before adding recordings. It is independent of the interface language."),
        ("prepare", "Prepara el reconocimiento", "Si el idioma no está listo, descárgalo aquí con internet. Después puedes transcribir sin conexión. Tus grabaciones se quedan en tu Mac.", "Prepare speech recognition", "If a model is missing, download it once; transcription continues when it is ready. Recordings stay on this computer."),
        ("run", "Retoma grabaciones detenidas", "Los archivos nuevos empiezan automáticamente. Este botón reintenta grabaciones pendientes o detenidas. Cancelar detiene la cola; el análisis de voces sigue siendo manual.", "Resume stopped recordings", "New files start automatically. This button retries pending or stopped recordings. Cancel stops the queue; speaker analysis remains manual."),
        ("status", "Sigue el progreso", "Aquí verás la preparación, el progreso y el estado del reconocimiento. Espera a que termine para copiar el resultado completo.", "Follow progress", "This area shows preparation, progress and recognition status. Wait for completion before copying the full result."),
        ("editor", "Escucha, revisa y copia", "Aquí aparecerá tu transcripción completa. Revisa nombres y cifras. Reproducir solo sirve para escuchar; el resaltado sigue el audio. Usa Copiar todo el texto o Exportar para llevarte el resultado y selecciona frases para guardar cuñas.", "Listen, review and copy", "Your full transcript appears here. Check names and numbers. Play only plays audio; highlighting follows the recording. Use Copy full text or Export to take the result with you, and select passages to save quotes."),
        ("interface", "Cambia el idioma cuando quieras", "Aquí cambias los botones entre español e inglés. Puedes repetir este recorrido desde Cómo usar Vocalia.", "Change language any time", "Choose one of the six interface languages here. Reopen this tour from How to use Vocalia.")
    ]
    var body: some View {
        GeometryReader { proxy in
            let step = steps[index]
            if let anchor = anchors[step.0] {
                let target = proxy[anchor]
                let width: CGFloat = 350
                let height: CGFloat = 290
                let right = proxy.size.width - target.maxX > width + 24
                let left = target.minX > width + 24
                let x = min(max(right ? target.maxX + 18 : left ? target.minX - width - 18 : target.midX - width/2, 12), proxy.size.width - width - 12)
                let proposedY = right || left ? target.midY - height/2 : target.maxY + height + 24 < proxy.size.height ? target.maxY + 18 : target.minY - height - 18
                let y = min(max(proposedY, 12), proxy.size.height-height-12)
                RoundedRectangle(cornerRadius: 8).stroke(.indigo, lineWidth: 3)
                    .frame(width: max(0,target.width+8), height: max(0,target.height+8))
                    .position(x:target.midX,y:target.midY).allowsHitTesting(false)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("\(index+1) / \(steps.count)").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button(text("Skip"), action:onFinish).buttonStyle(.plain).keyboardShortcut(.cancelAction)
                    }
                    Text(text(step.3)).font(.headline)
                    ScrollView { Text(text(step.4)).font(.system(size:14)).frame(maxWidth:.infinity,alignment:.leading).fixedSize(horizontal:false,vertical:true) }
                    HStack {
                        Button(text("Back")) { index -= 1 }.disabled(index == 0)
                        Spacer()
                        Button(index == steps.count-1 ? text("Done") : text("Next")) {
                            if index == steps.count-1 { onFinish() } else { index += 1 }
                        }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    }
                }.padding(18).frame(width:width,height:height)
                    .background(Color.white,in:RoundedRectangle(cornerRadius:16))
                    .overlay(RoundedRectangle(cornerRadius:16).stroke(.indigo.opacity(0.6)))
                    .shadow(color:.black.opacity(0.15),radius:12,y:4)
                    .position(x:x+width/2,y:y+height/2)
                Text(right ? "◀" : left ? "▶" : y > target.midY ? "▲" : "▼")
                    .font(.system(size:22)).foregroundStyle(.indigo)
                    .position(x: right ? x-6 : left ? x+width+6 : min(max(target.midX,x+20),x+width-20),
                              y: right || left ? min(max(target.midY,y+24),y+height-24) : y > target.midY ? y-7 : y+height+7)
                    .allowsHitTesting(false)
            }
        }
    }
}
