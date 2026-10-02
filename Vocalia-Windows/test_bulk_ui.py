import os
os.environ.setdefault('QT_QPA_PLATFORM','offscreen')
import tempfile,unittest,zipfile
from pathlib import Path
from unittest.mock import patch
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication,QWidget,QVBoxLayout,QListWidget,QListWidgetItem,QLabel,QMessageBox
from core import Store,new_document
from bulk_ui import BulkUI

class BulkUITests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.app=QApplication.instance() or QApplication([])
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.w=QWidget();self.w.language='en';self.w.store=Store(self.root/'history.db');self.w.list=QListWidget();self.w.status=QLabel();self.w.flush_edit=lambda:None
        self.ui=BulkUI(self.w,QVBoxLayout(self.w));self.w.refresh=lambda:None
        self.a=new_document('one.mp3');self.a.update(text='Edited text',segments=[dict(start=1,end=2,text='Timed text')],quotes=[])
        self.b=new_document('other.opus');self.b['text']='Do not export'
        for doc in (self.a,self.b):
            self.w.store.add(doc);row=QListWidgetItem(doc['name']);row.setData(Qt.ItemDataRole.UserRole,doc['id']);self.w.list.addItem(row);self.ui.configure(row)
        self.ui.ids={self.a['id']};self.ui.retranslate()
    def tearDown(self):self.w.store.close();self.w.close();self.w.list.close();self.temp.cleanup()
    def test_menu_exports_selected_only_and_keeps_existing_files(self):
        (self.root/'one.txt').write_text('Existing export')
        with patch('bulk_ui.QFileDialog.getExistingDirectory',return_value=str(self.root)):
            for action,label in self.ui.actions:
                if label.startswith('Export selection:'):action.trigger()
        self.assertEqual((self.root/'one.txt').read_text(),'Existing export')
        self.assertEqual((self.root/'one (1).txt').read_text(),'Edited text')
        self.assertIn('00:00:01,000', (self.root/'one.srt').read_text())
        self.assertTrue((self.root/'one.vtt').read_text().startswith('WEBVTT'))
        with zipfile.ZipFile(self.root/'one.docx') as z:self.assertIn(b'Edited text',z.read('word/document.xml'))
        self.assertFalse((self.root/'other.txt').exists())
    def test_cancel_removal_and_project_scope(self):
        removed=[];self.w.remove_ids=lambda ids:removed.extend(ids)
        with patch('bulk_ui.QMessageBox.question',return_value=QMessageBox.StandardButton.No):self.ui.remove([self.a['id']])
        self.assertFalse(removed)
        with patch('bulk_ui.QInputDialog.getText',return_value=('News',True)):self.ui.project()
        self.assertEqual(self.w.store.get(self.a['id'])['project'],'News');self.assertEqual(self.w.store.get(self.b['id'])['project'],'')
    def test_select_all_clear_and_busy(self):
        self.ui.select(True);self.assertEqual(len(self.ui.selected_ids()),2)
        self.ui.set_busy(True);self.ui.select(False);self.assertEqual(len(self.ui.selected_ids()),2);self.assertFalse(self.ui.button.isEnabled())
        self.ui.set_busy(False);self.ui.select(False);self.assertFalse(self.ui.selected_ids());self.assertFalse(self.ui.button.isEnabled())

    def test_transcribe_actions_use_checked_ids(self):
        from types import SimpleNamespace
        pending=[];queued=[]
        self.w.start_ids=lambda ids:pending.extend(ids)
        self.w.audio_review=SimpleNamespace(root=self.root)
        self.w.model=SimpleNamespace(currentText=lambda:'tiny')
        self.w.t=lambda key:key
        self.w.next_job=lambda:queued.extend(self.w.queue)
        (self.root/'Models').mkdir();(self.root/'Models'/'tiny.ready').touch()
        self.ui.actions[0][0].trigger();self.assertEqual(pending,[self.a['id']])
        with patch('bulk_ui.QMessageBox.question',return_value=QMessageBox.StandardButton.Yes):self.ui.actions[1][0].trigger()
        self.assertEqual(queued,[self.a['id']])
