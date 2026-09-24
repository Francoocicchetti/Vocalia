import hashlib
import math
from pathlib import Path
import tempfile
import unittest
import wave
from array import array
from audio_review import word_at, selection_times, valid_loop
from audio_clean import RumbleFilter, normalization_gain, clean_audio


def document():
    return {'text':'Ana dijo 9,5.', 'segments':[{'start':1, 'end':4, 'text':'Ana dijo 9,5.', 'words':[
        {'word':'Ana','start':1,'end':1.4}, {'word':' dijo','start':1.5,'end':2}, {'word':' 9,5.','start':3,'end':4}]}]}


class AudioReviewTests(unittest.TestCase):
    def test_exact_word_and_selection(self):
        doc=document()
        self.assertEqual(word_at(doc,9),(3,4))
        self.assertEqual(selection_times(doc,4,13),(1.5,4))
        self.assertIsNone(word_at(doc,3))
        self.assertIsNone(word_at(doc,99))

    def test_repeated_word_maps_to_its_occurrence(self):
        doc={'text':'sí sí', 'segments':[{'text':'sí sí','start':0,'end':5,'words':[{'word':'sí','start':1,'end':2},{'word':' sí','start':3,'end':4}]}]}
        self.assertEqual(word_at(doc,3),(3,4))

    def test_edits_and_missing_timing_never_guess(self):
        doc=document();doc['text']='Ana dijo 19,5.'
        self.assertIsNone(word_at(doc,9))
        doc=document();doc['segments'][0]['words']=[]
        self.assertIsNone(word_at(doc,0))

    def test_ambiguous_edited_segments(self):
        doc=document();doc['text']='Ana dijo 9,5. Ana dijo 9,5.'
        self.assertIsNone(word_at(doc,0))
        doc=document();doc['text']='Título\nAna dijo 9,5.'
        self.assertEqual(word_at(doc,7),(1,1.4))
        self.assertIsNone(selection_times(doc,0,len(doc['text'])))

    def test_unicode_and_bad_timestamps(self):
        doc={'text':'记者 😀', 'segments':[{'start':0,'end':3,'text':'记者 😀','words':[{'word':'记者','start':1,'end':2},{'word':' 😀','start':2,'end':3}]}]}
        self.assertEqual(word_at(doc,3),(2,3))
        doc['segments'][0]['words'][0]['start']=float('nan')
        self.assertIsNone(word_at(doc,0))
        self.assertFalse(valid_loop(1,1));self.assertFalse(valid_loop(0,float('inf')))
        self.assertTrue(valid_loop(3,4))

    def test_filter_reduces_rumble_preserves_voice_band(self):
        def level(frequency):
            f=RumbleFilter()
            values=f.process(math.sin(2*math.pi*frequency*i/16000) for i in range(32000))
            return math.sqrt(sum(x*x for x in values[16000:])/16000)
        self.assertLess(level(20)/level(1000),0.35)
        self.assertGreater(level(1000),0.65)
        self.assertEqual(normalization_gain(0),1)
        self.assertLessEqual(normalization_gain(0.01),2)

    def test_clean_copy_keeps_duration_and_original(self):
        with tempfile.TemporaryDirectory() as folder:
            source=Path(folder)/'source.wav';target=Path(folder)/'clean.wav'
            with wave.open(str(source),'wb') as f:
                f.setparams((1,2,16000,0,'NONE','not compressed'))
                f.writeframes(array('h',(round(3000*math.sin(i*2*math.pi*1000/16000)+3000*math.sin(i*2*math.pi*20/16000)) for i in range(32000))).tobytes())
            digest=hashlib.sha256(source.read_bytes()).hexdigest()
            clean_audio(source,target)
            self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(),digest)
            with wave.open(str(target)) as f:
                self.assertEqual(f.getnframes(),32000)
                samples=array('h');samples.frombytes(f.readframes(32000))
                self.assertLessEqual(max(map(abs,samples)),round(.951*32767))
            with self.assertRaises(ValueError):clean_audio(source,source)

    def test_failed_clean_leaves_no_output(self):
        with tempfile.TemporaryDirectory() as folder:
            source=Path(folder)/'bad.opus';source.write_bytes(b'not audio')
            target=Path(folder)/'clean.wav'
            with self.assertRaises(Exception):clean_audio(source,target)
            self.assertFalse(target.exists())
            self.assertEqual(sorted(x.name for x in Path(folder).iterdir()),['bad.opus'])
