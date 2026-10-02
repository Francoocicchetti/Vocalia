import SwiftUI
import AppKit

extension TranscriptionModel {
    var checkedDocuments:[Transcript] {documents.filter{batchSelection.contains($0.id)}}
    func commitBatch(_ value:[Transcript])throws {
        try JSONEncoder().encode(value).write(to:storage.appendingPathComponent("transcripciones.json"),options:.atomic)
        documents=value
    }
    func removeBatch(_ ids:Set<UUID>) {
        guard !busy,!importing else{return}
        let removed=documents.filter{ids.contains($0.id)}
        guard !removed.isEmpty else{return}
        do {
            // Write recovery data before changing history. Never touch recordings.
            try JSONEncoder().encode(removed).write(to:storage.appendingPathComponent("last-removed-group.json"),options:.atomic)
            let next=documents.filter{!ids.contains($0.id)}
            try commitBatch(next);lastRemovedBatch=removed
            if let selected,ids.contains(selected){stopPlayback();loadedSource=nil;loadedAudioPath=nil;self.selected=next.first?.id}
            batchSelection.subtract(ids)
        }catch{self.error=error.localizedDescription}
    }
    func restoreBatch() {
        guard !busy,!importing,!lastRemovedBatch.isEmpty else{return}
        let existing=Set(documents.map(\.id)),restored=lastRemovedBatch.filter{!existing.contains($0.id)}
        do {
            try commitBatch(documents+restored)
            batchSelection=Set(restored.map(\.id));selected=restored.first?.id ?? selected
            lastRemovedBatch=[];try? FileManager.default.removeItem(at:storage.appendingPathComponent("last-removed-group.json"))
        }catch{self.error=error.localizedDescription}
    }
    func assignBatch(_ ids:Set<UUID>,project:String) {
        guard !busy,!importing else{return}
        var next=documents
        for i in next.indices where ids.contains(next[i].id){next[i].project=String(project.trimmingCharacters(in:.whitespacesAndNewlines).prefix(120))}
        do{try commitBatch(next)}catch{self.error=error.localizedDescription}
    }
    func exportSelection(_ kind:String) {
        let ready=checkedDocuments.filter{!TextExport.render($0,kind:"txt").trimmingCharacters(in:.whitespacesAndNewlines).isEmpty}
        guard !ready.isEmpty else{error=T("No text to export in the selection.");return}
        let panel=NSOpenPanel();panel.canChooseDirectories=true;panel.canChooseFiles=false
        guard panel.runModal() == .OK,let folder=panel.url else{return}
        do {
            for doc in ready {
                let base=URL(fileURLWithPath:doc.name).deletingPathExtension().lastPathComponent
                var index=0
                let bytes=kind=="docx" ? WordExport.data(doc,title:doc.name,date:doc.recordedDate ?? LibrarySearch.date(doc.created),quotes:doc.quotes ?? []) : Data(TextExport.render(doc,kind:kind).utf8)
                while true {
                    let url=folder.appendingPathComponent(base+(index==0 ? "" : " (\(index))")+"."+kind)
                    do{try bytes.write(to:url,options:.withoutOverwriting);break}
                    catch CocoaError.fileWriteFileExists{index+=1}
                }
            }
            status=T("Selection exported. Existing files were kept.")
        }catch{self.error=error.localizedDescription}
    }
}

struct BatchControls:View {
    @ObservedObject var model:TranscriptionModel
    @State var removal=false;@State var retranscribe=false;@State var organization=false
    @State var captured=Set<UUID>();@State var project=""
    var locked:Bool {model.busy || model.importing}
    func count(_ text:String)->String {T(text).replacingOccurrences(of:"{count}",with:String(captured.count))}
    var body:some View {
        VStack(alignment:.leading,spacing:7) {
            HStack {
                Button(T("Select all")){model.batchSelection=Set(model.documents.map(\.id))}.disabled(locked || model.documents.isEmpty)
                Button{model.batchSelection=[]}label:{Image(systemName:"xmark.circle")}.help(T("Clear selection")).accessibilityLabel(T("Clear selection")).disabled(locked || model.batchSelection.isEmpty)
            }.controlSize(.small)
            Text(T("{count} selected").replacingOccurrences(of:"{count}",with:String(model.checkedDocuments.count))).font(.caption).foregroundStyle(.secondary)
            Menu(T("Actions for selection")) {
                Button(T("Transcribe selected pending")){model.begin(ids:model.checkedDocuments.filter{!$0.complete}.map(\.id))}
                    .disabled(!model.checkedDocuments.contains{!$0.complete})
                Button(T("Transcribe selection again…")){captured=Set(model.checkedDocuments.map(\.id));retranscribe=true}
                Button(T("Assign project…")){captured=Set(model.checkedDocuments.map(\.id));project="";organization=true}
                Divider()
                ForEach(["txt","srt","vtt","docx"],id:\.self){kind in
                    Button(T("Export selection: "+kind.uppercased())){model.exportSelection(kind)}
                }
                Divider()
                Button(T("Remove selection from history…"),role:.destructive){captured=Set(model.checkedDocuments.map(\.id));removal=true}
            }.disabled(locked || model.checkedDocuments.isEmpty)
            Button(T("Restore last removed group")){model.restoreBatch()}.controlSize(.small).disabled(locked || model.lastRemovedBatch.isEmpty)
        }
        .confirmationDialog(count("Remove {count} recordings from history? Original files are kept. You can restore the last removed group."),isPresented:$removal,titleVisibility:.visible) {
            Button(T("Remove selection from history…"),role:.destructive){model.removeBatch(captured)}
        }
        .confirmationDialog(count("Transcribe {count} selected recordings again? Existing text will be backed up before replacement."),isPresented:$retranscribe,titleVisibility:.visible){
            Button(T("Transcribe selection again…")){model.begin(ids:model.documents.filter{captured.contains($0.id)}.map(\.id))}
        }
        .alert(T("Assign project…"),isPresented:$organization){
            TextField(T("Project (blank removes assignment)"),text:$project)
            Button(T("Save")){model.assignBatch(captured,project:project)}
            Button(T("Cancel"),role:.cancel){}
        }
    }
}

enum BatchChecks {
    @MainActor static func run()throws {
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent("Vocalia-Batch-"+UUID().uuidString)
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        defer{try? FileManager.default.removeItem(at:folder)}
        let source=folder.appendingPathComponent("original.wav");try Data("original bytes".utf8).write(to:source)
        let model=TranscriptionModel(storageOverride:folder)
        var a=Transcript(source:source.path,name:"original.wav");a.fullTextOverride="Edited quote"
        let b=Transcript(source:"/missing.opus",name:"missing.opus"),c=Transcript(source:"/other.mp3",name:"other.mp3")
        model.documents=[a,b,c];model.selected=c.id;model.batchSelection=[a.id,b.id]
        let stale=model.textBinding(for:a)
        model.assignBatch([a.id,b.id],project:" News ")
        precondition(model.documents[0].project=="News" && model.documents[2].project==nil)
        model.busy=true;model.removeBatch([a.id,b.id]);precondition(model.documents.count==3);model.busy=false
        model.removeBatch([a.id,b.id]);stale.wrappedValue="Late edit"
        precondition(model.documents.map(\.id)==[c.id] && model.selected==c.id && model.batchSelection.isEmpty)
        let reopened=TranscriptionModel(storageOverride:folder);reopened.restoreBatch()
        precondition(reopened.documents.count==3 && reopened.documents.first{$0.id==a.id}?.fullTextOverride=="Edited quote")
        reopened.restoreBatch();precondition(reopened.documents.count==3)
        reopened.removeBatch(Set(reopened.documents.map(\.id)));precondition(reopened.documents.isEmpty && reopened.selected==nil)
        reopened.restoreBatch();precondition(reopened.documents.count==3)
        let blocked=TranscriptionModel(storageOverride:folder.appendingPathComponent("blocked"))
        blocked.documents=[a,b]
        try FileManager.default.createDirectory(at:blocked.storage.appendingPathComponent("transcripciones.json"),withIntermediateDirectories:true)
        blocked.removeBatch([a.id])
        precondition(blocked.documents.count==2 && blocked.error != nil)
        let original=try Data(contentsOf:source)
        precondition(original==Data("original bytes".utf8))
        print("PASS: bulk removal/restoration across restart, stale edits, busy guard, project scope and original preservation")
    }
}
