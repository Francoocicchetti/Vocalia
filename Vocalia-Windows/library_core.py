"""Local library search, metadata and portable Word export."""
import io,re,zipfile,datetime,html
from core import selection_match,timestamp

def normalized_tags(value):
    return list(dict.fromkeys(t.strip()[:80] for t in value.split(',') if t.strip()))[:30]

def library_search(documents, query='', project='', tag='', after='', before='', limit=200):
    results=[]
    for doc in documents:
        if project and doc.get('project','').casefold()!=project.casefold():continue
        if tag and not any(tag.casefold() in t.casefold() for t in doc.get('tags',[])):continue
        date=doc.get('recorded_date','')
        if after and date<after or before and (not date or date>before):continue
        text=doc.get('text','')
        if not query.strip():results.append(dict(id=doc['id'],name=doc['name'],excerpt=text[:160],start=None,end=None))
        else:
            matched=False
            for match in re.finditer(re.escape(query.strip()),text,re.IGNORECASE):
                matched=True
                timing=selection_match(doc,match.start(),match.end())
                results.append(dict(id=doc['id'],name=doc['name'],excerpt=text[max(0,match.start()-45):match.end()+100],start=timing['start'] if timing else None,end=timing['end'] if timing else None))
                if len(results)>=limit:return results
            if not matched and query.casefold() in doc['name'].casefold():results.append(dict(id=doc['id'],name=doc['name'],excerpt=doc['name'],start=None,end=None))
        if len(results)>=limit:return results[:limit]
    return results

def has_figures(segment):
    return any(c.isdecimal() for c in segment.get('text','')+segment.get('original_text',''))

def xml(value):
    return html.escape(''.join(c for c in str(value) if c in '\t\n\r' or 32<=ord(c)<=0xD7FF or 0xE000<=ord(c)<=0xFFFD or 0x10000<=ord(c)<=0x10FFFF),quote=True)

def word_document(doc,title,date,quotes,labels):
    def p(text,style='Normal'):
        return '<w:p><w:pPr><w:pStyle w:val="'+style+'"/></w:pPr><w:r><w:t xml:space="preserve">'+xml(text)+'</w:t></w:r></w:p>'
    body=p(title,'Title')+p(date)
    if doc.get('project'):body+=p(labels['project']+': '+doc['project'])
    if doc.get('tags'):body+=p(labels['tags']+': '+', '.join(doc['tags']))
    body+=p(labels['text'],'Heading1')
    body+=''.join(p(line) for line in doc.get('text','').splitlines())
    if quotes:
        body+=p(labels['quotes'],'Heading1')
        for q in quotes:
            body+=p(q['text'])+p(' · '.join(x for x in [q.get('speaker',''),doc['name'],timestamp(q['start'])[:-4]+'–'+timestamp(q['end'])[:-4]] if x),'Caption')
    document='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>'+body+'<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/></w:sectPr></w:body></w:document>'
    styles='''<?xml version="1.0" encoding="UTF-8"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:eastAsia="Microsoft YaHei"/><w:sz w:val="22"/><w:color w:val="000000"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="140" w:line="276" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style><w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/></w:pPr><w:rPr><w:b/><w:sz w:val="36"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:before="240" w:after="140"/></w:pPr><w:rPr><w:b/><w:sz w:val="26"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Caption"><w:name w:val="caption"/><w:basedOn w:val="Normal"/><w:rPr><w:sz w:val="18"/></w:rPr></w:style></w:styles>'''
    files={'[Content_Types].xml':'<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>', '_rels/.rels':'<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>','word/_rels/document.xml.rels':'<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>','word/document.xml':document,'word/styles.xml':styles}
    buffer=io.BytesIO()
    with zipfile.ZipFile(buffer,'w',zipfile.ZIP_DEFLATED) as archive:
        for name,value in files.items():archive.writestr(name,value.encode('utf-8'))
    return buffer.getvalue()
