import unittest
from advanced_core import apply_speakers,rename_speaker,edit_segment,comparison_rows
from core import new_document,transcript_text,playback_range,selection_match

class AdvancedTests(unittest.TestCase):
    def test_complete_catalog_and_placeholders(self):
        from i18n import CATALOG,LANGUAGES,tr,normalize
        from app import EN
        self.assertEqual({c for c,_ in LANGUAGES},{'en','es','de','fr','pt','zh'})
        for key,translations in CATALOG.items():
            for language in ('es','de','fr','pt','zh'):
                self.assertTrue(translations.get(language),key)
                self.assertEqual(key.count('%@'),translations[language].count('%@'),key)
        for key,value in EN.items():
            if key!='title':self.assertTrue(value in CATALOG,value)
        self.assertEqual(normalize('pt_BR'),'pt')
        self.assertEqual(tr('Full text','zh'),'完整文本')
    def document(self):
        d=new_document('interview.opus');d['segments']=[dict(start=0,end=4,text='Hello there.',words=[dict(start=0,end=1,word='Hello'),dict(start=2,end=4,word=' there.')])];d['text']='Hello there.';return d
    def test_speakers_split_align_and_rename(self):
        d=apply_speakers(self.document(),[dict(start=0,end=1.5,speaker='Speaker 1'),dict(start=2,end=4,speaker='Speaker 2')])
        self.assertEqual(len(d['segments']),2);self.assertEqual(d['text'],'Speaker 1: Hello\n\nSpeaker 2: there.')
        self.assertEqual(d['text'][slice(*playback_range(d,2.5))],'there.')
        i=d['text'].index('there');self.assertEqual(selection_match(d,i,i+6)['start'],2)
        d=rename_speaker(d,'Speaker 2','María');self.assertIn('María: there.',d['text'])
    def test_edited_prose_survives_analysis_and_review(self):
        d=self.document();d['text']='My independently edited quote'
        d=apply_speakers(d,[dict(start=0,end=4,speaker='Speaker 1')]);d=rename_speaker(d,'Speaker 1','Ana');d=edit_segment(d,0,'Correction','Ana',True)
        self.assertEqual(d['text'],'My independently edited quote');self.assertTrue(d['segments'][0]['reviewed'])
    def test_review_updates_unedited_full_text(self):
        d=edit_segment(self.document(),0,'Corrected','',True)
        self.assertEqual(d['text'],'Corrected');self.assertEqual(d['segments'][0]['original_text'],'Hello there.')
    def test_comparison_keeps_missing_and_different_sections(self):
        a=[dict(start=0,end=2,text='Hello.'),dict(start=22,end=25,text='world')]
        b=[dict(start=0,end=2,text='HELLO'),dict(start=23,end=26,text='another')]
        rows=comparison_rows(a,b);self.assertFalse(rows[0]['differs']);self.assertTrue(rows[1]['differs'])
    def test_overlapping_voices_are_not_claimed_certain(self):
        d=apply_speakers(self.document(),[dict(start=0,end=4,speaker='A'),dict(start=0,end=4,speaker='B')]);self.assertEqual(d['segments'][0]['speaker'],'Multiple speakers · review')

if __name__=='__main__':unittest.main()
