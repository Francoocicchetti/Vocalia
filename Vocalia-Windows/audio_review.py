"""Conservative mappings: never invent a word timestamp for edited text."""
import math
from core import layout, occurrences


def timed_words(doc):
    original, spans = layout(doc['segments'])
    for begin, end, segment in spans:
        body = original[begin:end]
        if doc['text'] != original:
            matches = occurrences(doc['text'], body)
            if len(matches) != 1:
                continue
            begin = matches[0]
        cursor, entries = 0, []
        for word in segment.get('words', []):
            literal = word['word'].strip()
            if not literal:
                continue
            found = body.find(literal, cursor)
            start, stop = word['start'], word['end']
            if (found < 0 or body[cursor:found].strip() or
                    not math.isfinite(start) or not math.isfinite(stop) or
                    start < 0 or stop <= start):
                entries = []
                break
            entries.append((begin + found, begin + found + len(literal), start, stop))
            cursor = found + len(literal)
        if not body[cursor:].strip():
            yield from entries


def word_at(doc, index):
    return next(((start, end) for a, b, start, end in timed_words(doc) if a <= index < b), None)


def selection_times(doc, start, end):
    if start >= end:
        return None
    entries = [entry for entry in timed_words(doc) if entry[0] < end and entry[1] > start]
    if not entries:
        return None
    # No unknown edited text or speaker names inside the selected range.
    cursor = start
    for a, b, _, _ in entries:
        if doc['text'][cursor:max(cursor, a)].strip():
            return None
        cursor = max(cursor, b)
    if doc['text'][cursor:end].strip():
        return None
    return entries[0][2], entries[-1][3]


def valid_loop(start, end):
    return all(math.isfinite(x) for x in (start, end)) and start >= 0 and end - start >= 0.08
