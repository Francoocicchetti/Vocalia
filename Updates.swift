import Foundation
import SwiftUI
import AppKit

struct AppRelease:Identifiable,Sendable {var version:String;var notes:String;var download:URL;var page:URL;var id:String{version}}
enum ReleaseCheck {
    static let version="0.0.5"
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
            guard let assets=release["assets"] as? [[String:Any]],assets.contains(where:{$0["name"] as? String==file && $0["browser_download_url"] as? String==link}),let download=URL(string:link),let page=URL(string:repo+"/releases/tag/"+tag) else{return nil}
            return AppRelease(version:version,notes:String((release["body"] as? String ?? "").prefix(100000)),download:download,page:page)
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
    func automaticCheck(){
        guard !(Bundle.main.bundleIdentifier ?? "").hasPrefix("cl.vocalia.qa") else{return}
        let d=UserDefaults.standard
        guard d.object(forKey:"automaticUpdates") as? Bool ?? true,Date().timeIntervalSince1970-d.double(forKey:"lastUpdateCheck")>86400 else{return};check(manual:false)
    }
    func check(manual:Bool=true){
        guard !checking else{return};checking=true;message="";UserDefaults.standard.set(Date().timeIntervalSince1970,forKey:"lastUpdateCheck")
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
    @AppStorage("automaticUpdates") var automatic=true
    @Environment(\.dismiss) var dismiss
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            Text(T("Updates")+" · Vocalia "+ReleaseCheck.version).font(.title2.bold())
            Toggle(T("Check for updates automatically"),isOn:$automatic)
            Text(T("Checks contact GitHub once a day. Recordings and transcripts are never sent.")).font(.caption).foregroundStyle(.secondary)
            if let release=manager.release {
                Text(T("Update available")+" · "+release.version).font(.headline)
                ScrollView{Text(release.notes).textSelection(.enabled).frame(maxWidth:.infinity,alignment:.leading)}
                Text(T("Download the ZIP, close Vocalia, then replace the app in Applications. Your history and models are preserved."))
                HStack{Button(T("Download update")){NSWorkspace.shared.open(release.download)};Button(T("Release details")){NSWorkspace.shared.open(release.page)}}
            }
            if manager.checking {ProgressView()}
            if !manager.message.isEmpty {Text(T(manager.message))}
            Spacer()
            HStack{Button(T("Check now")){manager.check()}.disabled(manager.checking);Spacer();Button(T("Close")){dismiss()}}
        }.padding(24).frame(width:680,height:520)
    }
}
