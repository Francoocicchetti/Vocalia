import Foundation
import CryptoKit
import AppKit
import Darwin

struct InstallPlan:Codable,Sendable {
    var parent:Int32;var staged:String;var target:String;var backup:String;var result:String
}
enum UpdateInstall {
    static func failure(_ text:String)->Error {TranscribeError.message(text)}
    static func hash(_ url:URL)throws->String {
        let file=try FileHandle(forReadingFrom:url);defer{try? file.close()};var hash=SHA256()
        while let chunk=try file.read(upToCount:1024*1024),!chunk.isEmpty{hash.update(data:chunk)}
        return hash.finalize().map{String(format:"%02x",$0)}.joined()
    }
    static func verify(_ url:URL,release:AppRelease)throws {
        guard release.size>0,release.size<=1024*1024*1024,release.digest.range(of:"^sha256:[0-9a-fA-F]{64}$",options:.regularExpression) != nil else{throw failure("Missing update checksum")}
        let attributes=try FileManager.default.attributesOfItem(atPath:url.path)
        guard attributes[.type] as? FileAttributeType == .typeRegular,(attributes[.size] as? NSNumber)?.int64Value==release.size,try hash(url)==String(release.digest.dropFirst(7)).lowercased() else{throw failure("Update checksum mismatch")}
    }
    static func run(_ executable:String,_ args:[String])throws {
        let p=Process();p.executableURL=URL(fileURLWithPath:executable);p.arguments=args;p.standardOutput=FileHandle.nullDevice;p.standardError=FileHandle.nullDevice
        try p.run();p.waitUntilExit();guard p.terminationStatus==0 else{throw failure("Update preparation failed")}
    }
    static func validateBundle(_ url:URL,version:String?=nil)throws {
        guard let bundle=Bundle(url:url),bundle.bundleIdentifier=="cl.franco.transcribe",version==nil || bundle.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String==version else{throw failure("Unexpected application in update")}
        try run("/usr/bin/codesign",["--verify","--deep","--strict",url.path])
    }
    static func targetAllowed(_ url:URL)throws {
        guard url.pathExtension=="app",!url.path.contains("/AppTranslocation/"),!url.path.contains("/Volumes/"),url.standardizedFileURL==url.resolvingSymlinksInPath(),FileManager.default.isWritableFile(atPath:url.deletingLastPathComponent().path) else{throw failure("Move Vocalia to a writable Applications folder before updating.")}
    }
    static func prepare(archive:URL,release:AppRelease,target:URL,work:URL,parent:Int32)throws->InstallPlan {
        try verify(archive,release:release);try targetAllowed(target);try validateBundle(target)
        let fm=FileManager.default,extracted=work.appendingPathComponent("unpacked-"+UUID().uuidString,isDirectory:true)
        try fm.createDirectory(at:extracted,withIntermediateDirectories:false,attributes:[.posixPermissions:0o700])
        // Only the verified official archive is extracted. Download digests are required.
        try run("/usr/bin/ditto",["-x","-k",archive.path,extracted.path])
        let app=extracted.appendingPathComponent("Vocalia.app");try validateBundle(app,version:release.version)
        let parentFolder=target.deletingLastPathComponent(),token=UUID().uuidString
        let staged=parentFolder.appendingPathComponent(".Vocalia-update-\(token).app")
        do{try fm.copyItem(at:app,to:staged);try validateBundle(staged,version:release.version)}catch{try? fm.removeItem(at:staged);throw error}
        return InstallPlan(parent:parent,staged:staged.path,target:target.path,backup:parentFolder.appendingPathComponent("Vocalia Previous \(token).app").path,result:work.appendingPathComponent("install-result.txt").path)
    }
    static func replace(_ plan:InstallPlan,move:(URL,URL)throws->Void = {try FileManager.default.moveItem(at:$0,to:$1)})throws {
        let target=URL(fileURLWithPath:plan.target),stage=URL(fileURLWithPath:plan.staged),backup=URL(fileURLWithPath:plan.backup)
        guard target.deletingLastPathComponent()==stage.deletingLastPathComponent(),target.deletingLastPathComponent()==backup.deletingLastPathComponent(),target != stage,target != backup,stage != backup,!FileManager.default.fileExists(atPath:backup.path) else{throw failure("Invalid update destination")}
        try move(target,backup)
        do{try move(stage,target)}catch{try move(backup,target);throw error}
    }
    static func launch(_ plan:InstallPlan,work:URL)throws {
        let helper=work.appendingPathComponent("VocaliaUpdater"),config=work.appendingPathComponent("install.json")
        try FileManager.default.copyItem(at:Bundle.main.executableURL!,to:helper);try FileManager.default.setAttributes([.posixPermissions:0o700],ofItemAtPath:helper.path)
        try JSONEncoder().encode(plan).write(to:config,options:.atomic)
        let process=Process();process.executableURL=helper;process.arguments=["--apply-update",config.path];process.standardOutput=FileHandle.nullDevice;process.standardError=FileHandle.nullDevice;try process.run()
    }
    static func apply(config:URL,relaunch:Bool=true)->Int32 {
        guard let data=try? Data(contentsOf:config),let plan=try? JSONDecoder().decode(InstallPlan.self,from:data) else{return 1}
        do {
            for _ in 0..<120 {if kill(plan.parent,0) != 0{break};Thread.sleep(forTimeInterval:0.5)}
            guard kill(plan.parent,0) != 0 else{throw failure("Vocalia did not close; update cancelled")}
            try targetAllowed(URL(fileURLWithPath:plan.target));try validateBundle(URL(fileURLWithPath:plan.staged));try validateBundle(URL(fileURLWithPath:plan.target))
            try replace(plan)
            try "PASS".write(toFile:plan.result,atomically:true,encoding:.utf8)
            // Keep the previous application as a rollback copy. User data is never moved.
            if relaunch{try run("/usr/bin/open",[plan.target])};return 0
        }catch{
            try? error.localizedDescription.write(toFile:plan.result,atomically:true,encoding:.utf8)
            if relaunch{try? run("/usr/bin/open",[FileManager.default.fileExists(atPath:plan.target) ? plan.target:plan.backup])};return 1
        }
    }
    static func downloadTest(manifest:URL) async throws {
        let data=try Data(contentsOf:manifest)
        let row=try JSONSerialization.jsonObject(with:data) as! [String:Any]
        guard let release=ReleaseCheck.select([row],current:"0.0.4") else{throw failure("No test release")}
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent("vocalia-download-test-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:folder)}
        let file:URL=try await withCheckedThrowingContinuation{continuation in
            let downloader=UpdateDownloader(release:release,work:folder,progress:{_ in},completion:{continuation.resume(with:$0)})
            downloader.start()
        }
        try verify(file,release:release)
        print("PASS: real official Mac update downloaded and SHA256 verified without browser or installation")
    }
    static func packageTest(archive:URL)throws {
        let fm=FileManager.default,work=fm.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent("vocalia-package-update-"+UUID().uuidString)
        try fm.createDirectory(at:work,withIntermediateDirectories:true);defer{try? fm.removeItem(at:work)}
        let target=work.appendingPathComponent("Vocalia.app")
        try fm.copyItem(at:Bundle.main.bundleURL,to:target)
        let history=work.appendingPathComponent("history.json");try Data("keep history".utf8).write(to:history)
        let size=(try fm.attributesOfItem(atPath:archive.path)[.size] as! NSNumber).int64Value
        let release=AppRelease(version:ReleaseCheck.version,notes:"",download:URL(string:ReleaseCheck.repo)!,page:URL(string:ReleaseCheck.repo)!,digest:"sha256:"+(try hash(archive)),size:size)
        let plan=try prepare(archive:archive,release:release,target:target,work:work,parent:Int32.max)
        let config=work.appendingPathComponent("plan.json");try JSONEncoder().encode(plan).write(to:config)
        guard apply(config:config,relaunch:false)==0 else{throw failure("Package installation test failed")}
        try validateBundle(target,version:ReleaseCheck.version);precondition(fm.fileExists(atPath:plan.backup));precondition((try! String(contentsOf:history,encoding:.utf8))=="keep history")
        print("PASS: signed package extraction, verification, installation, rollback copy and history retention")
    }
    static func tests()throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent("vocalia-update-test-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:root)}
        let history=root.appendingPathComponent("history.json");try Data("preserved quotes and transcripts".utf8).write(to:history)
        let target=root.appendingPathComponent("Vocalia.app"),stage=root.appendingPathComponent("new.app"),backup=root.appendingPathComponent("old.app")
        try Data("old".utf8).write(to:target);try Data("new".utf8).write(to:stage)
        let plan=InstallPlan(parent:0,staged:stage.path,target:target.path,backup:backup.path,result:root.appendingPathComponent("result").path)
        var failed=false
        do{try replace(plan,move:{a,b in if a==stage{throw failure("Simulated replacement failure")};try FileManager.default.moveItem(at:a,to:b)})}catch{failed=true}
        precondition(failed && (try! String(contentsOf:target,encoding:.utf8))=="old")
        try replace(plan);precondition((try! String(contentsOf:target,encoding:.utf8))=="new" && (try! String(contentsOf:backup,encoding:.utf8))=="old")
        let release=AppRelease(version:ReleaseCheck.version,notes:"",download:URL(string:ReleaseCheck.repo)!,page:URL(string:ReleaseCheck.repo)!,digest:"sha256:"+(try hash(target)),size:3)
        try verify(target,release:release);try Data("bad".utf8).write(to:target)
        failed=false;do{try verify(target,release:release)}catch{failed=true};precondition(failed)
        precondition((try! String(contentsOf:history,encoding:.utf8))=="preserved quotes and transcripts")
        print("PASS: update checksum, tamper rejection, atomic replacement and rollback; history outside target untouched")
    }
}

final class UpdateDownloader:NSObject,URLSessionDownloadDelegate,@unchecked Sendable {
    let release:AppRelease;let work:URL;let progress:@Sendable(Double)->Void;let completion:@Sendable(Result<URL,Error>)->Void
    var session:URLSession?;var task:URLSessionDownloadTask?
    init(release:AppRelease,work:URL,progress:@escaping @Sendable(Double)->Void,completion:@escaping @Sendable(Result<URL,Error>)->Void){self.release=release;self.work=work;self.progress=progress;self.completion=completion}
    func start(){let config=URLSessionConfiguration.ephemeral;config.timeoutIntervalForRequest=20;config.timeoutIntervalForResource=900;session=URLSession(configuration:config,delegate:self,delegateQueue:nil);task=session!.downloadTask(with:release.download);task!.resume()}
    func cancel(){task?.cancel()}
    func urlSession(_ session:URLSession,downloadTask:URLSessionDownloadTask,didWriteData bytesWritten:Int64,totalBytesWritten:Int64,totalBytesExpectedToWrite:Int64){
        if totalBytesWritten>release.size{downloadTask.cancel()};progress(min(1,Double(totalBytesWritten)/Double(max(1,release.size))))
    }
    func urlSession(_ session:URLSession,downloadTask:URLSessionDownloadTask,didFinishDownloadingTo location:URL){
        do{guard (downloadTask.response as? HTTPURLResponse)?.statusCode==200 else{throw UpdateInstall.failure("Download failed")};try UpdateInstall.verify(location,release:release);let target=work.appendingPathComponent("update.zip");try FileManager.default.moveItem(at:location,to:target);completion(.success(target))}catch{completion(.failure(error))}
    }
    func urlSession(_ session:URLSession,task:URLSessionTask,didCompleteWithError error:Error?){if let error{completion(.failure(error))};session.finishTasksAndInvalidate()}
}
