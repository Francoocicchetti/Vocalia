#if ENGINE_QA
import SwiftUI
import AVFoundation
struct ValidationConfig:Codable { var sources:[String];var output:String }
@main struct EngineValidationApp:App {var body:some Scene{WindowGroup("Verificación local de motores"){EngineValidationView()}}}
struct EngineValidationView:View {
 @State var status="Preparando validación…"
 @State var result=""
 var body:some View{
  VStack(alignment:.leading,spacing:16){Text("Verificación de motores locales").font(.title2);Text(status);Text(result).textSelection(.enabled)}.padding(28).frame(width:650,height:390)
  .task{
   do{
    let config=try JSONDecoder().decode(ValidationConfig.self,from:Data(contentsOf:Bundle.main.url(forResource:"qa",withExtension:"json")!))
    let root=URL(fileURLWithPath:config.output);try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
    func log(_ s:String){Task{@MainActor in status=s;try? s.write(to:root.appendingPathComponent("status.txt"),atomically:true,encoding:.utf8)}}
    try await LocalEngines.shared.prepare(compare:true,voices:true,update:{s,_ in log(s)})
    var blocks:[URL]=[]
    for (i,path) in config.sources.enumerated(){
     let url=root.appendingPathComponent("audio-\(i).caf")
     _ = try await AudioPrep.convert(URL(fileURLWithPath:path),into:url){_ in}
     blocks.append(url)
    }
    log("Comprobando Whisper con audio real…")
    let second=try await LocalEngines.shared.compare(audio:blocks[0],offset:0,language:"es",terms:[],update:{s,_ in log(s)})
    guard !second.isEmpty else{throw TranscribeError.message("Whisper no devolvió texto")}
    try JSONEncoder().encode(second).write(to:root.appendingPathComponent("whisper-result.json"))
    log("Comprobando separación de voces…")
    let intervals=try await LocalEngines.shared.voices(audio:blocks[0],offset:0,expected:nil,update:{s,_ in log(s)})
    guard !intervals.isEmpty else{throw TranscribeError.message("No se encontraron intervalos de voz")}
    try JSONEncoder().encode(intervals).write(to:root.appendingPathComponent("voice-result.json"))
    var summary="Whisper: \(second.count) fragmentos de texto. Voces: \(intervals.count) intervalos."
    if blocks.count>1{
     let merged=root.appendingPathComponent("dos-voces.caf")
     let format=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:16000,channels:1,interleaved:false)!
     do{
      let writer=try AVAudioFile(forWriting:merged,settings:format.settings,commonFormat:.pcmFormatFloat32,interleaved:false)
      for index in [0,1,0,1]{let file=try AVAudioFile(forReading:blocks[index]);let n=AVAudioFrameCount(min(file.length,16000*12));let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:n)!;try file.read(into:buffer,frameCount:n);try writer.write(from:buffer)}
     }
     let multiple=try await LocalEngines.shared.voices(audio:merged,offset:0,expected:nil,update:{s,_ in log(s)})
     try JSONEncoder().encode(multiple).write(to:root.appendingPathComponent("multiple-voices.json"))
     summary += " Dos clips alternados: \(Set(multiple.flatMap(\.ids)).count) voces estimadas."
    }
    result=summary;status="Verificación terminada"
    try summary.write(to:root.appendingPathComponent("SUCCESS.txt"),atomically:true,encoding:.utf8)
   }catch{result=error.localizedDescription;status="Error de validación";if let config=try? JSONDecoder().decode(ValidationConfig.self,from:Data(contentsOf:Bundle.main.url(forResource:"qa",withExtension:"json")!)){try? error.localizedDescription.write(to:URL(fileURLWithPath:config.output).appendingPathComponent("ERROR.txt"),atomically:true,encoding:.utf8)}}
  }
 }
}
#endif
