import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct LibraryHit:Identifiable {
    var document:UUID;var offset:Int;var excerpt:String;var start:Double?;var end:Double?
    var id:String {"\(document)-\(offset)"}
}
enum LibrarySearch {
    static func tags(_ input:String)->[String] {
        var seen=Set<String>()
        return input.split(separator:",").map{String($0.trimmingCharacters(in:.whitespacesAndNewlines).prefix(80))}.filter{!$0.isEmpty && seen.insert($0).inserted}.prefix(30).map{$0}
    }
    static func date(_ value:Date)->String {let f=DateFormatter();f.locale=Locale(identifier:"en_US_POSIX");f.dateFormat="yyyy-MM-dd";return f.string(from:value)}
    static func validDate(_ value:String)->Bool {if value.isEmpty{return true};let f=DateFormatter();f.locale=Locale(identifier:"en_US_POSIX");f.dateFormat="yyyy-MM-dd";f.isLenient=false;return f.date(from:value).map{f.string(from:$0)==value} ?? false}
    static func figures(_ s:Segment)->Bool {(s.text+s.original).unicodeScalars.contains{CharacterSet.decimalDigits.contains($0)}}
    static func find(_ documents:[Transcript],query:String,project:String="",tag:String="",after:String="",before:String="")->[LibraryHit] {
        var hits:[LibraryHit]=[];let needle=query.trimmingCharacters(in:.whitespacesAndNewlines)
        for doc in documents {
            if !project.isEmpty && (doc.project ?? "").lowercased() != project.lowercased(){continue}
            if !tag.isEmpty && !(doc.tags ?? []).contains(where:{$0.localizedCaseInsensitiveContains(tag)}){continue}
            let date=doc.recordedDate ?? Self.date(doc.created)
            if (!after.isEmpty && date<after) || (!before.isEmpty && date>before){continue}
            let text=TextExport.render(doc,kind:"txt") as NSString
            if needle.isEmpty {hits.append(LibraryHit(document:doc.id,offset:0,excerpt:String((text as String).prefix(160))))}
            else {
                var position=0;var matched=false
                while position<text.length {
                    let range=text.range(of:needle,options:[.caseInsensitive,.diacriticInsensitive],range:NSRange(location:position,length:text.length-position))
                    if range.location==NSNotFound {break};matched=true
                    let timing=TextAnalysis.locate(range,in:text as String,document:doc)
                    let a=max(0,range.location-45),b=min(text.length,NSMaxRange(range)+100)
                    hits.append(LibraryHit(document:doc.id,offset:range.location,excerpt:text.substring(with:NSRange(location:a,length:b-a)),start:timing?.start,end:timing?.end))
                    if hits.count>=200{return hits};position=NSMaxRange(range)
                }
                if !matched && doc.name.localizedCaseInsensitiveContains(needle){hits.append(LibraryHit(document:doc.id,offset:0,excerpt:doc.name))}
            }
            if hits.count>=200{return Array(hits.prefix(200))}
        };return hits
    }
}
struct LibraryPane:View {
    @ObservedObject var model:TranscriptionModel
    var open:(LibraryHit)->Void
    @Environment(\.dismiss) var dismiss
    @State var query="";@State var project="";@State var tag="";@State var after="";@State var before="";@State var selected:String?
    @State var editProject="";@State var editTags="";@State var editDate="";@State var message=""
    var hits:[LibraryHit] {LibrarySearch.find(model.documents,query:query,project:project,tag:tag,after:after,before:before)}
    var hit:LibraryHit? {hits.first{$0.id==selected}}
    var projects:[String] {Array(Set(model.documents.compactMap(\.project).filter{!$0.isEmpty})).sorted()}
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            Text(T("Library and projects")).font(.title2.bold())
            TextField(T("Search all transcripts"),text:$query).textFieldStyle(.roundedBorder)
            HStack {
                Picker(T("Project"),selection:$project){Text(T("All projects")).tag("");ForEach(projects,id:\.self){Text($0).tag($0)}}
                TextField(T("Filter by tag"),text:$tag)
                TextField(T("From YYYY-MM-DD"),text:$after)
                TextField(T("To YYYY-MM-DD"),text:$before)
            }.textFieldStyle(.roundedBorder)
            Text(T("Up to 200 results. Dates refer to the recording date you assign.")).font(.caption).foregroundStyle(.secondary)
            List(hits,selection:$selected){hit in
                VStack(alignment:.leading,spacing:4){
                    Text(model.documents.first{$0.id==hit.document}?.name ?? "").font(.headline)
                    Text(hit.excerpt).lineLimit(3)
                    Text(hit.start.map{TextExport.clock($0)} ?? T("No exact audio position")).font(.caption).foregroundStyle(.secondary)
                }.tag(hit.id)
            }.onChange(of:selected){load()}
            HStack{TextField(T("Project"),text:$editProject);TextField(T("Tags separated by commas"),text:$editTags);TextField(T("Recording date YYYY-MM-DD"),text:$editDate)}.textFieldStyle(.roundedBorder).disabled(hit==nil)
            Text(T("Projects and tags organize your history without moving original files.")).font(.caption)
            if !message.isEmpty {Text(message).foregroundStyle(.red)}
            HStack{
                Button(T("Save organization")){save()}.disabled(hit==nil)
                Button(T("Open result and listen")){if let hit{dismiss();open(hit)}}.disabled(hit==nil)
                Spacer();Button(T("Close")){dismiss()}
            }
        }.padding(22).frame(width:850,height:610)
    }
    func load(){guard let hit,let doc=model.documents.first(where:{$0.id==hit.document}) else{return};editProject=doc.project ?? "";editTags=(doc.tags ?? []).joined(separator:", ");editDate=doc.recordedDate ?? LibrarySearch.date(doc.created)}
    func save(){
        guard let hit,let i=model.documents.firstIndex(where:{$0.id==hit.document}) else{return}
        guard LibrarySearch.validDate(editDate) else{message=T("Use a valid date in YYYY-MM-DD format.");return}
        model.documents[i].project=String(editProject.trimmingCharacters(in:.whitespacesAndNewlines).prefix(120));model.documents[i].tags=LibrarySearch.tags(editTags);model.documents[i].recordedDate=editDate;model.persist();message=""
    }
}
struct WordPane:View {
    let document:Transcript
    @Environment(\.dismiss) var dismiss
    @State var title:String;@State var date:String;@State var quotes:Set<UUID>;@State var error=""
    init(document:Transcript){self.document=document;_title=State(initialValue:URL(fileURLWithPath:document.name).deletingPathExtension().lastPathComponent);_date=State(initialValue:document.recordedDate ?? LibrarySearch.date(document.created));_quotes=State(initialValue:Set((document.quotes ?? []).map(\.id)))}
    var body:some View {
        VStack(alignment:.leading,spacing:14){
            Text(T("Export Word")).font(.title2.bold())
            TextField(T("Document title"),text:$title).textFieldStyle(.roundedBorder)
            TextField(T("Recording date YYYY-MM-DD"),text:$date).textFieldStyle(.roundedBorder)
            Text(T("Select saved quotes to include"))
            List(document.quotes ?? []){quote in Toggle(quote.text,isOn:Binding(get:{quotes.contains(quote.id)},set:{if $0{quotes.insert(quote.id)}else{quotes.remove(quote.id)}}))}
            if !error.isEmpty {Text(error).foregroundStyle(.red)}
            HStack{Button(T("Close")){dismiss()};Spacer();Button(T("Save Word document")){save()}}
        }.padding(24).frame(width:650,height:480)
    }
    func save(){
        guard !date.isEmpty,LibrarySearch.validDate(date) else{error=T("Use a valid date in YYYY-MM-DD format.");return}
        let panel=NSSavePanel();panel.allowedContentTypes=[UTType(filenameExtension:"docx") ?? .data];panel.nameFieldStringValue=URL(fileURLWithPath:document.name).deletingPathExtension().lastPathComponent+".docx"
        if panel.runModal() == .OK,let url=panel.url {
            do{try WordExport.data(document,title:title.isEmpty ? document.name:title,date:date,quotes:(document.quotes ?? []).filter{quotes.contains($0.id)}).write(to:url,options:.atomic);dismiss()}catch{self.error=error.localizedDescription}
        }
    }
}

enum LibraryChecks {
    @MainActor static func run(output:String?=nil){
        var doc=Transcript(source:"/private/interview.opus",name:"Entrevista municipal.opus")
        doc.segments=[Segment(start:2,end:6,text:"El presupuesto es 9,5 millones.",original:"El presupuesto es 9 coma 5 millones."),Segment(start:7,end:9,text:"La entrevista continúa.",original:"La entrevista continúa.")]
        doc.project="Municipio";doc.tags=["salud","Chile"];doc.recordedDate="2026-09-17"
        let hits=LibrarySearch.find([doc],query:"PRESUPUESTO");precondition(hits.count==1 && hits[0].start==2)
        let cross=LibrarySearch.find([doc],query:"millones. La entrevista");precondition(cross.first?.end==9)
        precondition(LibrarySearch.find([doc],query:"",project:"municipio",tag:"CHI",after:"2026-09-01",before:"2026-09-30").count==1)
        precondition(LibrarySearch.find([doc],query:"",project:"Other").isEmpty)
        precondition(LibrarySearch.tags("prensa, Chile, prensa")==["prensa","Chile"])
        precondition(!LibrarySearch.validDate("2026-02-30") && LibrarySearch.validDate("2026-09-17"))
        doc.fullTextOverride="Cambió a diez millones.";precondition(LibrarySearch.find([doc],query:"diez").first?.start==nil)
        let restored=try! JSONDecoder().decode(Transcript.self,from:JSONEncoder().encode(doc));precondition(restored==doc)
        doc.fullTextOverride="Texto editado & completo\nEl presupuesto es 9,5 millones. Esta entrevista aborda la inversión municipal en salud y la ejecución de los recursos.\n\nLa autoridad señaló que las cifras serán revisadas antes de publicar el informe."
        let quote=SavedQuote(text:"El presupuesto es 9,5 millones.",speaker:"Ana",start:2,end:6,source:doc.source,sourceName:doc.name,editedSource:false)
        let data=WordExport.data(doc,title:"Entrevista municipal",date:"2026-09-17",quotes:[quote]);precondition(data.starts(with:[0x50,0x4b,3,4]))
        if let output{try! data.write(to:URL(fileURLWithPath:output),options:.atomic)}
        func release(_ version:String,_ date:String)->[String:Any]{let file="Vocalia-\(version)-macOS-AppleSilicon.zip";return ["tag_name":"v"+version,"published_at":date,"draft":false,"html_url":ReleaseCheck.repo+"/releases/tag/v"+version,"body":"Changes","assets":[["name":file,"browser_download_url":ReleaseCheck.repo+"/releases/download/v"+version+"/"+file]]]}
        precondition(ReleaseCheck.select([release("1.0.4","2026-09-16T00:00:00Z")])==nil)
        precondition(ReleaseCheck.select([release("0.0.6","2026-09-18T00:00:00Z")])==nil)
        precondition(ReleaseCheck.select([release("0.0.7","2026-09-18T00:00:00Z")])?.version=="0.0.7")
        var evil=release("0.0.7","2026-09-18T00:00:00Z");evil["assets"]=[["name":"Vocalia-0.0.7-macOS-AppleSilicon.zip","browser_download_url":"https://example.com/app.zip"]];precondition(ReleaseCheck.select([evil])==nil)
        precondition(LibrarySearch.figures(doc.segments[0]))
        print("PASS: library search, timings, edits, metadata migration, figures, Word archive and trusted update selection")
    }
}
