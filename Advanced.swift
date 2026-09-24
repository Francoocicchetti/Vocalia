import Foundation
import SwiftUI
import AppKit

struct TimedToken: Codable, Equatable, Sendable { var text:String; var start:Double; var end:Double }
struct SavedQuote: Codable, Identifiable, Equatable, Sendable {
    var id = UUID(); var text:String; var speaker:String; var start:Double; var end:Double; var source:String; var sourceName:String; var created = Date(); var editedSource:Bool
    var citation:String { "\(text)\n\n\(speaker.isEmpty ? "Sin hablante asignado" : speaker) · \(sourceName) · \(TextExport.clock(start))–\(TextExport.clock(end))" }
}
struct ComparisonRow: Codable, Identifiable, Equatable, Sendable {
    var id = UUID(); var start:Double; var end:Double; var apple:String; var whisper:String
    var differs:Bool { TextAnalysis.normalized(apple) != TextAnalysis.normalized(whisper) }
}
struct TextSpan { var range:NSRange; var segment:Segment }
struct SelectionMatch { var text:String; var start:Double; var end:Double; var speaker:String; var edited:Bool }
enum TextAnalysis {
    static func normalized(_ s:String)->String { s.folding(options:[.caseInsensitive],locale:Locale(identifier:"es")).components(separatedBy:CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator:" ") }
    static func layout(_ doc:Transcript)->(String,[TextSpan]) {
        var text="";var spans:[TextSpan]=[];var previous:Segment?
        for s in doc.segments.filter({!$0.text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty}).sorted(by:{$0.start<$1.start}) {
            let body=s.text.trimmingCharacters(in:.whitespacesAndNewlines)
            if previous == nil || previous!.speaker != s.speaker {
                if !text.isEmpty {text += "\n\n"};if !s.speaker.isEmpty {text += s.speaker+": "}
            } else if let first=body.first, !",.;:!?".contains(first) {text += " "}
            let start=(text as NSString).length;text += body
            spans.append(TextSpan(range:NSRange(location:start,length:(body as NSString).length),segment:s));previous=s
        }
        return(text+"\n",spans)
    }
    static func locate(_ range:NSRange,in visible:String,document:Transcript)->SelectionMatch? {
        let ns=visible as NSString
        guard range.location != NSNotFound,range.length>0,range.location>=0,NSMaxRange(range)<=ns.length else{return nil}
        let quote=ns.substring(with:range)
        guard !quote.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return nil}
        let (original,spans)=layout(document)
        var originRange=range
        if visible != original {
            let originalNS=original as NSString
            let matches=originalNS.ranges(of:quote)
            guard matches.count == 1 else{return nil}
            originRange=matches[0]
        }
        let related=spans.filter { NSIntersectionRange($0.range,originRange).length>0 }
        guard let first=related.first,let last=related.last else{return nil}
        let speakers=Set(related.map{$0.segment.speaker}.filter{!$0.isEmpty})
        return SelectionMatch(text:quote,start:first.segment.start,end:last.segment.end,speaker:speakers.count==1 ? speakers.first! : "",edited:visible != original)
    }
    static func comparisons(apple:[Segment],whisper:[Segment])->[ComparisonRow] {
        func words(_ segments:[Segment])->[TimedToken] { segments.flatMap { s in if let w=s.wordTimings,!w.isEmpty {return w};return [TimedToken(text:s.text,start:s.start,end:s.end)] } }
        let a=words(apple),b=words(whisper);let end=max(a.map(\.end).max() ?? 0,b.map(\.end).max() ?? 0)
        guard end.isFinite,end>0,end<86401 else{return []}
        return stride(from:0.0,to:end,by:20).compactMap { start in
            func text(_ words:[TimedToken])->String { words.filter{($0.start+$0.end)/2>=start && ($0.start+$0.end)/2<start+20}.map{$0.text.trimmingCharacters(in:.whitespacesAndNewlines)}.joined(separator:" ") }
            let x=text(a),y=text(b);guard !x.isEmpty || !y.isEmpty else{return nil}
            return ComparisonRow(start:start,end:min(end,start+20),apple:x,whisper:y)
        }
    }
    static func assignVoices(_ segments:[Segment],intervals:[VoiceInterval])->[Segment] {
        let ids=Array(Set(intervals.flatMap(\.ids))).sorted()
        let names=Dictionary(uniqueKeysWithValues:ids.enumerated().map{($0.element,"Voz \($0.offset+1)")})
        func voice(_ start:Double,_ end:Double)->String {
            var scores:[Int:Double]=[:]
            for v in intervals where v.end>start && v.start<end {for id in v.ids{scores[id,default:0] += max(0,min(end,v.end)-max(start,v.start))}}
            let ranked=scores.sorted{$0.value>$1.value}
            guard let top=ranked.first,top.value>0 else{return "Voz sin determinar"}
            if ranked.count>1,ranked[1].value>max(0.15,(end-start)*0.30){return "Varias voces · revisar"}
            return names[top.key] ?? "Voz sin determinar"
        }
        return segments.flatMap { s -> [Segment] in
            guard let words=s.wordTimings,!words.isEmpty else{var copy=s;copy.speaker=voice(s.start,s.end);return [copy]}
            var groups:[[TimedToken]]=[];var labels:[String]=[]
            for word in words {let label=voice(word.start,word.end);if labels.last==label {groups[groups.count-1].append(word)}else{groups.append([word]);labels.append(label)}}
            if groups.count==1{var copy=s;copy.speaker=labels[0];return [copy]}
            // Only split when the word strings faithfully reconstruct the recognized text.
            let joined=words.map(\.text).joined().trimmingCharacters(in:.whitespacesAndNewlines)
            guard normalized(joined)==normalized(s.text) else{var copy=s;copy.speaker="Varias voces · revisar";return [copy]}
            return groups.enumerated().map { i,w in
                var part=Segment(start:w.first!.start,end:max(w.last!.end,w.first!.start+0.05),text:w.map(\.text).joined().trimmingCharacters(in:.whitespacesAndNewlines),original:w.map(\.text).joined().trimmingCharacters(in:.whitespacesAndNewlines),confidence:s.confidence,speaker:labels[i]);part.wordTimings=w;return part
            }
        }
    }
}
extension NSString {
    func ranges(of substring:String)->[NSRange] {var results:[NSRange]=[];var remaining=NSRange(location:0,length:length);while remaining.length>0 {let r=range(of:substring,options:[],range:remaining);if r.location==NSNotFound{break};results.append(r);if results.count>1{break};remaining=NSRange(location:NSMaxRange(r),length:length-NSMaxRange(r))};return results}
}

// Native temporary attributes keep playback decoration out of text, undo and exports.
struct PlaybackTextMap {
    let original:String
    let spans:[TextSpan]
    init(document:Transcript) {(original,spans)=TextAnalysis.layout(document)}
    func range(at time:Double,in visible:String)->NSRange? {
        guard time.isFinite,let span=spans.first(where:{$0.segment.start<=time && time<$0.segment.end}) else{return nil}
        let body=(original as NSString).substring(with:span.range)
        let base:NSRange
        if visible==original {base=span.range}
        else {
            let matches=(visible as NSString).ranges(of:body)
            guard matches.count==1 else{return nil}
            base=matches[0]
        }
        // Prefer supplied word/run times only when their strings map exactly to the text.
        if let tokens=span.segment.wordTimings,!tokens.isEmpty {
            let ns=body as NSString;var cursor=0;var active:NSRange?
            for token in tokens {
                let word=token.text.trimmingCharacters(in:.whitespacesAndNewlines)
                if word.isEmpty {continue}
                let r=ns.range(of:word,options:[],range:NSRange(location:cursor,length:ns.length-cursor))
                guard r.location != NSNotFound else{return base}
                let skipped=ns.substring(with:NSRange(location:cursor,length:r.location-cursor))
                guard skipped.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return base}
                if token.start<=time && time<token.end {active=NSRange(location:base.location+r.location,length:r.length)}
                cursor=NSMaxRange(r)
            }
            if ns.substring(from:cursor).trimmingCharacters(in:.whitespacesAndNewlines).isEmpty {return active ?? base}
        }
        return base
    }
}

struct SelectableTranscript: NSViewRepresentable {
    @Binding var text:String
    @Binding var selection:NSRange
    var editable:Bool
    var document:Transcript
    var playbackTime:Double?
    var playing:Bool
    var followAudio:Bool
    var clickToPlay:Bool
    var onWordClick:(Int)->Void
    func makeCoordinator()->Coordinator {Coordinator(self)}
    func makeNSView(context:Context)->NSScrollView {
        let scroll=NSScrollView();scroll.hasVerticalScroller=true;scroll.borderType = .noBorder;scroll.drawsBackground=false
        let view=PlaybackTextView();view.isRichText=false;view.isAutomaticQuoteSubstitutionEnabled=false;view.isAutomaticDashSubstitutionEnabled=false;view.isAutomaticTextReplacementEnabled=false;view.isAutomaticSpellingCorrectionEnabled=false
        view.font=NSFont.systemFont(ofSize:16);view.textColor = .labelColor;view.backgroundColor = .white;view.textContainerInset=NSSize(width:16,height:16)
        view.isVerticallyResizable=true;view.isHorizontallyResizable=false;view.autoresizingMask=[.width];view.textContainer?.widthTracksTextView=true;view.delegate=context.coordinator
        scroll.documentView=view;return scroll
    }
    func updateNSView(_ scroll:NSScrollView,context:Context) {
        context.coordinator.parent=self
        guard let view=scroll.documentView as? NSTextView else{return}
        if view.string != text {let old=view.selectedRange();context.coordinator.updating=true;view.string=text;let length=(text as NSString).length;view.setSelectedRange(NSRange(location:min(old.location,length),length:min(old.length,max(0,length-old.location))));context.coordinator.updating=false}
        view.isEditable=editable
        if let playerView=view as? PlaybackTextView {playerView.clickToPlay=clickToPlay;playerView.onWordClick=onWordClick}
        let coordinator=context.coordinator
        if coordinator.cachedSegments != document.segments || coordinator.documentID != document.id {
            coordinator.cachedSegments=document.segments;coordinator.documentID=document.id
            coordinator.mapping=PlaybackTextMap(document:document)
        }
        let active=playbackTime.flatMap{coordinator.mapping?.range(at:$0,in:text)}
        if coordinator.highlight != active || coordinator.lastText != text {
            if let old=coordinator.highlight,NSMaxRange(old)<=(view.string as NSString).length {
                view.layoutManager?.removeTemporaryAttribute(.backgroundColor,forCharacterRange:old)
            }
            if let active {
                view.layoutManager?.addTemporaryAttribute(.backgroundColor,value:NSColor.systemYellow.withAlphaComponent(0.42),forCharacterRange:active)
                if playing && followAudio && view.selectedRange().length==0 {view.scrollRangeToVisible(active)}
            }
            coordinator.highlight=active;coordinator.lastText=text
        }
    }
    final class Coordinator:NSObject,NSTextViewDelegate {
        var parent:SelectableTranscript;var updating=false
        var cachedSegments:[Segment]=[];var documentID:UUID?;var mapping:PlaybackTextMap?
        var highlight:NSRange?;var lastText=""
        init(_ p:SelectableTranscript){parent=p}
        func textDidChange(_ n:Notification){guard !updating,let view=n.object as? NSTextView else{return};parent.text=view.string}
        func textViewDidChangeSelection(_ n:Notification){guard !updating,let view=n.object as? NSTextView else{return};let range=view.selectedRange();DispatchQueue.main.async{self.parent.selection=range}}
    }
}

enum BatchFiles {
    struct Result:Sendable {var files:[URL];var omitted:Int;var limitReached:Bool}
    static func collect(_ inputs:[URL])->Result {
        let supported=Set(["mp3","mp4","mov","m4a","wav","aiff","aif","caf","aac","flac","m4v","opus","ogg"])
        let keys:Set<URLResourceKey>=[.isDirectoryKey,.isRegularFileKey,.isSymbolicLinkKey,.isPackageKey]
        var files:[URL]=[];var omitted=0;var seen=Set<String>();var limit=false
        func accept(_ url:URL) {
            guard files.count<10000 else{limit=true;return}
            guard let v=try? url.resourceValues(forKeys:keys),v.isSymbolicLink != true,v.isRegularFile == true,supported.contains(url.pathExtension.lowercased()) else{omitted += 1;return}
            let u=url.resolvingSymlinksInPath().standardizedFileURL
            if seen.insert(u.path).inserted {files.append(u)}
        }
        for input in inputs {
            guard input.isFileURL,let v=try? input.resourceValues(forKeys:keys),v.isSymbolicLink != true else{omitted += 1;continue}
            if v.isDirectory == true && v.isPackage != true {
                guard let it=FileManager.default.enumerator(at:input,includingPropertiesForKeys:Array(keys),options:[.skipsHiddenFiles,.skipsPackageDescendants],errorHandler:{_,_ in omitted += 1;return true}) else{omitted += 1;continue}
                while let u=it.nextObject() as? URL {
                    if files.count>=10000{limit=true;break}
                    let flags=try? u.resourceValues(forKeys:keys)
                    if flags?.isSymbolicLink == true{omitted += 1;continue}
                    if flags?.isDirectory == true{continue}
                    accept(u)
                }
            }else{accept(input)}
            if limit{break}
        }
        return Result(files:files.sorted{$0.path.localizedStandardCompare($1.path) == .orderedAscending},omitted:omitted,limitReached:limit)
    }
}
@MainActor extension TranscriptionModel {
    func refreshAdvancedStatus() async {advancedModelStatus=await LocalEngines.shared.readyDescription()}
    func saveDictionary(_ text:String) {
        let new=text.components(separatedBy:CharacterSet(charactersIn:",;\n")).map{$0.trimmingCharacters(in:.whitespacesAndNewlines)}.filter{!$0.isEmpty}.map{String($0.prefix(100))}
        dictionary=Array(Set(dictionary+new)).sorted{$0.localizedStandardCompare($1) == .orderedAscending}
        UserDefaults.standard.set(dictionary,forKey:"personalDictionary")
    }
    func removeTerm(_ term:String){dictionary.removeAll{$0==term};UserDefaults.standard.set(dictionary,forKey:"personalDictionary")}
    func saveOptions(){UserDefaults.standard.set(compareEnabled,forKey:"compareEnabled")}
    func prepareAdvancedModels(){
        guard !busy else{return};busy=true;saveOptions()
        task=Task {
            do{try await LocalEngines.shared.prepare(compare:true,voices:true,update:{s,p in Task{@MainActor in self.status=s;self.progress=p}});status="Los dos modelos adicionales están listos para trabajar sin conexión."}
            catch{status=Task.isCancelled ? L("Preparación cancelada.") : "No se pudieron preparar los modelos.";if !Task.isCancelled{self.error=error.localizedDescription}}
            busy=false;task=nil;await refreshAdvancedStatus()
        }
    }
    func analyzeAdvanced(_ id:UUID,prepared:PreparedAudio,voicesRequested:Bool=false) async throws {
        guard let i=documents.firstIndex(where:{$0.id==id}) else{return}
        saveOptions()
        let update:@Sendable(String,Double)->Void={s,p in Task{@MainActor in self.status=s;self.progress=p}}
        var failures:[String]=[]
        if voicesRequested {
          do {
            let intervals=try await LocalEngines.shared.voices(audio:prepared.url,offset:prepared.offset,expected:expectedSpeakers>0 ? expectedSpeakers : nil,update:update)
            documents[i].voiceIntervals=intervals
            documents[i].segments=TextAnalysis.assignVoices(documents[i].segments,intervals:intervals)
            documents[i].advancedStatus="Voces separadas automáticamente; revisa las etiquetas."
            persist()
          } catch {try Task.checkCancellation();failures.append("Voces: " + error.localizedDescription)}
        }
        if compareEnabled {
          do {
            let second=try await LocalEngines.shared.compare(audio:prepared.url,offset:prepared.offset,language:Locale(identifier:documents[i].locale).language.languageCode?.identifier ?? "es",terms:terms,update:update)
            documents[i].whisperSegments=second
            documents[i].comparison=TextAnalysis.comparisons(apple:documents[i].segments,whisper:second)
            documents[i].advancedStatus="Comparación terminada. Las diferencias son puntos para revisar, no errores demostrados."
            persist()
          } catch {try Task.checkCancellation();failures.append("Whisper: " + error.localizedDescription)}
        }
        await refreshAdvancedStatus()
        if !failures.isEmpty {throw TranscribeError.message(failures.joined(separator:"\n"))}
    }
    func runAdvanced(){
        guard !busy,let doc=current,doc.complete,!doc.segments.isEmpty else{return}
        busy=true;saveOptions();activeID=doc.id;stopPlayback()
        task=Task {
            let temp=FileManager.default.temporaryDirectory.appendingPathComponent("FrancoAdvanced-\(UUID().uuidString).caf")
            defer{try? FileManager.default.removeItem(at:temp)}
            do{
                try JSONEncoder().encode(doc).write(to:storage.appendingPathComponent("revision-\(doc.id.uuidString)-\(UUID().uuidString).json"),options:.atomic)
                status="Preparando audio para comparación y voces…"
                let converter=Task.detached{try await AudioPrep.convert(URL(fileURLWithPath:doc.source),into:temp){p in await MainActor.run{self.progress=p}}}
                let prepared=try await withTaskCancellationHandler{try await converter.value}onCancel:{converter.cancel()}
                try Task.checkCancellation();try await analyzeAdvanced(doc.id,prepared:prepared,voicesRequested:voicesEnabled)
                status="Análisis adicional terminado. Abre Comparación o Voces."
            }catch{
                status=Task.isCancelled ? L("Análisis adicional cancelado; tu transcripción se conserva.") : "No se pudo completar el análisis adicional."
                if let i=documents.firstIndex(where:{$0.id==doc.id}){documents[i].advancedStatus=status+" "+error.localizedDescription}
                if !Task.isCancelled{self.error=error.localizedDescription}
            }
            busy=false;activeID=nil;task=nil;persist()
        }
    }
    func quoteMatch(range:NSRange)->SelectionMatch?{guard let doc=current else{return nil};return TextAnalysis.locate(range,in:TextExport.render(doc,kind:"txt"),document:doc)}
    func saveQuote(range:NSRange,speaker:String){
        guard let i=selectedIndex,let m=quoteMatch(range:range) else{error="Selecciona una frase del texto que coincida con la transcripción para poder conservar su tiempo. Una frase reescrita o repetida puede necesitar revisión en audio.";return}
        let doc=documents[i]
        let quote=SavedQuote(text:m.text,speaker:speaker.isEmpty ? m.speaker : speaker,start:m.start,end:m.end,source:doc.source,sourceName:doc.name,editedSource:m.edited)
        if documents[i].quotes == nil{documents[i].quotes=[]}
        documents[i].quotes!.append(quote);persist();status="Cuña guardada con su texto literal, archivo y tiempo."
    }
    func copyQuote(_ quote:SavedQuote,withSource:Bool){NSPasteboard.general.clearContents();NSPasteboard.general.setString(withSource ? quote.citation : quote.text,forType:.string);status="Cuña copiada."}
    func exportQuotes(){guard let doc=current,let quotes=doc.quotes,!quotes.isEmpty else{return};let p=NSSavePanel();p.nameFieldStringValue=URL(fileURLWithPath:doc.name).deletingPathExtension().lastPathComponent+" - cuñas.txt";p.allowedContentTypes=[.plainText];if p.runModal() == .OK,let url=p.url{do{try quotes.map(\.citation).joined(separator:"\n\n———\n\n").write(to:url,atomically:true,encoding:.utf8);status="Cuñas exportadas."}catch{self.error=error.localizedDescription}}}
    func renameVoice(from:String,to:String){guard !busy,let i=selectedIndex,!to.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return};let name=to.trimmingCharacters(in:.whitespacesAndNewlines);for j in documents[i].segments.indices where documents[i].segments[j].speaker==from{documents[i].segments[j].speaker=name};if let q=documents[i].quotes{documents[i].quotes=q.map{var copy=$0;if copy.speaker==from{copy.speaker=name};return copy}};persist()}
    func exportBatch(){
        let ready=documents.filter{!$0.segments.isEmpty};guard !ready.isEmpty else{return}
        let panel=NSOpenPanel();panel.canChooseDirectories=true;panel.canChooseFiles=false;panel.prompt=L("Guardar todos los TXT")
        if panel.runModal() == .OK,let root=panel.url{
            var failures=0
            for doc in ready{
                let suffix=doc.complete ? "" : " - PARCIAL"
                let base=URL(fileURLWithPath:doc.name).deletingPathExtension().lastPathComponent+suffix
                var url=root.appendingPathComponent(base+".txt");var n=1
                while FileManager.default.fileExists(atPath:url.path){url=root.appendingPathComponent(base+" (\(n)).txt");n += 1}
                do{try Data(TextExport.render(doc,kind:"txt").utf8).write(to:url,options:.withoutOverwriting)}catch{failures += 1}
            }
            status="\(ready.count-failures) transcripciones exportadas\(failures>0 ? "; \(failures) no pudieron guardarse" : "")."
        }
    }
}

struct DictionaryPane:View {
    @ObservedObject var model:TranscriptionModel
    @Environment(\.dismiss) var dismiss
    @State var input=""
    var body:some View {
        VStack(alignment:.leading,spacing:16){
            Text(L("Tu diccionario personal")).font(.title2.bold())
            Text(L("Guarda autoridades, comunas, apellidos e instituciones. Se usan como contexto, sin reemplazar palabras automáticamente.")).foregroundStyle(.secondary)
            HStack{TextField(L("Nombres o siglas separados por comas"),text:$input).textFieldStyle(.roundedBorder);Button(L("Guardar")){model.saveDictionary(input);input=""}.disabled(input.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)}
            List{ForEach(model.dictionary,id:\.self){term in HStack{Text(term);Spacer();Button{model.removeTerm(term)}label:{Image(systemName:"minus.circle")}.buttonStyle(.borderless).help(L("Quitar término"))}}}
            Text(L("Se envían hasta 100 términos al motor en cada grabación. Whisper usa el contexto que cabe en su ventana de indicaciones.")).font(.caption).foregroundStyle(.secondary)
            HStack{Spacer();Button(L("Listo")){dismiss()}.keyboardShortcut(.defaultAction)}
        }.padding(24).frame(width:590,height:470)
    }
}
struct QuotesPane:View {
    @ObservedObject var model:TranscriptionModel
    let document:Transcript
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            HStack{Text(L("Cuñas guardadas")).font(.headline);Spacer();Button(L("Exportar cuñas")){model.exportQuotes()}.disabled(document.quotes?.isEmpty != false)}
            Text(L("Selecciona la cita en Texto completo y pulsa Guardar cuña. Se conserva exactamente lo seleccionado, con su origen y tiempo.")).font(.caption).foregroundStyle(.secondary)
            ScrollView{LazyVStack(alignment:.leading,spacing:12){ForEach(document.quotes ?? []){q in
                VStack(alignment:.leading,spacing:10){
                    Text(q.text).font(.system(size:16)).textSelection(.enabled)
                    Text(L("\(q.speaker.isEmpty ? "Hablante sin asignar" : q.speaker) · \(q.sourceName) · \(TextExport.clock(q.start))–\(TextExport.clock(q.end))")).font(.caption).foregroundStyle(.secondary)
                    HStack{Button(L("Escuchar")){model.play(at:q.start,until:q.end)};Button(L("Copiar cita")){model.copyQuote(q,withSource:false)};Button(L("Copiar con fuente")){model.copyQuote(q,withSource:true)}}
                }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(.white,in:RoundedRectangle(cornerRadius:12))
            }}}
            if document.quotes?.isEmpty != false{Text(L("Todavía no hay cuñas guardadas para esta grabación.")).foregroundStyle(.secondary).frame(maxWidth:.infinity,maxHeight:.infinity)}
        }.padding(18)
    }
}
struct ComparisonPane:View {
    @ObservedObject var model:TranscriptionModel
    let document:Transcript
    @State var differencesOnly=true
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            HStack{Text(L("Apple ↔ Whisper")).font(.headline);Spacer();Toggle(L("Solo diferencias"),isOn:$differencesOnly).toggleStyle(.checkbox)}
            Text(L("Compara dos reconocimientos locales del mismo audio. Los bloques de unos 20 segundos resaltan diferencias; ninguna versión se considera automáticamente correcta.")).font(.caption).foregroundStyle(.secondary)
            if let state=document.advancedStatus{Text(L(state)).font(.caption).foregroundStyle(.secondary)}
            if let rows=document.comparison{
                Text(L("\(rows.filter(\.differs).count) bloques con diferencias de \(rows.count)")).font(.caption)
                Button(L("Copiar versión completa de Whisper")){
                    var doc=document;doc.fullTextOverride=nil;doc.segments=doc.whisperSegments ?? []
                    NSPasteboard.general.clearContents();NSPasteboard.general.setString(TextExport.render(doc,kind:"txt"),forType:.string)
                }
                ScrollView{LazyVStack(alignment:.leading,spacing:12){ForEach(rows.filter{!differencesOnly || $0.differs}){row in
                    VStack(alignment:.leading,spacing:10){
                        Button(L("Escuchar \(TextExport.clock(row.start))–\(TextExport.clock(row.end))")){model.play(at:row.start,until:row.end)}.buttonStyle(.link)
                        HStack(alignment:.top,spacing:18){
                            VStack(alignment:.leading,spacing:6){Text(L("APPLE")).font(.caption.bold());Text(row.apple.isEmpty ? L("Sin texto en este tramo") : row.apple).textSelection(.enabled)}.frame(maxWidth:.infinity,alignment:.leading)
                            Divider()
                            VStack(alignment:.leading,spacing:6){Text(L("WHISPER")).font(.caption.bold());Text(row.whisper.isEmpty ? L("Sin texto en este tramo") : row.whisper).textSelection(.enabled)}.frame(maxWidth:.infinity,alignment:.leading)
                        }
                    }.padding(14).background(row.differs ? Color.orange.opacity(0.08) : .white,in:RoundedRectangle(cornerRadius:12))
                }}}
            }else{Text(L("Activa Comparar con Whisper y pulsa Analizar voces / comparar. La primera vez se descarga un modelo; luego funciona sin conexión.")).foregroundStyle(.secondary).frame(maxWidth:.infinity,maxHeight:.infinity)}
        }.padding(18)
    }
}
struct VoicesPane:View {
    @ObservedObject var model:TranscriptionModel
    let document:Transcript
    @State var chosen=""
    @State var name=""
    var labels:[String]{Array(Set(document.segments.map(\.speaker).filter{!$0.isEmpty})).sorted()}
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            Text(L("Voces y hablantes")).font(.headline)
            Text(L("El modelo agrupa voces como Voz 1, Voz 2… Tú les asignas nombres. Las etiquetas son propias de esta grabación y pueden confundirse si hay ruido o voces superpuestas.")).font(.caption).foregroundStyle(.secondary)
            HStack{Text(L("Cantidad de voces"));Picker(L("Cantidad"),selection:$model.expectedSpeakers){Text(L("Automática")).tag(0);ForEach(1..<9){Text(L("\($0)")).tag($0)}}.labelsHidden().frame(width:150);Spacer()}.disabled(model.busy)
            Text(L("Si conoces cuántas personas hablan, indícalo antes de analizar. Recalcular voces puede cambiar las etiquetas.")).font(.caption).foregroundStyle(.secondary)
            if labels.isEmpty{Text(L("Activa Separar voces y pulsa Analizar voces / comparar.")).foregroundStyle(.secondary)}
            else{
                HStack{
                    Picker(L("Voz"),selection:$chosen){Text(L("Elige una voz")).tag("");ForEach(labels,id:\.self){Text($0).tag($0)}}
                    TextField(L("Nombre de la persona"),text:$name).textFieldStyle(.roundedBorder)
                    Button(L("Asignar nombre")){model.renameVoice(from:chosen,to:name);chosen=name;name=""}.disabled(chosen.isEmpty || name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                }.disabled(model.busy)
                ScrollView{LazyVStack(alignment:.leading,spacing:10){ForEach(document.segments){s in HStack(alignment:.top){Button(TextExport.clock(s.start)){model.play(at:s.start,until:s.end)}.buttonStyle(.link);VStack(alignment:.leading){Text(s.speaker.isEmpty ? L("Sin asignar") : s.speaker).font(.caption.bold());Text(s.text).textSelection(.enabled)}}.padding(10).frame(maxWidth:.infinity,alignment:.leading).background(.white,in:RoundedRectangle(cornerRadius:10))}}}
            }
            if document.fullTextOverride != nil{Text(L("Tu texto completo editado se conserva. Los nombres se aplican a los fragmentos y las cuñas guardadas.")).font(.caption).foregroundStyle(.secondary)}
            Spacer(minLength:0)
        }.padding(18)
    }
}

enum AdvancedTests {
    @MainActor static func autoImport() async {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent("VocaliaAutoTests-\(UUID())")
        defer{try? FileManager.default.removeItem(at:root)}
        let model=TranscriptionModel(storageOverride:root)
        var old=Transcript(source:"/missing-old.wav",name:"Edited history")
        old.fullTextOverride="Keep my edited quote";model.documents=[old]
        let first=root.appendingPathComponent("one.wav"),second=root.appendingPathComponent("two.opus")
        try! Data().write(to:first);try! Data().write(to:second)
        model.busy=true
        model.add([first,first]);model.add([second])
        for _ in 0..<100 where model.documents.count < 3 {try? await Task.sleep(for:.milliseconds(50))}
        precondition(model.documents.count == 3,"Concurrent imports and duplicate paths")
        // Missing sources exercise the real queue without a model download or audio data.
        try! FileManager.default.removeItem(at:first);try! FileManager.default.removeItem(at:second)
        model.busy=false
        for _ in 0..<100 {
            if model.documents.dropFirst().allSatisfy({$0.state.hasPrefix("Error:")}) && !model.busy {break}
            try? await Task.sleep(for:.milliseconds(50))
        }
        precondition(model.documents.dropFirst().allSatisfy{$0.state.hasPrefix("Error:")},"Imported recordings start without a button; failure continues")
        precondition(model.documents[0] == old,"Auto import preserves historical edits")
        let stopped=Transcript(source:"/missing-stopped.wav",name:"Stopped")
        model.documents.append(stopped);model.checkingLanguage=true
        model.startImported([stopped.id],generation:model.importGeneration)
        model.cancel();model.checkingLanguage=false
        try? await Task.sleep(for:.milliseconds(250))
        precondition(model.documents.last == stopped && !model.busy,"Cancel prevents deferred automatic restart")
        precondition(!model.voicesEnabled,"Automatic transcription does not enable speakers")
        print("PASS: Mac automatic concurrent imports, deduplication, history, failure continuation, cancellation and manual speakers")
    }

    @MainActor static func run(){
        var n=0;func check(_ ok:Bool,_ label:String){if !ok{print("FAIL \(label)");exit(1)};n += 1;print("OK \(label)")}
        check(AppLanguage.translate("Texto completo",language:"en")=="Full text","Interfaz inglesa traduce controles")
        check(AppLanguage.translate("Archivo 2 de 4",language:"en")=="File 2 of 4","Interfaz inglesa conserva cifras dinámicas")
        check(AppLanguage.translate("Texto completo",language:"es")=="Texto completo","Interfaz española conserva controles")
        check(AppLanguage.translate("Mi entrevista inédita",language:"en")=="Mi entrevista inédita","Traducción no modifica texto ajeno al catálogo")

        let testStore=FileManager.default.temporaryDirectory.appendingPathComponent("VocaliaRegression-\(UUID())")
        defer{try? FileManager.default.removeItem(at:testStore)}
        let model=TranscriptionModel(storageOverride:testStore)
        check(!model.voicesEnabled,"Separación de voces desactivada al iniciar")
        var first=Transcript(source:"/first.mp3",name:"first.mp3")
        first.segments=[Segment(start:0,end:2,text:"Primera",original:"Primera",confidence:1)]
        let second=Transcript(source:"/second.mp3",name:"second.mp3")
        model.documents=[first,second]
        let retainedText=model.textBinding(for:first)
        let retainedSegment=model.segmentBinding(documentID:first.id,snapshot:first.segments[0])
        model.documents.reverse();retainedText.wrappedValue="Edición correcta"
        check(model.documents.first(where:{$0.id==first.id})?.fullTextOverride=="Edición correcta" && model.documents[0].fullTextOverride==nil,"Edición sigue el ID después de reordenar")
        model.documents.removeAll{$0.id==first.id}
        check(retainedText.wrappedValue.contains("Primera"),"Editor retenido sobrevive a eliminar su grabación")
        retainedText.wrappedValue="No debe escribirse";retainedSegment.wrappedValue.text="Tampoco"
        check(model.documents.count==1 && model.documents[0].fullTextOverride==nil && model.documents[0].segments.isEmpty,"Callbacks antiguos no alteran otra grabación")
        model.documents=[]
        check(retainedSegment.wrappedValue.text=="Primera","Editor de fragmento sobrevive a vaciar historial")
        var d=Transcript(source:"/audio.mp3",name:"audio.mp3")
        d.segments=[Segment(start:1,end:4,text:"Hola, Chile.",original:"Hola, Chile.",confidence:1),Segment(start:5,end:8,text:"Una segunda frase.",original:"Una segunda frase.",confidence:1)]
        let(text,_)=TextAnalysis.layout(d)
        check(text==TextExport.render(d,kind:"txt"),"Texto y mapa temporal coinciden")
        let r=(text as NSString).range(of:"Chile. Una segunda")
        let m=TextAnalysis.locate(r,in:text,document:d)
        check(m?.start==1 && m?.end==8 && m?.text=="Chile. Una segunda","Selección cruza fragmentos sin cambiar la cita")
        check(TextAnalysis.locate(NSRange(location:999,length:4),in:text,document:d)==nil,"No acepta selección fuera del texto")
        let edited="Título\n"+text
        check(TextAnalysis.locate((edited as NSString).range(of:"segunda frase"),in:edited,document:d)?.start==5,"Localiza cita intacta dentro de texto editado")
        check(TextAnalysis.locate(NSRange(location:0,length:6),in:edited,document:d)==nil,"No inventa tiempo para palabras añadidas")
        d.segments.append(Segment(start:10,end:12,text:"Hola, Chile.",original:"Hola, Chile.",confidence:1))
        check(TextAnalysis.locate(NSRange(location:0,length:12),in:"Hola, Chile. \n",document:d)==nil,"Texto editado repetido requiere revisión")
        let assigned=TextAnalysis.assignVoices(d.segments,intervals:[VoiceInterval(start:0,end:4,ids:[0]),VoiceInterval(start:5,end:9,ids:[1]),VoiceInterval(start:10,end:12,ids:[0])])
        check(assigned.map(\.speaker)==["Voz 1","Voz 2","Voz 1"],"Asigna hablantes por intervalos")
        let rows=TextAnalysis.comparisons(apple:d.segments,whisper:d.segments)
        check(!rows.contains(where:\.differs),"Comparación idéntica sin diferencias")
        var other=d.segments;other[0].text="Adiós, Chile."
        check(TextAnalysis.comparisons(apple:d.segments,whisper:other).contains(where:\.differs),"Detecta divergencias entre motores")
        check(TextAnalysis.normalized("sí") != TextAnalysis.normalized("si"),"Conserva diferencias de acentos con significado")
        let q=SavedQuote(text:"Cita literal",speaker:"Ana",start:1,end:4,source:d.source,sourceName:d.name,editedSource:false)
        d.quotes=[q];d.comparison=rows;d.whisperSegments=other
        do{let restored=try JSONDecoder().decode(Transcript.self,from:JSONEncoder().encode(d));check(restored==d,"Cuñas y comparación persisten") }catch{check(false,"Persistencia avanzada")}
        var playbackDoc=Transcript(source:"/sample.mp3",name:"sample.mp3")
        var timed=Segment(start:0,end:3,text:"Hola Chile",original:"Hola Chile",confidence:1)
        timed.wordTimings=[TimedToken(text:"Hola",start:0,end:1),TimedToken(text:" Chile",start:1,end:3)]
        playbackDoc.segments=[timed,Segment(start:4,end:6,text:"Otra frase",original:"Otra frase",confidence:1)]
        let playback=PlaybackTextMap(document:playbackDoc);let full=TextExport.render(playbackDoc,kind:"txt")
        check(playback.range(at:0.5,in:full)==(full as NSString).range(of:"Hola"),"Resalta palabra con tiempo real")
        check(playback.range(at:1.5,in:full)==(full as NSString).range(of:"Chile"),"Avanza a la siguiente palabra")
        check(playback.range(at:3.5,in:full)==nil,"Silencio sin resaltado falso")
        check(playback.range(at:4.5,in:full)==(full as NSString).range(of:"Otra frase"),"Historial sin tiempos por palabra sigue el fragmento")
        check(playback.range(at:7,in:full)==nil,"Final del audio limpia el resaltado")
        let prefixed="Título\n"+full
        check(playback.range(at:1.5,in:prefixed)==(prefixed as NSString).range(of:"Chile"),"Sigue texto conservado después de una edición")
        check(playback.range(at:1.5,in:"Texto completamente reescrito")==nil,"No inventa sincronización en texto reescrito")
        check(playback.range(at:1.5,in:"Hola Chile. Hola Chile.")==nil,"No confunde frases repetidas tras editar")
        check(TextExport.render(playbackDoc,kind:"txt")==full,"Resaltado no cambia texto exportado")
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent("FrancoBatch-\(UUID().uuidString)")
        defer{try? FileManager.default.removeItem(at:folder)}
        do{
            try FileManager.default.createDirectory(at:folder.appendingPathComponent("Sub"),withIntermediateDirectories:true)
            for i in 0..<120{try Data("test".utf8).write(to:folder.appendingPathComponent("Sub/\(i).mp3"))}
            try Data("ignore".utf8).write(to:folder.appendingPathComponent("nota.txt"))
            try FileManager.default.createSymbolicLink(at:folder.appendingPathComponent("enlace"),withDestinationURL:folder)
            let opus = folder.appendingPathComponent("voice.OPUS")
            try Data("test".utf8).write(to: opus)
            check(BatchFiles.collect([opus]).files.count == 1, "Importa OPUS sin distinguir mayúsculas")
            try FileManager.default.removeItem(at: opus)
            let found=BatchFiles.collect([folder,folder.appendingPathComponent("Sub/1.mp3")])
            if found.files.count != 120 {print("DIAGNOSTICO archivos=\(found.files.count) omitidos=\(found.omitted) rutas=\(found.files.prefix(3)) carpeta=\(folder.path)")}
            check(found.files.count==120,"Carga 120 archivos recursivos sin duplicados")
            check(found.omitted>=2,"Omite archivos ajenos y enlaces circulares")
        }catch{check(false,"Carga múltiple")}
        for (language, expected) in [("de", "Vollständiger Text"), ("fr", "Texte intégral"), ("pt", "Texto completo"), ("zh", "完整文本")] {
            check(AppLanguage.translate("Texto completo", language:language)==expected, "Interfaz \(language) carga su catálogo")
            check(!AppLanguage.translate("Archivo 2 de 4",language:language).contains("%@"), "Interfaz \(language) conserva valores dinámicos")
        }
        check(NumberFormatting.format("Fue 9, coma, 5 por ciento.",language:"es-CL")=="Fue 9,5 por ciento.","Formato numérico 0")
        check(NumberFormatting.format("nueve coma cinco",language:"es-CL")=="9,5","Formato numérico 1")
        check(NumberFormatting.format("El 0 coma 05 %",language:"es-CL")=="El 0,05 %","Formato numérico 2")
        check(NumberFormatting.format("cero coma cero cinco",language:"es-CL")=="0,05","Formato numérico 3")
        check(NumberFormatting.format("treinta y nueve coma cincuenta y cinco",language:"es-CL")=="39,55","Formato numérico 4")
        check(NumberFormatting.format("-9 coma 5",language:"es-CL")=="-9,5","Formato numérico 5")
        check(NumberFormatting.format("9,5 y 10,25",language:"es-CL")=="9,5 y 10,25","Formato numérico 6")
        check(NumberFormatting.format("9, 5 y 3",language:"es-CL")=="9, 5 y 3","Formato numérico 7")
        check(NumberFormatting.format("Ponga una coma entre 9 y 5.",language:"es-CL")=="Ponga una coma entre 9 y 5.","Formato numérico 8")
        check(NumberFormatting.format("ciento nueve coma cinco",language:"es-CL")=="ciento nueve coma cinco","Formato numérico 9")
        check(NumberFormatting.format("mil nueve coma cinco",language:"es-CL")=="mil nueve coma cinco","Formato numérico 10")
        check(NumberFormatting.format("9 coma\n5",language:"es-CL")=="9 coma\n5","Formato numérico 11")
        check(NumberFormatting.format("9 coma 5 y después 10 coma 2",language:"es-CL")=="9,5 y después 10,2","Formato numérico 12")
        check(NumberFormatting.format("9 coma cinco y medio",language:"es-CL")=="9 coma cinco y medio","Formato numérico 13")
        check(NumberFormatting.format("dieciséis coma veintidós",language:"es-CL")=="16,22","Formato numérico 14")
        check(NumberFormatting.format("9 coma 5",language:"en")=="9 coma 5","La normalización usa el idioma del audio")
        let digits=NumberFormatting.tokens([TimedToken(text:" 9,",start:1,end:2),TimedToken(text:" coma,",start:2,end:3),TimedToken(text:" 5",start:3,end:4),TimedToken(text:" pesos",start:4,end:5)],language:"es")
        check(digits.count==2 && digits[0].text==" 9,5" && digits[0].start==1 && digits[0].end==4,"Decimal conserva el intervalo completo del audio")
        var numeric=Segment(start:0,end:1,text:"9,5 %",original:"9 coma 5 %",confidence:0.99)
        check(numeric.uncertain,"Las cifras se ofrecen para revisión aunque la confianza sea alta")
        numeric.reviewed=true;check(!numeric.uncertain,"La revisión humana de cifras se respeta")
        check(NumberFormatting.format("Subió 12 coma 75 por ciento.",language:"es")=="Subió 12,75 por ciento.","Decimales en porcentajes")
        check(NumberFormatting.format("$1234567, coma, 005",language:"es")=="$1234567,005","Montos grandes y ceros significativos")
        check(NumberFormatting.format("16/09/2026; 12:30; 1.500 pesos",language:"es")=="16/09/2026; 12:30; 1.500 pesos","Fechas, horas y miles conservan su formato")
        print("\(n) pruebas avanzadas correctas")
    }
}
