import os
os.environ.setdefault('QT_QPA_PLATFORM', 'offscreen')
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from PySide6.QtCore import QObject, Signal, Qt
from PySide6.QtGui import QTextCursor
from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel
from PySide6.QtMultimedia import QMediaPlayer
from PySide6.QtTest import QTest
from audio_ui import AudioReviewUI, TranscriptEdit
from core import Store, new_document


class Media(QObject):
    mediaStatusChanged=Signal(object)
    def __init__(self):
        super().__init__(); self.position=0; self.state=QMediaPlayer.PlaybackState.PlayingState
    def setPosition(self, value):self.position=value
    def play(self):self.state=QMediaPlayer.PlaybackState.PlayingState
    def pause(self):self.state=QMediaPlayer.PlaybackState.PausedState
    def playbackState(self):return self.state


class AudioUITests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.app=QApplication.instance() or QApplication([])
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.store=Store(self.root/'test.sqlite3')
        self.doc=new_document(self.root/'original.wav')
        self.doc.update(text='Ana dijo 9,5.',segments=[dict(text='Ana dijo 9,5.',start=1,end=4,words=[dict(word='Ana',start=1,end=1.4),dict(word=' dijo',start=1.5,end=2),dict(word=' 9,5.',start=3,end=4)])])
        self.store.add(self.doc)
        self.widget=QWidget();layout=QVBoxLayout(self.widget)
        self.editor=TranscriptEdit();self.editor.setPlainText(self.doc['text']);layout.addWidget(self.editor)
        self.plays=[];self.jobs=[]
        self.w=SimpleNamespace(editor=self.editor, media=Media(),store=self.store,selected=self.doc['id'],language='es',status=QLabel(),proc=None,flush_edit=lambda:None,play=lambda *args:self.plays.append(args),launch=lambda job:self.jobs.append(job))
        self.ui=AudioReviewUI(self.w,layout,self.root);self.ui.retranslate()
    def tearDown(self):self.widget.close();self.store.close();self.temp.cleanup()
    def test_word_click_and_edit_mode(self):
        self.widget.show();QTest.qWait(20)
        c=self.editor.textCursor();c.setPosition(9)
        point=self.editor.cursorRect(c).center()
        QTest.mouseClick(self.editor.viewport(),Qt.MouseButton.LeftButton,pos=point)
        self.assertEqual(self.plays[-1],(3,))
        self.ui.click.setChecked(False);self.plays.clear()
        QTest.mouseClick(self.editor.viewport(),Qt.MouseButton.LeftButton,pos=point)
        self.assertFalse(self.plays)
    def test_loop_pause_eof_and_document_reset(self):
        c=self.editor.textCursor();c.setPosition(4);c.setPosition(12,QTextCursor.MoveMode.KeepAnchor);self.editor.setTextCursor(c)
        self.ui.repeat_selection();self.assertEqual(self.ui.loop,(1.5,4))
        self.ui.position(4100);self.assertEqual(self.w.media.position,1500)
        self.w.media.pause();self.w.media.position=0;self.ui.position(4100);self.assertEqual(self.w.media.position,0)
        self.ui.media_status(QMediaPlayer.MediaStatus.EndOfMedia);self.assertEqual(self.w.media.position,1500)
        self.ui.reset();self.assertIsNone(self.ui.loop);self.assertFalse(self.ui.repeat.isChecked())
    def test_clean_is_explicit_and_keeps_source(self):
        self.assertEqual(self.ui.source(self.doc),self.doc['source'])
        self.ui.prepare_clean();self.assertEqual(self.jobs[0]['task'],'clean')
        self.assertNotEqual(self.jobs[0]['source'],self.jobs[0]['destination'])
        self.assertEqual(self.store.get(self.doc['id'])['text'],'Ana dijo 9,5.')
        target=self.root/'clean.wav';target.touch();self.doc['cleaned_source']=str(target)
        self.ui.use_clean.setChecked(True);self.assertEqual(self.ui.source(self.doc),str(target))
