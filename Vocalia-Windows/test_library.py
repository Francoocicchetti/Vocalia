import unittest,io,zipfile,xml.etree.ElementTree as ET,json,tempfile
from pathlib import Path
from core import new_document,Store,transcript_text
from library_core import library_search,normalized_tags,has_figures,word_document
from updates import choose_release,REPOSITORY
class LibraryTests(unittest.TestCase):
    def doc(self):
        d=new_document('/private/interview.opus');d.update(segments=[dict(text='El presupuesto es 9,5 millones.',start=2,end=6),dict(text='La entrevista continúa.',start=7,end=9)],project='Municipio',tags=['salud','Chile'],recorded_date='2026-09-17');d['text']=transcript_text(d['segments']);return d
    def test_search_phrase_case_and_cross_segment(self):
        d=self.doc();hits=library_search([d],'PRESUPUESTO');self.assertEqual((hits[0]['start'],hits[0]['end']),(2,6))
        hits=library_search([d],'millones. La entrevista');self.assertEqual((hits[0]['start'],hits[0]['end']),(2,9))
    def test_edited_text_without_reliable_time(self):
        d=self.doc();d['text']='Cambió a diez millones.';h=library_search([d],'diez')[0];self.assertIsNone(h['start'])
    def test_filters_limit_duplicate_occurrences_and_legacy(self):
        d=self.doc();self.assertEqual(len(library_search([d],project='municipio',tag='CHI',after='2026-09-01',before='2026-09-30')),1)
        self.assertFalse(library_search([d],project='Other'));self.assertFalse(library_search([d],after='2026-10-01'))
        d['text']='hola '*300;self.assertEqual(len(library_search([d],'hola')),200)
        old=dict(id='legacy',name='old',text='',segments=[]);self.assertEqual(len(library_search([old])),1)
    def test_metadata_roundtrip_removal_and_preserved_text(self):
        with tempfile.TemporaryDirectory() as p:
            s=Store(Path(p)/'history.db');d=self.doc();s.add(d);d['tags']=normalized_tags(' prensa, Chile, prensa, ');s.save(d);s.close();s=Store(Path(p)/'history.db');self.assertEqual(s.get(d['id']),d);s.remove(d['id']);self.assertFalse(library_search(s.documents()));s.undo_remove();self.assertEqual(s.get(d['id']),d);s.close()
    def test_figure_filter_preserves_corrected_original(self):
        self.assertTrue(has_figures(dict(text='nueve',original_text='9')));self.assertTrue(has_figures(dict(text='９，５')));self.assertFalse(has_figures(dict(text='Sin cifras.')))
    def test_word_content_styles_and_selected_quotes(self):
        d=self.doc();d['text']='Texto editado & <completo>\n中文\x00';q=dict(text='Cuña elegida',speaker='Ana',start=2,end=6)
        data=word_document(d,'Entrevista municipal','2026-09-17',[q],dict(project='Proyecto',tags='Etiquetas',text='Transcripción completa',quotes='Cuñas seleccionadas'))
        z=zipfile.ZipFile(io.BytesIO(data));self.assertIsNone(z.testzip())
        for name in z.namelist():ET.fromstring(z.read(name))
        xml=z.read('word/document.xml').decode();self.assertIn('Texto editado &amp; &lt;completo&gt;',xml);self.assertIn('Cuña elegida',xml);self.assertIn('00:00:02–00:00:06',xml);self.assertNotIn('/private/',xml)
        self.assertIn('w:val="Title"',xml);self.assertIn('w:val="Heading1"',xml)
    def release(self,tag='v0.0.7',date='2026-09-18T12:00:00Z'):
        filename='Vocalia-'+tag[1:]+'-Windows-x64-Setup.exe'
        return dict(tag_name=tag,published_at=date,draft=False,prerelease=True,html_url=REPOSITORY+'/releases/tag/'+tag,body='Changes',assets=[dict(name=filename,browser_download_url=REPOSITORY+'/releases/download/'+tag+'/'+filename)])
    def test_update_version_reset_and_trusted_links(self):
        self.assertEqual(choose_release([self.release()])['version'],'0.0.7')
        self.assertIsNone(choose_release([self.release('v1.0.4','2026-09-16T20:00:00Z')]))
        self.assertIsNone(choose_release([self.release('v0.0.6')]))
        r=self.release();r['assets'][0]['browser_download_url']='https://malicious.example/setup.exe';self.assertIsNone(choose_release([r]))
        r=self.release();r['draft']=True;self.assertIsNone(choose_release([r]))
        self.assertEqual(choose_release([self.release(),self.release('v0.0.10')])['version'],'0.0.10')
if __name__=='__main__':unittest.main()
