import Foundation
import AVFoundation
import SwiftUI

// No network: the bundled decoder reads the original and writes a temporary PCM copy.
actor OpusAudio {
    static let shared = OpusAudio()
    static let temporaryRoot = FileManager.default.temporaryDirectory.appendingPathComponent("Vocalia-Opus-" + UUID().uuidString)
    private var copies: [String: URL] = [:]
    static func needsDecoding(_ url: URL) -> Bool { ["opus", "ogg"].contains(url.pathExtension.lowercased()) }
    func playable(_ source: URL) async throws -> URL {
        guard Self.needsDecoding(source) else { return source }
        let values = try source.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let key = source.path + ":\(values.fileSize ?? 0):\(values.contentModificationDate?.timeIntervalSince1970 ?? 0)"
        if let copy = copies[key], FileManager.default.fileExists(atPath: copy.path) { return copy }
        try FileManager.default.createDirectory(at: Self.temporaryRoot, withIntermediateDirectories: true)
        let target = Self.temporaryRoot.appendingPathComponent(UUID().uuidString + ".wav")
        guard let helper = Bundle.main.url(forAuxiliaryExecutable: "opusdecode") else {
            throw TranscribeError.message("Falta el decodificador OPUS. Descarga de nuevo la aplicación completa.")
        }
        let process = Process();process.executableURL = helper;process.arguments = [source.path, target.path]
        process.standardInput = FileHandle.nullDevice;process.standardOutput = FileHandle.nullDevice;process.standardError = FileHandle.nullDevice
        do {
            try Task.checkCancellation();try process.run()
            while process.isRunning { try await Task.sleep(for: .milliseconds(40)) }
            try Task.checkCancellation()
            guard process.terminationStatus == 0 else {
                throw TranscribeError.message("No se pudo leer el archivo OPUS. Comprueba que no esté dañado y dure menos de diez horas.")
            }
            copies[key] = target;return target
        } catch {
            if process.isRunning { process.terminate();process.waitUntilExit() }
            try? FileManager.default.removeItem(at: target)
            throw error
        }
    }
}

// Integration check uses an explicitly supplied fixture and isolated output directory.
enum OpusChecks {
    @MainActor static func run(source: String, output: String) async {
        let folder = URL(fileURLWithPath: output)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = URL(fileURLWithPath: source)
            guard BatchFiles.collect([url]).files.count == 1 else { throw TranscribeError.message("OPUS import rejected") }
            let playable = try await OpusAudio.shared.playable(url)
            let asset = AVURLAsset(url: playable)
            guard try await asset.load(.isPlayable) else { throw TranscribeError.message("Decoded audio cannot play") }
            let duration = try await asset.load(.duration).seconds
            let model = TranscriptionModel(storageOverride: folder)
            model.localeID = "en-US"
            let doc = Transcript(source: source, name: url.lastPathComponent)
            model.documents = [doc];model.selected = doc.id
            try await model.transcribe(doc.id)
            guard let result = model.documents.first, result.complete,
                  TextExport.render(result, kind: "txt").lowercased().contains("country"),
                  abs(result.duration-duration) < 0.1,
                  result.segments.allSatisfy({ $0.start >= 0 && $0.end <= duration + 0.5 }) else {
                throw TranscribeError.message("OPUS transcript or timing check failed")
            }
            try "PASS: OPUS import, local decoding, playable audio, native transcription and source-aligned timestamps".write(to: folder.appendingPathComponent("PASS.txt"), atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(at: OpusAudio.temporaryRoot)
            print("OPUS integration PASS");exit(0)
        } catch {
            try? error.localizedDescription.write(to: folder.appendingPathComponent("ERROR.txt"), atomically: true, encoding: .utf8)
            print(error);exit(1)
        }
    }
}

struct OpusValidationView: View {
    let config: URL
    var body: some View {
        Text("Checking OPUS import, playback and transcription…").padding(30)
            .task {
                guard let data = try? Data(contentsOf: config),
                      let paths = try? JSONDecoder().decode([String].self, from: data), paths.count == 2 else { return }
                await OpusChecks.run(source: paths[0], output: paths[1])
            }
    }
}
