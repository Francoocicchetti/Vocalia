"""Review, comparison and speaker metadata; never silently replace edited prose."""
import copy
import re
from core import transcript_text, timestamp


def comparison_rows(first, second, seconds=20):
    end = max([s['end'] for s in first + second] or [0])
    rows = []
    for start in range(0, int(end) + 1, seconds):
        a = transcript_text([s for s in first if start <= s['start'] < start + seconds])
        b = transcript_text([s for s in second if start <= s['start'] < start + seconds])
        if not a and not b:continue
        normal = lambda text: re.sub(r'\W+', '', text.casefold())
        rows.append(dict(start=start, end=min(end, start+seconds), first=a, second=b, differs=normal(a)!=normal(b)))
    return rows


def speaker_at(start, end, turns):
    scores={}
    for turn in turns:
        overlap=max(0,min(end,turn['end'])-max(start,turn['start']))
        scores[turn['speaker']]=scores.get(turn['speaker'],0)+overlap
    ranked=sorted(scores.items(),key=lambda item:item[1],reverse=True)
    if not ranked or ranked[0][1]<=0:return ''
    if len(ranked)>1 and ranked[1][1]>max(0.15,(end-start)*0.3):return 'Multiple speakers · review'
    return ranked[0][0]


def apply_speakers(doc, turns):
    result = copy.deepcopy(doc)
    generated=doc['text']==transcript_text(doc['segments'])
    result['speaker_turns'] = turns
    segments=[]
    normal=lambda text: re.sub(r'\W+','',text.casefold())
    for segment in result['segments']:
        words=segment.get('words',[])
        if words and normal(''.join(w['word'] for w in words))==normal(segment['text']):
            groups=[]
            for word in words:
                label=speaker_at(word['start'],word['end'],turns)
                if groups and groups[-1][0]==label:groups[-1][1].append(word)
                else:groups.append((label,[word]))
            if len(groups)>1:
                for label,group in groups:
                    part=copy.deepcopy(segment);text=''.join(w['word'] for w in group).strip()
                    part.update(start=group[0]['start'],end=group[-1]['end'],words=group,text=text,original_text=text,speaker=label)
                    segments.append(part)
                continue
        segment['speaker']=speaker_at(segment['start'],segment['end'],turns);segments.append(segment)
    result['segments']=segments
    if generated:result['text']=transcript_text(segments)
    for quote in result.get('quotes',[]):
        if not quote.get('speaker') or quote.get('automatic_speaker'):
            quote['speaker'] = speaker_at(quote['start'],quote['end'],turns)
            quote['automatic_speaker'] = True
    return result


def rename_speaker(doc, old, new):
    result = copy.deepcopy(doc)
    generated=doc['text']==transcript_text(doc['segments'])
    new = new.strip()
    if not old or not new:return result
    for items in ('segments','quotes','speaker_turns'):
        for item in result.get(items,[]):
            if item.get('speaker') == old:item['speaker'] = new
    if generated:result['text']=transcript_text(result['segments'])
    return result


def edit_segment(doc, index, text, speaker, reviewed):
    result = copy.deepcopy(doc)
    old_generated = transcript_text(result['segments'])
    segment = result['segments'][index]
    segment.setdefault('original_text',segment['text'])
    segment.update(text=text,speaker=speaker.strip(),reviewed=bool(reviewed))
    # An independently edited full transcript is authoritative and must survive review.
    if result['text'] == old_generated:result['text'] = transcript_text(result['segments'])
    return result


def quote_citation(quote):
    return f"{quote['text']}\n\n{quote.get('speaker','')} · {quote.get('source','')} · {timestamp(quote['start'])}–{timestamp(quote['end'])}"
