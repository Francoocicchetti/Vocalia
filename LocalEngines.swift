import Foundation
import AVFoundation
import WhisperKit
import SpeakerKit
import ArgmaxCore

struct VoiceInterval: Codable, Equatable, Sendable { var start: Double; var end: Double; var ids: [Int] }
actor LocalEngines {
    static let shared = LocalEngines()
    let root: URL
    private var whisper: WhisperKit?
    private var speakerKit: SpeakerKit?
    private var paths: [String:String] = [:]
    init(root: URL? = nil) {
        self.root = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Franco Transcribe/Models")
        if let data = try? Data(contentsOf: self.root.appendingPathComponent("locations.json")), let p = try? JSONDecoder().decode([String:String].self, from: data) { paths = p }
    }
    private func savePaths() throws { try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true); try JSONEncoder().encode(paths).write(to: root.appendingPathComponent("locations.json"), options: .atomic) }
    func readyDescription() -> String {
        let a = paths["whisper"].map { FileManager.default.fileExists(atPath:$0) } ?? false
        let b = paths["speakers"].map { FileManager.default.fileExists(atPath:$0) } ?? false
        return "Whisper: \(a ? "descargado" : "por descargar") · Voces: \(b ? "descargado" : "por descargar")"
    }
    func prepare(compare: Bool, voices: Bool, update: @escaping @Sendable (String,Double) -> Void) async throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        if compare && whisper == nil {
            var folder: URL
            if let saved = paths["whisper"], FileManager.default.fileExists(atPath:saved) { folder = URL(fileURLWithPath:saved) }
            else {
                update("Descargando Whisper para comparar dentro del Mac…",0)
                folder = try await WhisperKit.download(variant:"large-v3-v20240930_626MB",downloadBase:root.appendingPathComponent("Whisper"),progressCallback:{ p in update("Descargando Whisper: \(Int(p.fractionCompleted*100)) %",p.fractionCompleted) })
                paths["whisper"] = folder.path; try savePaths()
            }
            try Task.checkCancellation()
            update("Preparando Whisper para este Mac…",0.95)
            whisper = try await WhisperKit(WhisperKitConfig(modelFolder:folder.path,tokenizerFolder:root.appendingPathComponent("Tokenizer"),verbose:false,prewarm:true,load:true,download:false))
        }
        if voices && speakerKit == nil {
            let saved = paths["speakers"].flatMap { FileManager.default.fileExists(atPath:$0) ? $0 : nil }
            update(saved == nil ? "Descargando el modelo para separar voces…" : "Preparando la separación de voces…",0)
            let config = PyannoteConfig(downloadBase:root.appendingPathComponent("Speakers").path,modelFolder:saved,download:saved == nil,load:false,verbose:false,concurrentSegmenterWorkers:2,concurrentEmbedderWorkers:2)
            let kit = try await SpeakerKit(config)
            if let manager = kit.diarizer as? ModelManager, let folder = manager.modelPath ?? manager.modelFolder { paths["speakers"] = folder.path; try savePaths() }
            try Task.checkCancellation()
            update("Preparando los modelos de voces…",0.8)
            try await kit.ensureModelsLoaded()
            speakerKit = kit
        }
        try Task.checkCancellation()
        update("Modelos locales listos",1)
    }
    static func samples(_ url: URL) throws -> [Float] {
        let f = try AVAudioFile(forReading:url)
        guard f.processingFormat.sampleRate == 16000, f.processingFormat.channelCount == 1, f.length < 16000 * 7200 else { throw TranscribeError.message("La comparación y las voces admiten hasta 2 horas por archivo. Divide esta grabación para esas funciones; la transcripción de Apple admite archivos más largos.") }
        guard let b = AVAudioPCMBuffer(pcmFormat:f.processingFormat,frameCapacity:AVAudioFrameCount(f.length)) else { throw TranscribeError.message("No hay memoria suficiente para analizar el audio.") }
        try f.read(into:b)
        guard let data = b.floatChannelData?[0] else { throw TranscribeError.message("El audio local no tiene el formato esperado.") }
        return Array(UnsafeBufferPointer(start:data,count:Int(b.frameLength)))
    }
    func compare(audio:URL,offset:Double,language:String,terms:[String],update:@escaping @Sendable(String,Double)->Void) async throws -> [Segment] {
        try await prepare(compare:true,voices:false,update:update)
        guard let whisper else { throw TranscribeError.message("Whisper no está listo.") }
        let audioArray = try Self.samples(audio)
        let prompt = terms.isEmpty ? nil : whisper.tokenizer?.encode(text:terms.joined(separator:", ")).prefix(180).map { $0 }
        let options = DecodingOptions(language:language,temperature:0,temperatureFallbackCount:2,skipSpecialTokens:true,wordTimestamps:true,promptTokens:prompt,concurrentWorkerCount:1,chunkingStrategy:.vad)
        update("Comparando con Whisper en tu Mac…",0)
        let output = try await whisper.transcribe(audioArray:audioArray,decodeOptions:options,callback:{ _ in !Task.isCancelled })
        try Task.checkCancellation()
        return output.flatMap(\.segments).compactMap { s in
            let text = s.text.trimmingCharacters(in:.whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            var segment = Segment(start:Double(s.start)+offset,end:Double(s.end)+offset,text:NumberFormatting.format(text,language:language),original:text,confidence:nil)
            segment.wordTimings = s.words?.map { TimedToken(text:$0.word,start:Double($0.start)+offset,end:Double($0.end)+offset) }
            if let timing=segment.wordTimings {segment.wordTimings=NumberFormatting.tokens(timing,language:language)}
            return segment
        }
    }
    func voices(audio:URL,offset:Double,expected:Int?,update:@escaping @Sendable(String,Double)->Void) async throws -> [VoiceInterval] {
        try await prepare(compare:false,voices:true,update:update)
        guard let speakerKit else { throw TranscribeError.message("El modelo de voces no está listo.") }
        let audioArray = try Self.samples(audio)
        let result = try await speakerKit.diarize(audioArray:audioArray,options:PyannoteDiarizationOptions(numberOfSpeakers:expected),progressCallback:{ p in update("Separando voces: \(Int(p.fractionCompleted*100)) %",p.fractionCompleted) })
        try Task.checkCancellation()
        return result.segments.map { VoiceInterval(start:Double($0.startTime)+offset,end:Double($0.endTime)+offset,ids:$0.speaker.speakerIds) }.sorted { $0.start < $1.start }
    }
}
