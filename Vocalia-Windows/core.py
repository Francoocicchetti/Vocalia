"""Platform-independent data model. No audio or GUI dependencies."""
import json
import os
import sqlite3
import uuid
import time
from pathlib import Path

EXTENSIONS = {'.mp3', '.mp4', '.mov', '.m4a', '.wav', '.flac', '.aac', '.aiff', '.aif', '.caf', '.m4v', '.opus', '.ogg'}


def collect_files(inputs, limit=10000):
    result, seen = [], set()
    for name in inputs:
        path = Path(name)
        if path.is_symlink():
            continue
        paths = path.rglob('*') if path.is_dir() else [path]
        for candidate in paths:
            if candidate.is_symlink() or not candidate.is_file() or candidate.suffix.lower() not in EXTENSIONS:
                continue
            canonical = str(candidate.resolve())
            key = os.path.normcase(canonical)
            if key not in seen:
                seen.add(key)
                result.append(canonical)
                if len(result) >= limit:
                    return sorted(result)
    return sorted(result)


def new_document(path):
    return dict(id=str(uuid.uuid4()), source=str(path), name=Path(path).name,
                recorded_date=__import__('datetime').date.today().isoformat(), project='', tags=[], status='pending', segments=[], text='', quotes=[], language='es', complete=False)


def transcript_text(segments):
    return layout(segments)[0]


def timestamp(seconds, separator=','):
    ms = max(0, round(seconds * 1000))
    hours, ms = divmod(ms, 3600000)
    minutes, ms = divmod(ms, 60000)
    sec, ms = divmod(ms, 1000)
    return f'{hours:02}:{minutes:02}:{sec:02}{separator}{ms:03}'


def export_text(doc, kind='txt'):
    if kind == 'txt':
        return doc['text']
    if kind not in ('srt', 'vtt'):
        raise ValueError('Unknown export format')
    rows = ['WEBVTT\n'] if kind == 'vtt' else []
    for i, segment in enumerate(doc['segments'], 1):
        separator = '.' if kind == 'vtt' else ','
        rows.append(f"{i}\n{timestamp(segment['start'], separator)} --> {timestamp(segment['end'], separator)}\n{segment['text'].strip()}\n")
    return '\n'.join(rows)


def layout(segments):
    text, spans, previous = '', [], None
    for segment in segments:
        body = segment['text'].strip()
        if not body:
            continue
        speaker = segment.get('speaker','')
        if previous is None or speaker != previous:
            if text:text += '\n\n'
            if speaker:text += speaker + ': '
        elif text:text += ' '
        previous = speaker
        start = len(text)
        text += body
        spans.append((start, len(text), segment))
    return text, spans


def occurrences(text, needle):
    if not needle:
        return []
    result, start = [], 0
    while len(result) < 2:
        index = text.find(needle, start)
        if index < 0:
            break
        result.append(index)
        start = index + len(needle)
    return result


def selection_match(doc, start, end):
    text = doc['text']
    if not 0 <= start < end <= len(text):
        return None
    literal = text[start:end]
    if not literal.strip():
        return None
    original, spans = layout(doc['segments'])
    if text != original:
        matches = occurrences(original, literal)
        if len(matches) != 1:
            return None
        start, end = matches[0], matches[0] + len(literal)
    matched = [s for a, b, s in spans if a < end and b > start]
    if not matched:
        return None
    return dict(text=literal, start=matched[0]['start'], end=matched[-1]['end'])


def playback_range(doc, seconds):
    original, spans = layout(doc['segments'])
    for begin, end, s in spans:
        if not s['start'] <= seconds < s['end']:
            continue
        body = original[begin:end]
        if doc['text'] != original:
            matches = occurrences(doc['text'], body)
            if len(matches) != 1:
                return None
            begin = matches[0]
        position = 0
        active = None
        for word in s.get('words', []):
            content = word['word'].strip()
            if not content:
                continue
            found = body.find(content, position)
            if found < 0 or body[position:found].strip():
                return (begin, begin + len(body))
            if word['start'] <= seconds < word['end']:
                active = (begin + found, begin + found + len(content))
            position = found + len(content)
        if s.get('words') and not body[position:].strip() and active:
            return active
        return (begin, begin + len(body))
    return None


def qt_index(text, index):
    return len(text[:index].encode('utf-16-le')) // 2


def python_index(text, position):
    return len(text.encode('utf-16-le')[:position * 2].decode('utf-16-le', errors='ignore'))


def atomic_json(path, value):
    path = Path(path)
    temporary = path.with_suffix(path.suffix + '.tmp')
    with temporary.open('w', encoding='utf-8') as stream:
        json.dump(value, stream, ensure_ascii=False)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


class Store:
    def __init__(self, path):
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(path)
        try:
            self.db.execute('PRAGMA journal_mode=WAL')
            self.db.execute('PRAGMA synchronous=FULL')
            self.db.execute('CREATE TABLE IF NOT EXISTS documents (id TEXT PRIMARY KEY, data TEXT NOT NULL, removed INTEGER NOT NULL DEFAULT 0)')
            self.db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)')
            self.db.commit()
        except Exception:
            self.db.close()
            raise

    def documents(self):
        return [json.loads(row[0]) for row in self.db.execute('SELECT data FROM documents WHERE removed=0 ORDER BY rowid')]

    def get(self, ident):
        row = self.db.execute('SELECT data FROM documents WHERE id=? AND removed=0', (ident,)).fetchone()
        return json.loads(row[0]) if row else None

    def add(self, doc):
        with self.db:
            self.db.execute('INSERT INTO documents(id,data) VALUES(?,?)', (doc['id'], json.dumps(doc, ensure_ascii=False)))

    def save(self, doc):
        # A delayed editor callback cannot resurrect a removed recording.
        with self.db:
            self.db.execute('UPDATE documents SET data=? WHERE id=? AND removed=0', (json.dumps(doc, ensure_ascii=False), doc['id']))

    def remove(self, ident):
        with self.db:
            self.db.execute('UPDATE documents SET removed=? WHERE id=? AND removed=0', (time.time_ns(), ident))

    def undo_remove(self):
        row = self.db.execute('SELECT id FROM documents WHERE removed>0 ORDER BY removed DESC, rowid DESC LIMIT 1').fetchone()
        if row:
            with self.db:
                self.db.execute('UPDATE documents SET removed=0 WHERE id=?', row)
            return row[0]

    def setting(self, key, fallback=None):
        row = self.db.execute('SELECT value FROM settings WHERE key=?', (key,)).fetchone()
        return json.loads(row[0]) if row else fallback

    def set_setting(self, key, value):
        with self.db:
            self.db.execute('INSERT OR REPLACE INTO settings VALUES(?,?)', (key, json.dumps(value)))

    def close(self):
        self.db.close()
