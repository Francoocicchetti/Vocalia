import Foundation
import SwiftUI
import AppKit

struct AppRelease:Identifiable,Sendable {var version:String;var notes:String;var download:URL;var page:URL;var digest:String="";var size:Int64=0;var id:String{version}}
enum ReleaseCheck {
    static let version="0.0.6"
    static let repo="https://github.com/Francoocicchetti/Vocalia"
    static func numbers(_ value:String)->[Int]? {
        let v=value.hasPrefix("v") ? String(value.dropFirst()):value
        let parts=v.split(separator:".");guard parts.count==3,parts.allSatisfy({!$0.isEmpty && $0.allSatisfy(\.isNumber)}),parts.allSatisfy({Int($0) != nil}) else{return nil};return parts.compactMap{Int($0)}
    }
    static func select(_ releases:[[String:Any]],current:String=version)->AppRelease? {
        guard let existing=numbers(current) else{return nil}
        return releases.compactMap{release->AppRelease? in
            guard let tag=release["tag_name"] as? String,let n=numbers(tag),existing.lexicographicallyPrecedes(n),release["draft"] as? Bool != true,let date=release["published_at"] as? String,date>="2026-09-17T00:00:00Z",release["html_url"] as? String==repo+"/releases/tag/"+tag else{return nil}
            let version=tag.hasPrefix("v") ? String(tag.dropFirst()):tag
            let file="Vocalia-\(version)-macOS-AppleSilicon.zip",link=repo+"/releases/download/"+tag+"/Vocalia-\(version)-macOS-AppleSilicon.zip"
            guard let assets=release["assets"] as? [[String:Any]],let asset=assets.first(where:{$0["name"] as? String==file && $0["browser_download_url"] as? String==link}),let download=URL(string:link),let page=URL(string:repo+"/releases/tag/"+tag) else{return nil}
            return AppRelease(version:version,notes:String((release["body"] as? String ?? "").prefix(100000)),download:download,page:page,digest:asset["digest"] as? String ?? "",size:(asset["size"] as? NSNumber)?.int64Value ?? 0)
        }.max{numbers($0.version)!.lexicographicallyPrecedes(numbers($1.version)!)}
    }
    static func fetch() async throws->AppRelease? {
        var request=URLRequest(url:URL(string:"https://api.github.com/repos/Francoocicchetti/Vocalia/releases?per_page=30")!);request.timeoutInterval=15;request.setValue("Vocalia/"+version,forHTTPHeaderField:"User-Agent")
        let (bytes,response)=try await URLSession.shared.bytes(for:request)
        guard (response as? HTTPURLResponse)?.statusCode==200 else{throw URLError(.badServerResponse)}
        var data=Data();for try await byte in bytes{data.append(byte);if data.count>2000000{throw URLError(.dataLengthExceedsMaximum)}}
        guard let releases=try JSONSerialization.jsonObject(with:data) as? [[String:Any]] else{throw URLError(.cannotParseResponse)}
        return select(releases)
    }
}
@MainActor final class UpdateManager:ObservableObject {
    @Published var show=false;@Published var checking=false;@Published var release:AppRelease?;@Published var message=""
    @Published var downloading=false;@Published var installing=false;@Published var progress=0.0;@Published var archive:URL?
    var downloader:UpdateDownloader?;var work:URL?;var downloadID=UUID()
    func downloadUpdate(){
        guard !downloading,!installing,let release else{return}
        guard release.size>0,release.size<=1024*1024*1024,release.digest.range(of:"^sha256:[0-9a-fA-F]{64}$",options:.regularExpression) != nil else{message="Could not download or verify the update. Try again.";return}
        cancelDownload();let id=UUID();downloadID=id;message="";progress=0;downloading=true
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent("VocaliaUpdate-"+UUID().uuidString,isDirectory:true)
        do{try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700]);work=folder}catch{downloading=false;message="Could not download or verify the update. Try again.";return}
        downloader=UpdateDownloader(release:release,work:folder,progress:{[weak self] value in Task{@MainActor in guard self?.downloadID==id else{return};self?.progress=value}},completion:{[weak self] result in Task{@MainActor in
            guard let self,self.downloadID==id else{try? FileManager.default.removeItem(at:folder);return};self.downloading=false;self.downloader=nil
            switch result{case .success(let url):self.archive=url;self.progress=1;self.message="Update verified. Ready to install and restart."
            case .failure:self.message="Could not download or verify the update. Try again.";try? FileManager.default.removeItem(at:folder);self.work=nil}
        }})
        downloader?.start()
    }
    func cancelDownload(){downloadID=UUID();downloader?.cancel();downloader=nil;downloading=false;archive=nil;if let work{try? FileManager.default.removeItem(at:work)};work=nil}
    func install(model:TranscriptionModel){
        guard !model.busy,!model.importing else{message="Wait for transcription and imports to finish before installing.";return}
        guard !installing,let archive,let release,let work else{return}
        installing=true;message="Preparing installation…"
        let target=Bundle.main.bundleURL,parent=getpid()
        Task {
            var plan:InstallPlan?
            do{
                let prepared=try await Task.detached {try UpdateInstall.prepare(archive:archive,release:release,target:target,work:work,parent:parent)}.value;plan=prepared
                guard !model.busy,!model.importing else{throw UpdateInstall.failure("Wait for transcription and imports to finish before installing.")}
                try JSONEncoder().encode(model.documents).write(to:model.storage.appendingPathComponent("transcripciones.json"),options:.atomic)
                model.stopPlayback();try UpdateInstall.launch(prepared,work:work);NSApplication.shared.terminate(nil)
            }catch{
                if let plan{try? FileManager.default.removeItem(atPath:plan.staged)}
                message=error.localizedDescription.contains("Applications") ? "Move Vocalia to a writable Applications folder before updating." : "Could not start installation. Vocalia has not been changed."
                installing=false
            }
        }
    }
    func automaticCheck(){
        guard !(Bundle.main.bundleIdentifier ?? "").hasPrefix("cl.vocalia.qa") else{return}
        let d=UserDefaults.standard
        guard d.object(forKey:"automaticUpdates") as? Bool ?? true,Date().timeIntervalSince1970-d.double(forKey:"lastUpdateCheck")>86400 else{return};check(manual:false)
    }
    func check(manual:Bool=true){
        guard !checking,!downloading,!installing,archive==nil else{return};checking=true;message="";UserDefaults.standard.set(Date().timeIntervalSince1970,forKey:"lastUpdateCheck")
        Task {
            do {
                let result=try await ReleaseCheck.fetch();release=result;UserDefaults.standard.set(Date().timeIntervalSince1970,forKey:"lastUpdateCheck")
                if let result {
                    if manual || UserDefaults.standard.string(forKey:"notifiedUpdate") != result.version {show=true;UserDefaults.standard.set(result.version,forKey:"notifiedUpdate")}
                }else{message="You have the latest available version."}
            }catch{if manual{message="Could not check updates. Check your internet connection and try again."}}
            checking=false
        }
    }
}
struct UpdatePane:View {
    @ObservedObject var manager:UpdateManager
    @ObservedObject var model:TranscriptionModel
    @AppStorage("automaticUpdates") var automatic=true
    @Environment(\.dismiss) var dismiss
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            Text(T("Update Vocalia")+" · Vocalia "+ReleaseCheck.version).font(.title2.bold())
            Toggle(T("Check for updates automatically"),isOn:$automatic)
            Text(T("Checks contact GitHub once a day. Recordings and transcripts are never sent.")).font(.caption).foregroundStyle(.secondary)
            if let release=manager.release {
                Text(T("Update available")+" · "+release.version).font(.headline)
                ScrollView{Text(release.notes).textSelection(.enabled).frame(maxWidth:.infinity,alignment:.leading)}
                Text(T("Download and install from Vocalia. Your history, quotes and models stay on this computer."))
                if manager.downloading {Text(T("Downloading update…"));ProgressView(value:manager.progress);Text("\(Int(manager.progress*100)) %")}
                HStack{
                    if manager.archive != nil {Button(T("Install and restart")){manager.install(model:model)}.disabled(manager.installing || model.busy || model.importing)}
                    else{Button(T("Update now")){manager.downloadUpdate()}.disabled(manager.downloading || manager.installing)}
                    Button(T("Release details")){NSWorkspace.shared.open(release.page)}
                }
            }
            if manager.checking || manager.installing {ProgressView()}
            if !manager.message.isEmpty {Text(T(manager.message))}
            Spacer()
            HStack{Button(T("Check now")){manager.check()}.disabled(manager.checking || manager.downloading || manager.installing || manager.archive != nil);Spacer();Button(T(manager.downloading ? "Cancel":"Close")){manager.cancelDownload();dismiss()}.disabled(manager.installing)}
        }.padding(24).frame(width:680,height:600).interactiveDismissDisabled(manager.downloading || manager.installing)
    }
}
