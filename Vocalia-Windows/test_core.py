import tempfile
import unittest
from pathlib import Path
from core import *


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.store = Store(self.root/'history.sqlite3')
        self.doc = new_document('audio.mp3')
        self.doc['segments'] = [dict(start=0,end=2,text='Hola Chile',words=[dict(start=0,end=1,word='Hola'),dict(start=1,end=2,word=' Chile')]),dict(start=3,end=5,text='Otra frase.')]
        self.doc['text'] = transcript_text(self.doc['segments'])
        self.store.add(self.doc)

    def tearDown(self):
        self.store.close();self.tmp.cleanup()

    def test_opus_import(self):
        folder=self.root/'Notas de voz';folder.mkdir()
        for name in ['entrevista.opus','OTRA.OPUS','nota.ogg']:(folder/name).write_bytes(b'test')
        files=collect_files([str(folder)])
        self.assertEqual(len(files),3)
        self.assertTrue(any(p.endswith('.OPUS') for p in files))

    def test_full_text(self):self.assertEqual(self.doc['text'],'Hola Chile Otra frase.')
    def test_copy_preserves_edit(self):
        self.doc['text']='Cita editada';self.assertEqual(export_text(self.doc),'Cita editada')
    def test_subtitle_timing(self):self.assertIn('00:00:00,000 --> 00:00:02,000',export_text(self.doc,'srt'))
    def test_vtt(self):self.assertTrue(export_text(self.doc,'vtt').startswith('WEBVTT\n'))
    def test_long_time(self):self.assertEqual(timestamp(3661.2),'01:01:01,200')
    def test_select_across_segments(self):
        match=selection_match(self.doc,5,15);self.assertEqual(match['text'],'Chile Otra');self.assertEqual((match['start'],match['end']),(0,5))
    def test_invalid_selection(self):self.assertIsNone(selection_match(self.doc,-1,200))
    def test_edited_quote(self):
        self.doc['text']='Título: Hola Chile';match=selection_match(self.doc,8,18);self.assertEqual(match['start'],0)
    def test_rewritten_quote(self):
        self.doc['text']='Palabras añadidas';self.assertIsNone(selection_match(self.doc,0,8))
    def test_word_highlight(self):self.assertEqual(playback_range(self.doc,1.5),(5,10))
    def test_silence(self):self.assertIsNone(playback_range(self.doc,2.5))
    def test_fragment_highlight(self):self.assertEqual(playback_range(self.doc,3.5),(11,22))
    def test_highlight_after_edit(self):
        self.doc['text']='Intro: '+self.doc['text'];self.assertEqual(playback_range(self.doc,1.5),(12,17))
    def test_ambiguous_edited_highlight(self):
        self.doc['text']='Hola Chile Hola Chile';self.assertIsNone(playback_range(self.doc,1))
    def test_utf16(self):
        text='😀 Perú';self.assertEqual(qt_index(text,2),3);self.assertEqual(python_index(text,3),2)
    def test_remove_stale_save(self):
        self.store.remove(self.doc['id']);self.doc['text']='late';self.store.save(self.doc);self.assertIsNone(self.store.get(self.doc['id']))
    def test_undo(self):
        self.store.remove(self.doc['id']);self.store.undo_remove();self.assertEqual(self.store.get(self.doc['id'])['text'],self.doc['text'])
    def test_deleted_editor_does_not_change_next(self):
        second=new_document('second.mp3');self.store.add(second);self.store.remove(self.doc['id']);self.doc['text']='stale';self.store.save(self.doc)
        self.assertEqual(self.store.get(second['id'])['text'],'')
    def test_restart_preserves_history(self):
        self.store.close();self.store=Store(self.root/'history.sqlite3');self.assertEqual(self.store.get(self.doc['id']),self.doc)
    def test_settings(self):
        self.store.set_setting('dictionary',['Ñuñoa']);self.assertEqual(self.store.setting('dictionary'),['Ñuñoa'])
    def test_bulk_import(self):
        sub=self.root/'many';sub.mkdir()
        for i in range(120):(sub/f'{i}.mp3').write_bytes(b'x')
        (sub/'ignore.txt').write_text('test')
        self.assertEqual(len(collect_files([sub,sub/'1.mp3'])),120)
    def test_limit(self):
        for i in range(5):(self.root/f'{i}.mp4').write_bytes(b'x')
        self.assertEqual(len(collect_files([self.root],limit=3)),3)
    def test_atomic_json(self):
        file=self.root/'job.json';atomic_json(file,{'text':'Prueba ñ'});self.assertEqual(json.loads(file.read_text(encoding='utf-8'))['text'],'Prueba ñ')
    def test_corrupt_history_not_overwritten(self):
        file=self.root/'corrupt.sqlite';file.write_bytes(b'not a database')
        with self.assertRaises(sqlite3.DatabaseError):Store(file)
        self.assertEqual(file.read_bytes(),b'not a database')


if __name__=='__main__':unittest.main()
