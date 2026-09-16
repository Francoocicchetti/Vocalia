import SwiftUI
import AppKit
import AVFoundation
import Speech
import UniformTypeIdentifiers

struct Segment: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var start: Double
    var end: Double
    var text: String
    var original: String
    var confidence: Double?
    var alternatives: [String] = []
    var speaker = ""
    var reviewed = false
    var wordTimings: [TimedToken]? = nil
    var uncertain: Bool { !reviewed && ((confidence.map { $0 < 0.75 } ?? false) || text.unicodeScalars.contains { CharacterSet.decimalDigits.contains($0) }) }
}
struct Transcript: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var source: String
    var name: String
    var created = Date()
    var segments: [Segment] = []
    var state = "Pendiente"
    var duration: Double = 0
    var locale = ""
    var complete = false
    var fullTextOverride: String? = nil
    var quotes: [SavedQuote]? = nil
    var whisperSegments: [Segment]? = nil
    var comparison: [ComparisonRow]? = nil
    var voiceIntervals: [VoiceInterval]? = nil
    var advancedStatus: String? = nil
}
enum TranscribeError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let s) = self { return s }; return nil }
}
enum TextExport {
    static func time(_ seconds: Double, separator: String = ",") -> String {
        let n = Int((max(0, seconds.isFinite ? seconds : 0) * 1000).rounded())
        return String(format: "%02d:%02d:%02d", n / 3600000, (n / 60000) % 60, (n / 1000) % 60) + separator + String(format: "%03d", n % 1000)
    }
    static func clock(_ t: Double) -> String { String(time(t).prefix(8)) }
    static func body(_ s: Segment) -> String { (s.speaker.isEmpty ? "" : "\(s.speaker): ") + s.text.trimmingCharacters(in: .whitespacesAndNewlines) }
    static func render(_ doc: Transcript, kind: String) -> String {
        let segments = doc.segments.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.sorted { $0.start < $1.start }
        if kind == "txt" {
            if let edited = doc.fullTextOverride { return edited }
            var paragraphs: [String] = []
            var paragraph = ""
            var previous: Segment?
            for segment in segments {
                let newParagraph = previous.map { segment.speaker != $0.speaker } ?? true
                if newParagraph {
                    if !paragraph.isEmpty { paragraphs.append(paragraph) }
                    paragraph = body(segment)
                } else {
                    let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    let punctuation = text.first.map { ",.;:!?".contains($0) } ?? false
                    paragraph += (punctuation ? "" : " ") + text
                }
                previous = segment
            }
            if !paragraph.isEmpty { paragraphs.append(paragraph) }
            return paragraphs.joined(separator: "\n\n") + "\n"
        }
        let sep = kind == "vtt" ? "." : ","
        return (kind == "vtt" ? "WEBVTT\n\n" : "") + segments.enumerated().map { i,s in
            "\(i+1)\n\(time(s.start, separator: sep)) --> \(time(max(s.start + 0.05, s.end), separator: sep))\n\(body(s).replacingOccurrences(of: "\n\n", with: "\n"))\n"
        }.joined(separator: "\n")
    }
}

struct PreparedAudio: Sendable { let url: URL; let duration: Double; let offset: Double; let multipleTracks: Bool }
enum AudioPrep {
    static func convert(_ source: URL, into target: URL, progress: @escaping @Sendable (Double) async -> Void) async throws -> PreparedAudio {
        if OpusAudio.needsDecoding(source) {
            let decoded = try await OpusAudio.shared.playable(source)
            return try await convert(decoded, into: target, progress: progress)
        }
        let asset = AVURLAsset(url: source)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = tracks.first else { throw TranscribeError.message("El archivo no contiene una pista de audio.") }
        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0, duration < 24 * 3600 else { throw TranscribeError.message("Duración no válida. Usa archivos de menos de 24 horas.") }
        let reader = try AVAssetReader(asset: asset)
        let settings: [String: Any] = [AVFormatIDKey:kAudioFormatLinearPCM, AVSampleRateKey:16000, AVNumberOfChannelsKey:1, AVLinearPCMBitDepthKey:32, AVLinearPCMIsFloatKey:true, AVLinearPCMIsBigEndianKey:false, AVLinearPCMIsNonInterleaved:false]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { throw TranscribeError.message("No se puede leer el audio de este archivo.") }
        reader.add(output)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
        let writer = try AVAudioFile(forWriting: target, settings: format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
        guard reader.startReading() else { throw reader.error ?? TranscribeError.message("No se pudo abrir la pista de audio.") }
        defer { if reader.status == .reading { reader.cancelReading() } }
        var offset: Double?; var written: Int64 = 0; var count = 0
        while let sample = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            let pts = CMSampleBufferGetPresentationTimeStamp(sample).seconds
            if offset == nil { offset = pts.isFinite ? max(0, pts) : 0 }
            // Preserve gaps so transcript timestamps continue to match the original video.
            let position = pts.isFinite ? max(0, Int64(((pts - (offset ?? 0)) * 16000).rounded())) : written
            while position - written > 2 {
                let frames = AVAudioFrameCount(min(position - written, 8192))
                let silence = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
                silence.frameLength = frames
                memset(silence.floatChannelData![0], 0, Int(frames) * 4)
                try writer.write(from: silence); written += Int64(frames)
                try Task.checkCancellation()
            }
            let frames = CMSampleBufferGetNumSamples(sample)
            guard frames > 0, let block = CMSampleBufferGetDataBuffer(sample) else { continue }
            guard CMBlockBufferGetDataLength(block) == frames * 4 else { throw TranscribeError.message("El formato del audio no se pudo convertir correctamente.") }
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
            buffer.frameLength = AVAudioFrameCount(frames)
            let code = CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: frames * 4, destination: buffer.floatChannelData![0])
            guard code == kCMBlockBufferNoErr else { throw TranscribeError.message("No se pudieron leer las muestras de audio.") }
            try writer.write(from: buffer); written += Int64(frames); count += 1
            if count % 100 == 0 { await progress(min(1, Double(written) / 16000 / duration)) }
        }
        try Task.checkCancellation()
        guard reader.status == .completed, written > 0 else { throw reader.error ?? TranscribeError.message("No se encontró audio utilizable.") }
        return PreparedAudio(url: target, duration: duration, offset: offset ?? 0, multipleTracks: tracks.count > 1)
    }
}

@MainActor final class TranscriptionModel: ObservableObject {
    @Published var documents: [Transcript] = []
    @Published var selected: UUID?
    @Published var busy = false
    @Published var status = "Agrega una grabación para empezar."
    @Published var engineStatus = "Comprobando el modelo de voz…"
    @Published var progress: Double = 0
    @Published var vocabulary = UserDefaults.standard.string(forKey: "vocabulary") ?? ""
    @Published var error: String?
    @Published var downloadProgress: Progress?
    @Published var isPlaying = false
    @Published var playbackTime: Double = 0
    @Published var playbackRate: Float = 1
    @Published var locales: [Locale] = []
    @Published var localeID = UserDefaults.standard.string(forKey: "locale") ?? "es-CL"
    @Published var dictionary: [String] = UserDefaults.standard.stringArray(forKey: "personalDictionary") ?? []
    @Published var compareEnabled = UserDefaults.standard.object(forKey: "compareEnabled") as? Bool ?? false
    @Published var voicesEnabled = false // Speaker analysis requires a fresh, explicit manual request.
    @Published var expectedSpeakers = 0
    @Published var advancedModelStatus = "Modelos adicionales: comprobando…"
    @Published var queue: [UUID] = []
    @Published var batchTotal = 0
    @Published var batchFinished = 0
    @Published var importing = false
    var processingQueue = false
    var playbackEnd: Double?
    var playbackRequest=UUID()
    var downloadObservation:NSKeyValueObservation?
    var activeID: UUID?
    var terms: [String] { Array(Set(dictionary + vocabulary.components(separatedBy: CharacterSet(charactersIn: ",;\n")).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })).sorted().prefix(100).map { String($0.prefix(100)) } }
    var task: Task<Void, Never>?
    var analyzer: SpeechAnalyzer?
    var player: AVPlayer?
    var loadedSource: String?
    var observation: Any?
    var chosenLocale: Locale?
    var languageCheckID=UUID()
    @Published var languageInstalled=false
    @Published var checkingLanguage=false
    let storage: URL
    var selectedIndex: Int? { documents.firstIndex { $0.id == selected } }
    var current: Transcript? { selectedIndex.map { documents[$0] } }
    var totalWords: Int { current.map { TextExport.render($0, kind: "txt").split(whereSeparator: { $0.isWhitespace }).count } ?? 0 }
    init(storageOverride: URL? = nil) {
        storage = storageOverride ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Franco Transcribe", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
            let history = storage.appendingPathComponent("transcripciones.json")
            if FileManager.default.fileExists(atPath: history.path) {
                documents = try JSONDecoder().decode([Transcript].self, from: Data(contentsOf: history))
                for i in documents.indices where !documents[i].complete && documents[i].state != "Pendiente" { documents[i].state = "Interrumpido · puedes volver a transcribir" }
                selected = documents.first?.id
            }
        } catch { self.error = "No se pudo cargar el historial local: \(error.localizedDescription)" }
    }
    // SwiftUI may retain a binding after its row was deleted or reordered.
    // Resolve identity for every access; never retain an array index in an editor.
    func textBinding(for document:Transcript)->Binding<String> {
        Binding(get:{[weak self] in
            let current=self?.documents.first(where:{$0.id==document.id}) ?? document
            return TextExport.render(current,kind:"txt")
        },set:{[weak self] value in
            guard let self,let i=self.documents.firstIndex(where:{$0.id==document.id}) else{return}
            self.documents[i].fullTextOverride=value
        })
    }
    func segmentBinding(documentID:UUID,snapshot:Segment)->Binding<Segment> {
        Binding(get:{[weak self] in
            self?.documents.first(where:{$0.id==documentID})?.segments.first(where:{$0.id==snapshot.id}) ?? snapshot
        },set:{[weak self] value in
            guard let self,let i=self.documents.firstIndex(where:{$0.id==documentID}),let j=self.documents[i].segments.firstIndex(where:{$0.id==snapshot.id}) else{return}
            self.documents[i].segments[j]=value
        })
    }
    func persist() {
        do { try JSONEncoder().encode(documents).write(to: storage.appendingPathComponent("transcripciones.json"), options: .atomic) }
        catch { self.error = "No se pudo guardar el historial: \(error.localizedDescription). Exporta el texto antes de cerrar." }
    }
    func checkEngine() async {
        let check=UUID();languageCheckID=check;let requested=localeID
        checkingLanguage=true;chosenLocale=nil;languageInstalled=false
        defer{if languageCheckID==check{checkingLanguage=false}}
        guard SpeechTranscriber.isAvailable else {engineStatus="El reconocimiento local no está disponible en este Mac.";return}
        let available=await SpeechTranscriber.supportedLocales.sorted{$0.identifier<$1.identifier}
        let matched=await SpeechTranscriber.supportedLocale(equivalentTo:Locale(identifier:requested))
        guard languageCheckID==check,localeID==requested else{return}
        locales=available;chosenLocale=matched
        guard let matched else{engineStatus="Este idioma no está disponible en el motor local.";return}
        let state=await AssetInventory.status(forModules:[SpeechTranscriber(locale:matched,preset:.transcription)])
        guard languageCheckID==check,localeID==requested else{return}
        languageInstalled=state == .installed
        engineStatus="Modelo \(matched.identifier) · " + (languageInstalled ? "listo en tu Mac" : "requiere descargar el idioma una vez")
    }
    func observeDownload(_ value:Progress) {
        downloadProgress=value
        downloadObservation=value.observe(\.fractionCompleted,options:[.initial,.new]){[weak self] value,_ in
            let fraction=value.fractionCompleted
            Task{@MainActor in self?.progress=fraction}
        }
    }
    func prepareLanguage() {
        guard !busy,!checkingLanguage else{return}
        busy=true
        task=Task {
            do {
                await checkEngine();try Task.checkCancellation()
                guard let locale=chosenLocale else{throw TranscribeError.message("El idioma elegido no está disponible para transcripción local.")}
                let module=SpeechTranscriber(locale:locale,preset:.transcription)
                _ = try await AssetInventory.reserve(locale:locale)
                if let installation=try await AssetInventory.assetInstallationRequest(supporting:[module]) {
                    status="Descargando el modelo de idioma. Tus grabaciones no se envían.";observeDownload(installation.progress)
                    try await installation.downloadAndInstall()
                }
                try Task.checkCancellation();await checkEngine()
                status=languageInstalled ? "Idioma listo. Ya puedes transcribir sin conexión." : "El idioma aún no está listo. Intenta descargarlo de nuevo."
            }catch{status=Task.isCancelled ? "Descarga cancelada." : "No se pudo preparar el idioma.";if !Task.isCancelled{self.error=error.localizedDescription}}
            downloadProgress=nil;downloadObservation=nil;busy=false;task=nil
        }
    }
    func pick() {
        let p = NSOpenPanel(); p.allowsMultipleSelection = true; p.canChooseDirectories = true
        p.allowedContentTypes = [.audio, .movie, .folder, UTType(filenameExtension:"opus") ?? .data, UTType(filenameExtension:"ogg") ?? .data]; p.prompt = L("Agregar a la cola")
        p.message = L("Selecciona varios archivos con ⌘ o Mayúsculas. También puedes elegir carpetas completas.")
        if p.runModal() == .OK { add(p.urls) }
    }
    func add(_ urls: [URL]) {
        guard !importing else { return }; importing = true
        Task {
            let found = await Task.detached { BatchFiles.collect(urls) }.value
            var known=Set(documents.map{URL(fileURLWithPath:$0.source).resolvingSymlinksInPath().standardizedFileURL.path}); var added=0
            for url in found.files where known.insert(url.path).inserted {
                var doc=Transcript(source:url.path,name:url.lastPathComponent)
                if processingQueue { doc.state="En cola";queue.append(doc.id);batchTotal += 1 }
                documents.append(doc);added += 1
                if !busy {selected=doc.id}
            }
            importing=false;persist()
            if !busy {status="\(added) archivos agregados. Selecciona Transcribir pendientes para procesarlos todos."}
            if found.omitted>0 || found.limitReached {error="Se agregaron \(added) archivos compatibles. Se omitieron \(found.omitted) elementos no compatibles, enlaces o carpetas sin acceso.\(found.limitReached ? " El límite por carga es 10.000 archivos; agrega el resto por separado." : "")"}
        }
    }
    func begin(all: Bool = false) {
        guard !busy,!checkingLanguage else { return }
        let ids: [UUID] = all ? documents.filter { !$0.complete }.map(\.id) : selected.map { [$0] } ?? []
        guard !ids.isEmpty else { return }
        busy = true; processingQueue=true; queue=ids; batchTotal=ids.count;batchFinished=0; progress = 0; stopPlayback()
        for i in documents.indices where ids.contains(documents[i].id) {documents[i].state="En cola"}
        UserDefaults.standard.set(vocabulary, forKey: "vocabulary"); UserDefaults.standard.set(localeID, forKey: "locale")
        task = Task {
            while !queue.isEmpty || importing {
                if Task.isCancelled { break }
                if queue.isEmpty {try? await Task.sleep(for:.milliseconds(100));continue}
                let id=queue.removeFirst(); activeID=id; selected = id
                do { try await transcribe(id) }
                catch {
                    let cancelled = Task.isCancelled || error is CancellationError
                    let detail = cancelled ? "Cancelado · se conserva el texto parcial" : "Error: \(error.localizedDescription)"
                    if let i = documents.firstIndex(where: { $0.id == id }) { documents[i].state = detail }
                    status = detail
                    persist()
                }
                batchFinished += 1
            }
            let cancelled=Task.isCancelled
            for i in documents.indices where queue.contains(documents[i].id) {documents[i].state="Pendiente"}
            queue=[];processingQueue=false;activeID=nil
            if !cancelled {status="Lote terminado: \(batchFinished) archivos procesados. Revisa el estado de cada grabación."}
            busy = false; downloadProgress = nil; downloadObservation=nil; analyzer = nil; task = nil;persist()
        }
    }
    func transcribe(_ id: UUID) async throws {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let source = URL(fileURLWithPath: documents[index].source)
        guard FileManager.default.isReadableFile(atPath: source.path) else { throw TranscribeError.message("No puedo leer el archivo original. Vuelve a conectarlo o agrégalo desde su nueva ubicación.") }
        status = "Preparando el reconocimiento local…"
        await checkEngine()
        try Task.checkCancellation()
        guard let locale = chosenLocale else { throw TranscribeError.message("El idioma elegido no está disponible para transcripción local.") }
        let transcriber = SpeechTranscriber(locale: locale, transcriptionOptions: [], reportingOptions: [.alternativeTranscriptions], attributeOptions: [.audioTimeRange, .transcriptionConfidence])
        _ = try await AssetInventory.reserve(locale: locale)
        if let installation = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            status = "Descargando el modelo de idioma. Tus grabaciones no se envían."
            observeDownload(installation.progress)
            try await installation.downloadAndInstall()
            downloadProgress = nil; downloadObservation=nil
        }
        try Task.checkCancellation()
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("FrancoAudio-" + UUID().uuidString + ".caf")
        defer { try? FileManager.default.removeItem(at: temporary) }
        status = "Extrayendo el audio de \(source.lastPathComponent)…"
        documents[index].state = "Preparando audio"; persist()
        let converter = Task.detached { try await AudioPrep.convert(source, into: temporary) { fraction in
            await MainActor.run { self.progress = fraction * 0.15 }
        } }
        let prepared = try await withTaskCancellationHandler { try await converter.value } onCancel: { converter.cancel() }
        try Task.checkCancellation()
        documents[index].duration = prepared.duration
        documents[index].locale = locale.identifier
        // Keep the previous transcript in a local backup before deliberately replacing it.
        if !documents[index].segments.isEmpty {
            let backup = storage.appendingPathComponent("revision-\(id.uuidString)-\(UUID().uuidString).json")
            try JSONEncoder().encode(documents[index]).write(to: backup, options: .atomic)
        }
        documents[index].segments = []; documents[index].fullTextOverride = nil; documents[index].whisperSegments=nil;documents[index].comparison=nil;documents[index].voiceIntervals=nil;documents[index].advancedStatus=nil; documents[index].complete = false; documents[index].state = "Transcribiendo"
        status = "Transcribiendo en tu Mac · \(source.lastPathComponent)" + (prepared.multipleTracks ? " · primera pista de audio" : "")
        let engine = SpeechAnalyzer(modules: [transcriber], options: .init(priority: .userInitiated, modelRetention: .whileInUse))
        analyzer = engine
        let context = AnalysisContext()
        context.contextualStrings[.general] = terms
        try await engine.setContext(context)
        let collector = Task { @MainActor in
            for try await result in transcriber.results {
                try Task.checkCancellation()
                guard result.isFinal else { continue }
                let text = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                let confidences = result.text.runs.compactMap { $0.transcriptionConfidence }
                let conf = confidences.isEmpty ? nil : confidences.min()
                let start = result.range.start.seconds + prepared.offset
                let end = CMTimeRangeGetEnd(result.range).seconds + prepared.offset
                guard start.isFinite, end.isFinite else { continue }
                var segment = Segment(start: max(0, start), end: max(start + 0.05, end), text: NumberFormatting.format(text,language:locale.identifier), original: text, confidence: conf, alternatives: result.alternatives.prefix(3).map { String($0.characters).trimmingCharacters(in: .whitespacesAndNewlines) }.filter { $0 != text })
                segment.wordTimings = result.text.runs.compactMap { run in
                    guard let r=run.audioTimeRange,r.start.seconds.isFinite,CMTimeRangeGetEnd(r).seconds.isFinite else{return nil}
                    return TimedToken(text:String(result.text[run.range].characters),start:r.start.seconds+prepared.offset,end:CMTimeRangeGetEnd(r).seconds+prepared.offset)
                }
                if let timing=segment.wordTimings {segment.wordTimings=NumberFormatting.tokens(timing,language:locale.identifier)}
                if let i = self.documents.firstIndex(where: { $0.id == id }) {
                    self.documents[i].segments.append(segment)
                    self.progress = min(0.99, 0.15 + 0.85 * max(0, end) / prepared.duration)
                    self.persist()
                }
            }
        }
        do {
            let audio = try AVAudioFile(forReading: temporary)
            try await withTaskCancellationHandler {
                if let last = try await engine.analyzeSequence(from: audio) { try await engine.finalizeAndFinish(through: last) }
                else { await engine.cancelAndFinishNow() }
                try await collector.value
            } onCancel: { Task { await engine.cancelAndFinishNow() }; collector.cancel() }
            try Task.checkCancellation()
        } catch {
            await engine.cancelAndFinishNow(); collector.cancel(); _ = await collector.result; throw error
        }
        documents[index].complete = true
        if compareEnabled && !documents[index].segments.isEmpty {
            do { try await analyzeAdvanced(id,prepared:prepared) }
            catch {
                if Task.isCancelled {throw error}
                documents[index].advancedStatus="Análisis adicional pendiente: \(error.localizedDescription)"
            }
        }
        documents[index].state = documents[index].segments.isEmpty ? "No se detectó voz reconocible" : "Transcripción terminada"
        progress = 1; status = documents[index].state + ". Revisa nombres, cifras y fragmentos señalados."
        analyzer = nil; persist(); await checkEngine()
    }
    func cancel() { status = "Cancelando…"; downloadProgress?.cancel(); task?.cancel(); if let analyzer { Task { await analyzer.cancelAndFinishNow() } } }
    func export(_ kind: String) {
        guard let doc = current, !doc.segments.isEmpty else { return }
        let p = NSSavePanel(); p.nameFieldStringValue = URL(fileURLWithPath: doc.name).deletingPathExtension().lastPathComponent + "." + kind
        p.allowedContentTypes = [UTType(filenameExtension: kind) ?? .plainText]
        p.prompt = L("Guardar transcripción")
        if p.runModal() == .OK, let url = p.url {
            do { try TextExport.render(doc, kind: kind).write(to: url, atomically: true, encoding: .utf8); status = "Guardado: \(url.lastPathComponent)" }
            catch { self.error = error.localizedDescription }
        }
    }
    func copyText() { guard let doc = current else { return }; NSPasteboard.general.clearContents(); NSPasteboard.general.setString(TextExport.render(doc, kind: "txt"), forType: .string); status = "Transcripción completa copiada. Lista para pegar de una vez." }
    func stopPlayback() { playbackRequest=UUID();player?.pause(); isPlaying = false;playbackEnd=nil }
    func play(at seconds: Double? = nil, until end:Double? = nil) {
        guard let source = current?.source else { return }
        guard FileManager.default.isReadableFile(atPath:source) else {error="No encuentro el audio original. Conecta el disco o usa Vincular original para elegirlo en su nueva ubicación.";return}
        stopPlayback()
        let request=playbackRequest
        Task {
          do {
            let playable = try await OpusAudio.shared.playable(URL(fileURLWithPath: source))
            guard self.current?.source == source, self.playbackRequest == request else { return }
        if loadedSource != source {
            playbackTime=0
            if let observation { player?.removeTimeObserver(observation) }
            player = AVPlayer(url: playable); loadedSource = source
            observation = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
                MainActor.assumeIsolated {
                    guard self?.loadedSource==source else{return}
                    self?.playbackTime = time.seconds.isFinite ? time.seconds : 0; self?.isPlaying = (self?.player?.rate ?? 0) > 0
                    if let end=self?.playbackEnd,time.seconds>=end {self?.stopPlayback()}
                }
            }
        }
        if let seconds {
            player?.seek(to: CMTime(seconds: max(0, seconds), preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
                Task { @MainActor in
                    guard finished,let self,self.current?.source==source,self.playbackRequest==request else{return}
                    self.playbackEnd=end;self.player?.playImmediately(atRate:self.playbackRate);self.isPlaying=true
                }
            }
        } else {playbackEnd=end;player?.playImmediately(atRate:playbackRate);isPlaying=true}
          } catch {
            if self.playbackRequest == request { self.error = error.localizedDescription; self.isPlaying = false }
          }
        }
    }
    func relinkOriginal() {
        guard !busy,let i=selectedIndex else{return}
        let panel=NSOpenPanel();panel.allowedContentTypes=[.audio,.movie,UTType(filenameExtension:"opus") ?? .data,UTType(filenameExtension:"ogg") ?? .data];panel.allowsMultipleSelection=false
        panel.message=L("Elige el mismo audio o video en su nueva ubicación. Los tiempos guardados corresponden a esa grabación.");panel.prompt=L("Vincular original")
        if panel.runModal() == .OK,let url=panel.url {
            stopPlayback();documents[i].source=url.path;persist();status="Original vinculado. Tu texto y tus cuñas se conservan."
        }
    }
    func removeSelected() { guard !busy, let selected else { return }; stopPlayback(); self.selected=nil; documents.removeAll { $0.id == selected }; self.selected = documents.last?.id; persist() }
}

struct TranscribeView: View {
    @StateObject var model = TranscriptionModel()
    @State var targeted = false
    @State var onlyReview = false
    @State var transcriptView = "completo"
    @State var showRemove = false
    @State var showDictionary = false
    @State var showTutorial = false
    @AppStorage("guidedTour102Release") private var guidedTourCompleted = false
    @State var selection = NSRange(location: 0, length: 0)
    @State var quoteSpeaker = ""
    @State var followAudio = true
    @AppStorage("uiLanguage") var uiLanguage = AppLanguage.system
    let accent = Color(red: 0.24, green: 0.28, blue: 0.66)
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(nsImage: NSImage(named: "TranscribeIcon") ?? NSImage(systemSymbolName: "waveform", accessibilityDescription: "Franco Transcribe")!)
                    .resizable().scaledToFit().frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 4) { Text(L("Vocalia")).font(.system(size: 26, weight: .bold, design: .rounded)); Text(L("De la voz al texto. Dentro de tu Mac.")).foregroundStyle(.secondary) }
                Spacer()
                Button(T("How to use Vocalia")) { showTutorial = true }
                Label(L("100 % local"), systemImage: "lock.shield").foregroundStyle(accent).font(.system(size: 13, weight: .semibold))
            }.padding(22)
            Divider()
            HStack(spacing: 0) {
                sidebar.frame(width: 245)
                Divider()
                VStack(spacing: 0) {
                    settings.padding(18)
                    Divider()
                    if let index = model.selectedIndex {
                        editor(index).id("\(model.documents[index].id)-\(uiLanguage)").frame(maxHeight: .infinity)
                    } else {
                        VStack(spacing: 18) {
                            Image(systemName: "waveform").font(.system(size: 55, weight: .light)).foregroundStyle(accent)
                            Text(L("Tus grabaciones, listas para leer.")).font(.system(size: 22, weight: .semibold, design: .rounded))
                            Text(L("Arrastra audios o videos. Obtén texto editable, marcas de tiempo y subtítulos.")).multilineTextAlignment(.center).foregroundStyle(.secondary).frame(maxWidth: 410)
                            Button(L("Elegir archivos…")) { model.pick() }.buttonStyle(.borderedProminent).tint(accent).controlSize(.large)
                            Text(L("MP3 · MP4 · MOV · M4A · WAV · AIFF · FLAC · OPUS")).font(.system(size: 11)).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }.tourTarget("editor")
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                if model.busy {
                    if let p = model.downloadProgress { ProgressView(value: p.fractionCompleted).tint(accent) }
                    else { ProgressView(value: model.progress).tint(accent) }
                }
                HStack {
                    VStack(alignment: .leading, spacing: 4) { Text(L(model.status)).font(.system(size: 12, weight: .medium)).lineLimit(2); Text(L(model.engineStatus)).font(.system(size: 10)).foregroundStyle(.secondary) }
                    Spacer()
                    if model.processingQueue { Text(L("Archivo \(model.batchFinished+1) de \(model.batchTotal)")).font(.system(size:11)).foregroundStyle(.secondary) }
                    if model.busy { Button(L("Cancelar")) { model.cancel() } }
                    else { Button { model.begin() } label: { Label(model.current?.complete == true ? L("Volver a transcribir") : L("Transcribir"), systemImage: "waveform") }.buttonStyle(.borderedProminent).tint(accent).controlSize(.large).disabled(model.current == nil) }
                }
            }.padding(16).tourTarget("status")
        }
        .disabled(showTutorial)
        .allowsHitTesting(!showTutorial)
        .overlayPreferenceValue(TourAnchors.self) { anchors in
            if showTutorial { VocaliaCoachMarks(anchors: anchors, language: uiLanguage) { showTutorial = false; guidedTourCompleted = true } }
        }
        .onAppear { if !guidedTourCompleted { showTutorial = true } }
        .onChange(of: showTutorial, initial: true) {
            if showTutorial { NSApp.keyWindow?.makeFirstResponder(nil) }
        }
        .frame(minWidth: 1100, minHeight: 800).background(Color(red: 0.975, green: 0.975, blue: 0.99)).preferredColorScheme(.light)
        .overlay { if targeted { RoundedRectangle(cornerRadius: 15).stroke(accent, lineWidth: 4).padding(5).allowsHitTesting(false) } }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $targeted) { providers in
            guard !model.importing else { return false }
            Task { @MainActor in
                var urls: [URL] = []
                for p in providers {
                    let u: URL? = await withCheckedContinuation { continuation in
                        p.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                            if let d = item as? Data { continuation.resume(returning: URL(dataRepresentation: d, relativeTo: nil)) }
                            else { continuation.resume(returning: item as? URL) }
                        }
                    }
                    if let u { urls.append(u) }
                }
                model.add(urls)
            }
            return true
        }
        .environment(\.locale,Locale(identifier:uiLanguage))
        .task { UserDefaults.standard.set(uiLanguage,forKey:"uiLanguage");await model.checkEngine(); await model.refreshAdvancedStatus() }
        .onChange(of: model.selected) { model.stopPlayback();selection=NSRange(location:0,length:0);quoteSpeaker="" }
        .onChange(of: model.localeID) { UserDefaults.standard.set(model.localeID,forKey:"locale");Task { await model.checkEngine() } }
        .onChange(of: model.documents) { if !model.busy { model.persist() } }
        .onChange(of: model.compareEnabled) { model.saveOptions() }
        .onChange(of: model.voicesEnabled) { model.saveOptions() }
        .sheet(isPresented: $showDictionary) { DictionaryPane(model:model) }
        .alert("Vocalia", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) { Button(L("Entendido")) { model.error = nil } } message: { Text(L(model.error ?? "")) }
        .confirmationDialog(L("¿Quitar esta transcripción del historial? El audio original se conserva."), isPresented: $showRemove) { Button(L("Quitar del historial"), role: .destructive) { model.removeSelected() } }
    }
    var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text(L("GRABACIONES · \(model.documents.count)")).font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary); Spacer() }
            Button { model.pick() } label: { Label(model.importing ? L("Buscando archivos…") : L("Agregar archivos o carpetas…"), systemImage:"plus") }.disabled(model.importing).controlSize(.large).tourTarget("add")
            ScrollView {
                VStack(spacing: 7) {
                    ForEach(model.documents) { doc in
                        Button { model.selected = doc.id } label: {
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: doc.complete ? "checkmark.circle" : "waveform").foregroundStyle(accent)
                                VStack(alignment: .leading, spacing: 5) { Text(doc.name).font(.system(size: 12, weight: .semibold)).lineLimit(2); Text(L(doc.state)).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(2) }
                                Spacer(minLength: 0)
                            }.padding(11).frame(maxWidth: .infinity, alignment: .leading).background(model.selected == doc.id ? accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 10))
                        }.buttonStyle(.plain)
                    }
                }
            }
            Button(L("Transcribir pendientes")) { model.begin(all: true) }.disabled(model.busy || !model.documents.contains { !$0.complete }).tourTarget("run")
            Button(L("Exportar todos los TXT")) { model.exportBatch() }.disabled(model.busy || !model.documents.contains { !$0.segments.isEmpty })
            Button(L("Quitar del historial…")) { showRemove = true }.buttonStyle(.link).disabled(model.busy || model.current == nil).font(.system(size: 11))
            Text(L("Puedes agregar muchos archivos o carpetas de una vez, incluso mientras se procesa la cola.\nLos originales se conservan.")).font(.system(size: 10)).foregroundStyle(.secondary)
        }.padding(16)
    }
    var settings: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L("Idioma del audio")).font(.system(size: 12, weight: .semibold))
                Picker(L("Idioma del audio"), selection: $model.localeID) {
                    Text(Locale(identifier:uiLanguage).localizedString(forIdentifier:model.localeID) ?? model.localeID).tag(model.localeID)
                    ForEach(model.locales.map{$0.identifier.replacingOccurrences(of:"_",with:"-")}.filter{$0 != model.localeID},id:\.self){id in
                        Text(Locale(identifier:uiLanguage).localizedString(forIdentifier:id) ?? id).tag(id)
                    }
                }.labelsHidden().frame(width:180).disabled(model.busy).tourTarget("audio")
                Button(model.languageInstalled ? L("Idioma listo") : L("Descargar idioma")){model.prepareLanguage()}.disabled(model.busy || model.checkingLanguage || model.languageInstalled).tourTarget("prepare")
                Picker(T("Change language"),selection:$uiLanguage){ForEach(AppLanguage.options,id:\.code){option in Text(option.name).tag(option.code)}}.frame(width:185).disabled(model.busy).tourTarget("interface")
                Spacer()
                Button(L("Diccionario (\(model.dictionary.count))")) {showDictionary=true}.disabled(model.busy)
            }
            TextField(L("Nombres y siglas: Contraloría, COMPIN, Javiera Rodríguez…"), text: $model.vocabulary).textFieldStyle(.roundedBorder).disabled(model.busy)
            Text(L("Separa términos con comas. Ayudan al reconocimiento; revisa nombres y cifras al terminar.")).font(.system(size: 10)).foregroundStyle(.secondary)
            HStack(spacing:14) {
                Toggle(L("Comparar con Whisper"),isOn:$model.compareEnabled).toggleStyle(.checkbox)
                Toggle(T("Speaker analysis: manual"),isOn:$model.voicesEnabled).help(T("Speaker separation only runs when you select it and click Analyze speakers / compare. It never runs after transcription.")).toggleStyle(.checkbox)
                Spacer()
                Button(L("Preparar modelos")) {model.prepareAdvancedModels()}
            }.font(.system(size:11)).disabled(model.busy)
            Text(L(model.advancedModelStatus)).font(.system(size:10)).foregroundStyle(.secondary)
        }
    }
    func editor(_ index: Int) -> some View {
        let doc=model.documents[index]
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) { Text(doc.name).font(.headline).lineLimit(1); Text(L("\(model.totalWords) palabras · \(TextExport.clock(doc.duration))")).font(.system(size: 11)).foregroundStyle(.secondary) }
                Spacer()
                Button { model.isPlaying ? model.stopPlayback() : model.play() } label: { Image(systemName: model.isPlaying ? "pause.fill" : "play.fill") }.help(L("Escuchar el original"))
                Text(TextExport.clock(model.playbackTime)).font(.system(size: 11, design: .monospaced))
                Picker(L("Velocidad"), selection: $model.playbackRate) { Text(L("0,75×")).tag(Float(0.75)); Text(L("1×")).tag(Float(1)); Text(L("1,25×")).tag(Float(1.25)) }.labelsHidden().frame(width: 75).onChange(of: model.playbackRate) { if model.isPlaying { model.player?.rate = model.playbackRate } }
            }.padding(16)
            HStack {
                Picker(L("Vista de la transcripción"), selection: $transcriptView) {
                    Text(L("Texto completo")).tag("completo")
                    Text(L("Revisar")).tag("revision")
                    Text(L("Cuñas")).tag("cunas")
                    Text(L("Comparación")).tag("comparacion")
                    Text(L("Voces")).tag("voces")
                }.pickerStyle(.segmented)
            }.padding(.horizontal,16).padding(.bottom,10)
            HStack {
                if model.current?.complete == true {Button(L("Analizar voces / comparar")) {model.runAdvanced()}.disabled(model.busy || (!model.compareEnabled && !model.voicesEnabled))}
                Spacer()
                Button(L("Copiar todo el texto")) { model.copyText() }.buttonStyle(.borderedProminent).tint(accent).disabled(model.current?.segments.isEmpty != false)
                Menu(L("Exportar")) { Button(L("Vincular original…")){model.relinkOriginal()}.disabled(model.busy); Divider(); Button(L("Texto (.txt)")) { model.export("txt") }; Button(L("Subtítulos (.srt)")) { model.export("srt") }; Button(L("WebVTT (.vtt)")) { model.export("vtt") } }.disabled(model.current?.segments.isEmpty != false).frame(width: 105)
            }.padding(.horizontal, 16).padding(.bottom, 12)
            Divider()
            if transcriptView == "cunas" {
                QuotesPane(model:model,document:doc)
            } else if transcriptView == "comparacion" {
                ComparisonPane(model:model,document:doc)
            } else if transcriptView == "voces" {
                VoicesPane(model:model,document:doc)
            } else if transcriptView == "completo" {
                VStack(alignment: .leading, spacing: 12) {
                    if doc.segments.isEmpty {
                        Text(model.busy ? L("La transcripción aparecerá aquí como un solo texto.") : L("Pulsa Transcribir para obtener el texto completo."))
                            .foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        HStack {
                            Text(doc.complete ? L("TRANSCRIPCIÓN COMPLETA") : L("TEXTO PARCIAL · transcripción sin terminar"))
                                .font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                            Spacer()
                            Toggle(L("Seguir audio"),isOn:$followAudio).toggleStyle(.checkbox).font(.system(size:11))
                            Button(L("Guardar TXT")) { model.export("txt") }
                        }
                        SelectableTranscript(text: model.textBinding(for:doc),selection:$selection,editable:!model.busy && !showTutorial,document:doc,playbackTime:model.loadedSource==doc.source ? model.playbackTime : nil,playing:model.isPlaying,followAudio:followAudio)
                        .font(.system(size: 16)).lineSpacing(7).scrollContentBackground(.hidden)
                        .padding(16).background(.white, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.10)))
                        .accessibilityLabel(L("Transcripción completa editable")).disabled(model.busy)
                        Text(L("El amarillo sigue la voz. Puedes pausar, editar o seleccionar una cuña. Copiar todo incluye el texto entero."))
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                        HStack {
                            Button(L("Escuchar selección")) {if let match=model.quoteMatch(range:selection){model.play(at:max(0,match.start-0.25),until:match.end+0.15)}}
                            TextField(L("Nombre del hablante"),text:$quoteSpeaker).textFieldStyle(.roundedBorder).frame(maxWidth:190)
                            Button(L("Guardar cuña")) {model.saveQuote(range:selection,speaker:quoteSpeaker)}
                            Spacer()
                        }.disabled(model.busy || model.quoteMatch(range:selection) == nil)
                        if selection.length>0,model.quoteMatch(range:selection)==nil {Text(L("No puedo ubicar esa selección con certeza. Elige una frase que coincida con el reconocimiento o revísala con audio.")).font(.system(size:10)).foregroundStyle(.orange)}
                        else if let match=model.quoteMatch(range:selection) {Text(L("Selección: \(TextExport.clock(match.start))–\(TextExport.clock(match.end)) · tiempos del fragmento de origen")).font(.system(size:10)).foregroundStyle(.secondary)}
                        if doc.fullTextOverride != nil {
                            Text(L("Tus cambios en este texto se guardan en el TXT. Los subtítulos conservan el texto de Revisar con audio."))
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    }
                }.padding(18).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
            Toggle(L("Solo por revisar"), isOn: $onlyReview).toggleStyle(.checkbox).font(.system(size: 11)).padding(12)
            if doc.fullTextOverride != nil {
                Text(L("Tienes una versión editada en Texto completo. Los cambios de estos fragmentos se aplican a los subtítulos; no reemplazan tu versión editada."))
                    .font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 16)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if doc.segments.isEmpty {
                        VStack(spacing: 12) { Image(systemName: "text.alignleft").font(.largeTitle).foregroundStyle(.secondary); Text(model.busy ? L("El texto aparecerá aquí conforme se reconozca.") : L("Pulsa Transcribir para convertir esta grabación en texto.")).foregroundStyle(.secondary).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(.vertical, 65)
                    }
                    ForEach(doc.segments) { segment in
                        let segmentBinding=model.segmentBinding(documentID:doc.id,snapshot:segment)
                        if !onlyReview || !segment.reviewed {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Button { model.play(at: max(0, segment.start - 0.4)) } label: { Label(TextExport.clock(segment.start), systemImage: "play.circle") }.buttonStyle(.link).font(.system(size: 11, design: .monospaced))
                                    if segment.uncertain { Label(L("Escuchar y revisar"), systemImage: "ear.badge.exclamationmark").font(.system(size: 10)).foregroundStyle(.orange) }
                                    Spacer()
                                    TextField(L("Hablante (opcional)"), text: segmentBinding.speaker).textFieldStyle(.roundedBorder).frame(width: 140).font(.system(size: 11))
                                    Toggle(L("Revisado"), isOn: segmentBinding.reviewed).toggleStyle(.checkbox).font(.system(size: 11))
                                }
                                TextEditor(text: segmentBinding.text).font(.system(size: 15)).scrollContentBackground(.hidden).frame(minHeight: 62, maxHeight: 180)
                                if segment.text != segment.original || !segment.alternatives.isEmpty {
                                    HStack {
                                        if !segment.alternatives.isEmpty { Menu(L("Otras lecturas")) { ForEach(segment.alternatives, id: \.self) { alt in Button(alt) { segmentBinding.wrappedValue.text = alt; segmentBinding.wrappedValue.reviewed = false } } }.frame(width: 125) }
                                        if segment.text != segment.original { Button(L("Restaurar original")) { segmentBinding.wrappedValue.text = segment.original; segmentBinding.wrappedValue.reviewed = false }.font(.system(size: 10)).buttonStyle(.link) }
                                        Spacer()
                                    }
                                }
                            }.padding(13).background(.white, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(segment.uncertain ? .orange.opacity(0.4) : accent.opacity(0.09))).disabled(model.busy)
                        }
                    }
                }.padding(16)
            }
            Text(T("Review flags indicate low recognition confidence or figures to check against the audio. They are not accuracy scores.")).font(.system(size: 9)).foregroundStyle(.secondary).padding(12)
            }
        }
    }
}

final class TranscribeDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationWillTerminate(_ notification: Notification) { try? FileManager.default.removeItem(at: OpusAudio.temporaryRoot) }
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let icon = NSImage(named: "TranscribeIcon") { NSApp.applicationIconImage = icon }
        NSApp.setActivationPolicy(.regular); NSApp.activate(ignoringOtherApps: true)
    }
}
#if !QA && !ENGINE_QA
@main struct TranscribeApp: App {
    @NSApplicationDelegateAdaptor(TranscribeDelegate.self) var delegate
    init() {
        if let index = CommandLine.arguments.firstIndex(of: "--opus-self-test"), CommandLine.arguments.count > index + 2 {
            let source = CommandLine.arguments[index+1], output = CommandLine.arguments[index+2]
            Task { @MainActor in await OpusChecks.run(source: source, output: output) }
            RunLoop.main.run()
        }
        if CommandLine.arguments.contains("--self-test") { TranscribeTests.run(); AdvancedTests.run(); exit(0) } }
    var body: some Scene { WindowGroup("Vocalia") { if let config = Bundle.main.url(forResource: "opus-qa", withExtension: "json") { OpusValidationView(config: config) } else { VocaliaStartView() } }.defaultSize(width: 1100, height: 820).commands { CommandGroup(replacing: .newItem) {} } }
}
#endif
enum TranscribeTests {
    static func run() {
        var count = 0
        func check(_ b: Bool, _ label: String) { if !b { print("FAIL \(label)"); exit(1) }; count += 1; print("OK \(label)") }
        check(TextExport.time(3661.234) == "01:01:01,234", "Tiempos de más de una hora")
        check(TextExport.time(59.9996) == "00:01:00,000", "Redondeo de milisegundos")
        check(TextExport.time(-2) == "00:00:00,000", "Tiempos negativos")
        var doc = Transcript(source: "/prueba.mp4", name: "prueba.mp4")
        doc.segments = [Segment(start: 0, end: 2.5, text: "Hola, Chile.", original: "Hola, Chile.", confidence: 0.95), Segment(start: 3, end: 5, text: "Esta es una prueba.", original: "Esta es una prueba.", confidence: 0.6, speaker: "Ana")]
        let srt = TextExport.render(doc, kind: "srt")
        check(srt.contains("00:00:00,000 --> 00:00:02,500"), "Tiempos SRT")
        check(srt.contains("2\n00:00:03,000"), "Numeración de segmentos")
        check(srt.contains("Ana: Esta es una prueba."), "Etiqueta manual de hablante")
        check(TextExport.render(doc, kind: "vtt").hasPrefix("WEBVTT\n\n1\n00:00:00.000"), "Formato WebVTT")
        check(!TextExport.render(doc, kind: "txt").contains("-->"), "Texto limpio")
        var paragraph = doc
        paragraph.segments[1].speaker = ""
        check(TextExport.render(paragraph, kind: "txt") == "Hola, Chile. Esta es una prueba.\n", "Une fragmentos continuos en un párrafo")
        paragraph.segments[1].start = 10
        check(TextExport.render(paragraph, kind: "txt") == "Hola, Chile. Esta es una prueba.\n", "Pausas no fragmentan el texto completo")
        paragraph.fullTextOverride = "Mi cuña corregida, en un único texto."
        check(TextExport.render(paragraph, kind: "txt") == paragraph.fullTextOverride, "Copia y TXT incluyen la edición completa")
        check(TextExport.render(paragraph, kind: "srt").contains("Hola, Chile."), "Subtítulos conservan su texto con tiempos")
        do {
            var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(paragraph)) as! [String: Any]
            legacy.removeValue(forKey: "fullTextOverride")
            let restored = try JSONDecoder().decode(Transcript.self, from: JSONSerialization.data(withJSONObject: legacy))
            check(restored.fullTextOverride == nil && restored.segments.count == 2, "Historial anterior compatible")
            let edited = try JSONDecoder().decode(Transcript.self, from: JSONEncoder().encode(paragraph))
            check(edited.fullTextOverride == paragraph.fullTextOverride, "Edición completa persiste al reabrir")
        } catch { check(false, "Migración del historial") }
        check(doc.segments[1].uncertain && !doc.segments[0].uncertain, "Aviso de confianza")
        doc.segments[1].reviewed = true
        check(!doc.segments[1].uncertain, "Revisión humana")
        doc.segments[0].text = "Corrección manual"
        check(doc.segments[0].original == "Hola, Chile.", "Conserva texto original")
        do { let round = try JSONDecoder().decode(Transcript.self, from: JSONEncoder().encode(doc)); check(round == doc, "Historial conserva tiempos, edición y originales") } catch { check(false, "Historial") }
        print("\(count) pruebas correctas")
    }
}
