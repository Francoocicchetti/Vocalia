import sqlite3,tempfile,unittest
from pathlib import Path
from core import Store,new_document

class BulkStoreTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name);self.path=self.root/'history.sqlite3';self.store=Store(self.path)
        self.source=self.root/'source.opus';self.source.write_bytes(b'original')
        self.docs=[new_document(self.source),new_document('other.mp3'),new_document('keep.wav')]
        for i,doc in enumerate(self.docs):doc.update(text=f'Edited {i}',quotes=[dict(text='Quote',start=1,end=2)],project='Old');self.store.add(doc)
    def tearDown(self):self.store.close();self.temp.cleanup()
    def test_group_undo_after_restart_and_stale_editor(self):
        a,b,c=self.docs;self.store.remove_many([a['id'],b['id'],a['id'],'missing'])
        a['text']='Late';self.store.save(a)
        self.assertEqual([d['id'] for d in self.store.documents()],[c['id']])
        self.store.close();self.store=Store(self.path)
        self.assertEqual(self.store.undo_remove_many(),[a['id'],b['id']])
        self.assertEqual(self.store.get(a['id'])['text'],'Edited 0')
        self.assertEqual(self.store.get(b['id'])['quotes'],b['quotes'])
        self.assertEqual(self.source.read_bytes(),b'original')
        self.assertFalse(self.store.undo_remove_many())
    def test_distinct_groups_restore_last_first(self):
        a,b,c=self.docs;self.store.remove(a['id']);self.store.remove_many([b['id'],c['id']])
        self.assertFalse(self.store.documents());self.assertEqual(self.store.undo_remove_many(),[b['id'],c['id']]);self.assertIsNone(self.store.get(a['id']))
        self.assertEqual(self.store.undo_remove(),a['id'])
    def test_assignment_only_touches_selection(self):
        a,b,c=self.docs;self.store.assign_project([a['id'],b['id']],' News ')
        self.assertEqual(self.store.get(a['id'])['project'],'News');self.assertEqual(self.store.get(c['id']),c)
        self.store.assign_project([a['id']],'');self.assertEqual(self.store.get(a['id'])['project'],'')
    def test_removal_transaction_rolls_back(self):
        a,b,c=self.docs
        self.store.db.execute("CREATE TRIGGER fail_remove BEFORE UPDATE ON documents WHEN new.id='"+b['id']+"' BEGIN SELECT RAISE(ABORT,'failure'); END")
        with self.assertRaises(sqlite3.IntegrityError):self.store.remove_many([a['id'],b['id']])
        self.assertEqual(len(self.store.documents()),3);self.assertFalse(self.store.undo_remove_many())
