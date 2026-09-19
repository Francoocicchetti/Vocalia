import Foundation

enum WordExport {
    static func xml(_ value:String)->String {
        String(String.UnicodeScalarView(value.unicodeScalars.filter{let n=$0.value;return n==9 || n==10 || n==13 || (n>=32 && n<=0xD7FF) || (n>=0xE000 && n<=0xFFFD) || (n>=0x10000 && n<=0x10FFFF)})).replacingOccurrences(of:"&",with:"&amp;").replacingOccurrences(of:"<",with:"&lt;").replacingOccurrences(of:">",with:"&gt;").replacingOccurrences(of:"\"",with:"&quot;")
    }
    static func p(_ value:String,_ style:String="Normal")->String {"<w:p><w:pPr><w:pStyle w:val=\""+style+"\"/></w:pPr><w:r><w:t xml:space=\"preserve\">"+xml(value)+"</w:t></w:r></w:p>"}
    @MainActor static func data(_ doc:Transcript,title:String,date:String,quotes:[SavedQuote])->Data {
        var body=p(title,"Title")+p(date)
        if let project=doc.project,!project.isEmpty {body+=p(T("Project")+": "+project)}
        if let tags=doc.tags,!tags.isEmpty {body+=p(T("Tags")+": "+tags.joined(separator:", "))}
        body+=p(T("Full transcript"),"Heading1")
        for line in TextExport.render(doc,kind:"txt").components(separatedBy:.newlines){body+=p(line)}
        if !quotes.isEmpty {
            body+=p(T("Selected quotes"),"Heading1")
            for quote in quotes {body+=p(quote.text)+p([quote.speaker,doc.name,TextExport.clock(quote.start)+"–"+TextExport.clock(quote.end)].filter{!$0.isEmpty}.joined(separator:" · "),"Caption")}
        }
        let document="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\"><w:body>"+body+"<w:sectPr><w:pgSz w:w=\"11906\" w:h=\"16838\"/><w:pgMar w:top=\"1134\" w:right=\"1134\" w:bottom=\"1134\" w:left=\"1134\"/></w:sectPr></w:body></w:document>"
        var files:[(String,String)]=[]
        files.append(("[Content_Types].xml","<?xml version=\"1.0\"?><Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\"><Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/><Default Extension=\"xml\" ContentType=\"application/xml\"/><Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/><Override PartName=\"/word/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml\"/></Types>"))
        files.append(("_rels/.rels","<?xml version=\"1.0\"?><Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"word/document.xml\"/></Relationships>"))
        files.append(("word/_rels/document.xml.rels","<?xml version=\"1.0\"?><Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"><Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/></Relationships>"))
        files.append(("word/styles.xml","<?xml version=\"1.0\" encoding=\"UTF-8\"?><w:styles xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii=\"Arial\" w:hAnsi=\"Arial\" w:eastAsia=\"Microsoft YaHei\"/><w:sz w:val=\"22\"/><w:color w:val=\"000000\"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after=\"140\" w:line=\"276\" w:lineRule=\"auto\"/></w:pPr></w:pPrDefault></w:docDefaults><w:style w:type=\"paragraph\" w:default=\"1\" w:styleId=\"Normal\"><w:name w:val=\"Normal\"/></w:style><w:style w:type=\"paragraph\" w:styleId=\"Title\"><w:name w:val=\"Title\"/><w:basedOn w:val=\"Normal\"/><w:pPr><w:keepNext/></w:pPr><w:rPr><w:b/><w:sz w:val=\"36\"/></w:rPr></w:style><w:style w:type=\"paragraph\" w:styleId=\"Heading1\"><w:name w:val=\"heading 1\"/><w:basedOn w:val=\"Normal\"/><w:pPr><w:keepNext/><w:spacing w:before=\"240\" w:after=\"140\"/></w:pPr><w:rPr><w:b/><w:sz w:val=\"26\"/></w:rPr></w:style><w:style w:type=\"paragraph\" w:styleId=\"Caption\"><w:name w:val=\"caption\"/><w:basedOn w:val=\"Normal\"/><w:rPr><w:sz w:val=\"18\"/></w:rPr></w:style></w:styles>"))
        files.append(("word/document.xml",document));return archive(files)
    }
    // Uncompressed ZIP records avoid external executables and preserve Unicode XML.
    static func archive(_ files:[(String,String)])->Data {
        var output=Data(),central=Data()
        func u16(_ value:UInt16,_ data:inout Data){data.append(UInt8(value&255));data.append(UInt8(value>>8))}
        func u32(_ value:UInt32,_ data:inout Data){u16(UInt16(value&65535),&data);u16(UInt16(value>>16),&data)}
        func crc(_ data:Data)->UInt32 {var c:UInt32=0xffffffff;for b in data{c ^= UInt32(b);for _ in 0..<8{c=(c>>1)^((c&1)==1 ? 0xedb88320:0)}};return c^0xffffffff}
        for (name,value) in files {
            let n=Data(name.utf8),data=Data(value.utf8),size=UInt32(data.count),checksum=crc(data),offset=UInt32(output.count)
            u32(0x04034b50,&output);for v:UInt16 in [20,0,0,0,33]{u16(v,&output)};u32(checksum,&output);u32(size,&output);u32(size,&output);u16(UInt16(n.count),&output);u16(0,&output);output.append(n);output.append(data)
            u32(0x02014b50,&central);for v:UInt16 in [20,20,0,0,0,33]{u16(v,&central)};u32(checksum,&central);u32(size,&central);u32(size,&central);u16(UInt16(n.count),&central);for _ in 0..<4{u16(0,&central)};u32(0,&central);u32(offset,&central);central.append(n)
        }
        let start=UInt32(output.count);output.append(central);u32(0x06054b50,&output);u16(0,&output);u16(0,&output);u16(UInt16(files.count),&output);u16(UInt16(files.count),&output);u32(UInt32(central.count),&output);u32(start,&output);u16(0,&output);return output
    }
}
