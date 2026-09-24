import Foundation
import AVFoundation
import AppKit

struct AudioWordSpan { let range:NSRange; let start:Double; let end:Double }
enum AudioWordMap {
    static func spans(_ doc:Transcript, visible:String)->[AudioWordSpan] {
        let (original,segments)=TextAnalysis.layout(doc)
        var result:[AudioWordSpan]=[]
        for span in segments {
            let body=(original as NSString).substring(with:span.range) as NSString
            let base:Int
            if visible==original {base=span.range.location}
            else {let matches=(visible as NSString).ranges(of:body as String);guard matches.count==1 else{continue};base=matches[0].location}
            var cursor=0;var entries:[AudioWordSpan]=[];var valid=true
            for token in span.segment.wordTimings ?? [] {
                let word=token.text.trimmingCharacters(in:.whitespacesAndNewlines)
                if word.isEmpty {continue}
                let r=body.range(of:word,range:NSRange(location:cursor,length:body.length-cursor))
                guard r.location != NSNotFound,body.substring(with:NSRange(location:cursor,length:r.location-cursor)).trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,token.start.isFinite,token.end.isFinite,token.start>=0,token.end>token.start else{valid=false;break}
                entries.append(AudioWordSpan(range:NSRange(location:base+r.location,length:r.length),start:token.start,end:token.end));cursor=NSMaxRange(r)
            }
            if valid && body.substring(from:cursor).trimmingCharacters(in:.whitespacesAndNewlines).isEmpty {result += entries}
        }
        return result
    }
    static func word(_ index:Int,document:Transcript,visible:String)->AudioWordSpan? {spans(document,visible:visible).first{NSLocationInRange(index,$0.range)}}
    static func selection(_ range:NSRange,document:Transcript,visible:String)->(Double,Double)? {
        let ns=visible as NSString
        guard range.location>=0,range.location != NSNotFound,range.length>0,NSMaxRange(range)<=ns.length else{return nil}
        let entries=spans(document,visible:visible).filter{NSIntersectionRange(range,$0.range).length>0}
        guard let first=entries.first,let last=entries.last,last.end-first.start>=0.08 else{return nil}
        var cursor=range.location
        for entry in entries {
            guard ns.substring(with:NSRange(location:cursor,length:max(0,entry.range.location-cursor))).trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return nil}
            cursor=max(cursor,NSMaxRange(entry.range))
        }
        guard cursor>=NSMaxRange(range) || ns.substring(with:NSRange(location:cursor,length:NSMaxRange(range)-cursor)).trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return nil}
        return (first.start,last.end)
    }
}

final class PlaybackTextView:NSTextView {
    var onWordClick:((Int)->Void)?
    var clickToPlay=true
    override func mouseDown(with event:NSEvent) {
        let start=convert(event.locationInWindow,from:nil)
        super.mouseDown(with:event)
        guard clickToPlay,isEditable,event.clickCount==1,selectedRange().length==0,event.modifierFlags.intersection([.shift,.control,.option,.command]).isEmpty,let lm=layoutManager,let tc=textContainer else{return}
        let finish=convert(window?.mouseLocationOutsideOfEventStream ?? event.locationInWindow,from:nil)
        guard hypot(finish.x-start.x,finish.y-start.y)<4 else{return}
        let point=NSPoint(x:start.x-textContainerOrigin.x,y:start.y-textContainerOrigin.y)
        let glyph=lm.glyphIndex(for:point,in:tc)
        guard glyph<lm.numberOfGlyphs,lm.boundingRect(forGlyphRange:NSRange(location:glyph,length:1),in:tc).contains(point) else{return}
        onWordClick?(lm.characterIndexForGlyph(at:glyph))
    }
}

struct RumbleFilter {
    let alpha:Float=1/(1+2*Float.pi*70/16000)
    var x:Float=0;var y:Float=0
    mutating func sample(_ value:Float)throws->Float {
        guard value.isFinite else{throw TranscribeError.message("Invalid audio sample")}
        y=alpha*(y+value-x);x=value;return y
    }
    static func gain(_ peak:Float)->Float {peak>0.0001 ? min(2,0.95/peak) : 1}
}

enum AudioCleanup {
    static func create(_ source:URL,target:URL) async throws {
        guard source.standardizedFileURL != target.standardizedFileURL else{throw TranscribeError.message("Source must be preserved")}
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent("Vocalia-clean-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        defer{try? FileManager.default.removeItem(at:folder)}
        let duration=try await AVURLAsset(url:source).load(.duration).seconds
        guard duration.isFinite,duration>0,duration<7200 else{throw TranscribeError.message(T("Audio cleanup supports recordings shorter than two hours."))}
        let prepared=try await AudioPrep.convert(source,into:folder.appendingPathComponent("input.caf"),progress:{_ in})
        let filtered=folder.appendingPathComponent("filtered.caf"),output=folder.appendingPathComponent("output.wav")
        let format=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:16000,channels:1,interleaved:false)!
        var peak:Float=0
        do {
            let input=try AVAudioFile(forReading:prepared.url),writer=try AVAudioFile(forWriting:filtered,settings:format.settings)
            var filter=RumbleFilter()
            let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:8192)!
            var padding=Int64((prepared.offset*16000).rounded())
            while padding>0 {
                try Task.checkCancellation();buffer.frameLength=AVAudioFrameCount(min(padding,8192));memset(buffer.floatChannelData![0],0,Int(buffer.frameLength)*4);try writer.write(from:buffer);padding-=Int64(buffer.frameLength)
            }
            while input.framePosition<input.length {
                try Task.checkCancellation();try input.read(into:buffer)
                let data=buffer.floatChannelData![0]
                for i in 0..<Int(buffer.frameLength) {data[i]=try filter.sample(data[i]);peak=max(peak,abs(data[i]))}
                try writer.write(from:buffer)
            }
        }
        do {
            let input=try AVAudioFile(forReading:filtered),writer=try AVAudioFile(forWriting:output,settings:format.settings)
            let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:8192)!,gain=RumbleFilter.gain(peak)
            while input.framePosition<input.length {
                try Task.checkCancellation();try input.read(into:buffer)
                for i in 0..<Int(buffer.frameLength){buffer.floatChannelData![0][i] *= gain}
                try writer.write(from:buffer)
            }
        }
        try Task.checkCancellation()
        try FileManager.default.createDirectory(at:target.deletingLastPathComponent(),withIntermediateDirectories:true)
        try FileManager.default.moveItem(at:output,to:target)
    }
}

extension TranscriptionModel {
    func audioSource(_ doc:Transcript)->String {
        if useCleanedAudio,let path=doc.cleanedSource,FileManager.default.isReadableFile(atPath:path){return path}
        return doc.source
    }
    func cleanAudio() {
        guard !busy,let doc=current else{return}
        stopPlayback();busy=true;status=T("Cleaning audio locally…")
        let output=storage.appendingPathComponent("Cleaned/"+UUID().uuidString+".wav")
        task=Task {
            defer{busy=false;task=nil}
            do {
                let work=Task.detached{try await AudioCleanup.create(URL(fileURLWithPath:doc.source),target:output)}
                try await withTaskCancellationHandler{try await work.value}onCancel:{work.cancel()}
                try Task.checkCancellation()
                guard let i=documents.firstIndex(where:{$0.id==doc.id}) else{try? FileManager.default.removeItem(at:output);return}
                documents[i].cleanedSource=output.path;persist();status=T("Cleaned copy ready. Select Use cleaned audio to listen or transcribe again.")
            } catch {try? FileManager.default.removeItem(at:output);if !Task.isCancelled{self.error=error.localizedDescription}}
        }
    }
    func repeatAudio(start:Double=0,end:Double?=nil) {
        guard start.isFinite,start>=0,end.map({$0.isFinite && $0-start>=0.08}) ?? true else{return}
        loopStart=start;loopEnd=end;play(at:start)
    }
    func clickWord(_ index:Int) {
        guard let doc=current else{return}
        if let word=AudioWordMap.word(index,document:doc,visible:TextExport.render(doc,kind:"txt")) {
            loopStart=nil;loopEnd=nil;play(at:word.start)
        }else{status=T("No reliable word timing here. Use Review to listen to the original segment.")}
    }
}

enum AudioReviewChecks {
    static func run() async throws {
        func check(_ condition:Bool,_ label:String)throws {guard condition else{throw TranscribeError.message("FAIL "+label)};print("OK "+label)}
        var doc=Transcript(source:"/fixture.wav",name:"fixture.wav")
        var segment=Segment(start:1,end:4,text:"Ana dijo 9,5.",original:"Ana dijo 9,5.",confidence:0.9)
        segment.wordTimings=[TimedToken(text:"Ana",start:1,end:1.4),TimedToken(text:" dijo",start:1.5,end:2),TimedToken(text:" 9,5.",start:3,end:4)]
        doc.segments=[segment]
        let text=TextExport.render(doc,kind:"txt")
        try check(AudioWordMap.word(9,document:doc,visible:text)?.start==3,"Exact decimal word timing")
        try check(AudioWordMap.word(3,document:doc,visible:text)==nil,"Whitespace does not seek")
        try check(AudioWordMap.word(9,document:doc,visible:"Ana dijo 19,5.")==nil,"Edited word does not invent timing")
        try check(AudioWordMap.word(0,document:doc,visible:"Ana dijo 9,5. Ana dijo 9,5.")==nil,"Ambiguous duplicate does not seek")
        let times=AudioWordMap.selection(NSRange(location:4,length:8),document:doc,visible:text)
        try check(times?.0==1.5 && times?.1==4,"Loop selection uses word bounds")
        func level(_ frequency:Float)throws->Double {
            var filter=RumbleFilter();var energy:Double=0
            for i in 0..<32000 {let y=try filter.sample(sin(2 * .pi * frequency * Float(i)/16000));if i>=16000{energy += Double(y*y)}}
            return sqrt(energy/16000)
        }
        let low=try level(20),voice=try level(1000)
        try check(low/voice<0.35 && voice>0.65,"Rumble reduced; voice band retained")
        try check(RumbleFilter.gain(0)==1 && RumbleFilter.gain(0.01)<=2,"Silence and gain bounds")
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent("Vocalia-AudioTest-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        defer{try? FileManager.default.removeItem(at:folder)}
        let source=folder.appendingPathComponent("source.wav"),target=folder.appendingPathComponent("clean.wav")
        let format=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:16000,channels:1,interleaved:false)!
        do {
            let writer=try AVAudioFile(forWriting:source,settings:format.settings)
            let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:32000)!;buffer.frameLength=32000
            for i in 0..<32000 {buffer.floatChannelData![0][i]=0.1*sin(2 * .pi * 1000 * Float(i)/16000)+0.1*sin(2 * .pi * 20 * Float(i)/16000)}
            try writer.write(from:buffer)
        }
        let stereo=folder.appendingPathComponent("stereo.wav"),mono=folder.appendingPathComponent("mono.caf")
        do {
            let stereoFormat=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:48000,channels:2,interleaved:false)!
            let writer=try AVAudioFile(forWriting:stereo,settings:stereoFormat.settings)
            let buffer=AVAudioPCMBuffer(pcmFormat:stereoFormat,frameCapacity:48000)!;buffer.frameLength=48000
            for channel in 0..<2 {for i in 0..<48000 {buffer.floatChannelData![channel][i]=0.1*sin(2 * .pi * 400 * Float(i)/48000)}}
            try writer.write(from:buffer)
        }
        _ = try await AudioPrep.convertPCM(stereo,into:mono,progress:{_ in})
        let converted=try AVAudioFile(forReading:mono)
        try check(converted.length==16000 && converted.processingFormat.channelCount==1,"Stereo 48 kHz resamples without timeline drift")
        let original=try Data(contentsOf:source)
        try await AudioCleanup.create(source,target:target)
        let clean=try AVAudioFile(forReading:target)
        try check(clean.length==32000,"Cleaned copy preserves every audio frame")
        let after=try Data(contentsOf:source)
        try check(original==after,"Original recording unchanged")
        let buffer=AVAudioPCMBuffer(pcmFormat:clean.processingFormat,frameCapacity:32000)!;try clean.read(into:buffer)
        let peak=(0..<Int(buffer.frameLength)).map{abs(buffer.floatChannelData![0][$0])}.max() ?? 0
        try check(peak<=0.951,"Cleaned copy does not clip")
        let savedDoc=doc
        let state=try await MainActor.run { () throws -> Data in
            let model=TranscriptionModel(storageOverride:folder.appendingPathComponent("history"));model.documents=[savedDoc];model.selected=savedDoc.id;model.persist()
            return try Data(contentsOf:model.storage.appendingPathComponent("transcripciones.json"))
        }
        let decoded=try JSONDecoder().decode([Transcript].self,from:state)
        try check(decoded[0].cleanedSource==nil && decoded[0].segments==doc.segments,"Old history remains compatible")
        print("Audio review checks passed")
    }
}

extension AudioPrep {
    static func convertPCM(_ source:URL,into target:URL,progress:@escaping @Sendable(Double) async->Void) async throws->PreparedAudio {
        let input=try AVAudioFile(forReading:source)
        let duration=Double(input.length)/input.processingFormat.sampleRate
        guard duration.isFinite,duration>0,duration<86400 else{throw TranscribeError.message("Invalid audio duration")}
        let format=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:16000,channels:1,interleaved:false)!
        guard let converter=AVAudioConverter(from:input.processingFormat,to:format) else{throw TranscribeError.message("Unsupported PCM format")}
        let writer=try AVAudioFile(forWriting:target,settings:format.settings)
        let output=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:8192)!
        var finished=false;var readError:Error?
        while !finished {
            try Task.checkCancellation()
            var error:NSError?
            let status=converter.convert(to:output,error:&error){frames,state in
                guard input.framePosition<input.length else{state.pointee = .endOfStream;return nil}
                let count=min(AVAudioFrameCount(min(input.length-input.framePosition,Int64(UInt32.max))),frames)
                guard let buffer=AVAudioPCMBuffer(pcmFormat:input.processingFormat,frameCapacity:count) else{state.pointee = .endOfStream;return nil}
                do{try input.read(into:buffer,frameCount:count);state.pointee = .haveData;return buffer}
                catch{readError=error;state.pointee = .endOfStream;return nil}
            }
            if let error=readError ?? error {throw error}
            if output.frameLength>0 {try writer.write(from:output)}
            switch status {
            case .endOfStream:finished=true
            case .error:throw TranscribeError.message("PCM conversion failed")
            default:break
            }
            await progress(Double(input.framePosition)/Double(input.length))
        }
        return PreparedAudio(url:target,duration:duration,offset:0,multipleTracks:false)
    }
}
