import unittest
from number_format import format_numbers,format_words
from core import transcript_text,playback_range,export_text

class NumberTests(unittest.TestCase):
    def test_decimal_formats_and_ambiguous_phrases(self):
        for original,expected in [['Fue 9, coma, 5 por ciento.', 'Fue 9,5 por ciento.'], ['nueve coma cinco', '9,5'], ['El 0 coma 05 %', 'El 0,05 %'], ['cero coma cero cinco', '0,05'], ['treinta y nueve coma cincuenta y cinco', '39,55'], ['-9 coma 5', '-9,5'], ['9,5 y 10,25', '9,5 y 10,25'], ['9, 5 y 3', '9, 5 y 3'], ['Ponga una coma entre 9 y 5.', 'Ponga una coma entre 9 y 5.'], ['ciento nueve coma cinco', 'ciento nueve coma cinco'], ['mil nueve coma cinco', 'mil nueve coma cinco'], ['9 coma\n5', '9 coma\n5'], ['9 coma 5 y después 10 coma 2', '9,5 y después 10,2'], ['9 coma cinco y medio', '9 coma cinco y medio'], ['dieciséis coma veintidós', '16,22']]:
            with self.subTest(original=original):
                self.assertEqual(format_numbers(original,'es-CL'),expected)
                self.assertEqual(format_numbers(original,'en'),original)
                self.assertEqual(format_numbers(expected,'es-CL'),expected)
    def test_amounts_percentages_and_large_digit_values(self):
        cases=[('Subió 12 coma 75 por ciento.','Subió 12,75 por ciento.'),('$1234567, coma, 005','$1234567,005'),('Fue 100 coma 0 millones.','Fue 100,0 millones.'),('16/09/2026; 12:30; 1.500 pesos','16/09/2026; 12:30; 1.500 pesos')]
        for original,expected in cases:self.assertEqual(format_numbers(original,'es'),expected)
    def test_timing_copy_and_exports(self):
        words=[dict(word=' 9,',start=1,end=2),dict(word=' coma,',start=2,end=3),dict(word=' 5',start=3,end=4),dict(word=' pesos',start=4,end=5)]
        result=format_words(words,'es')
        self.assertEqual(result,[dict(word=' 9,5',start=1,end=4),dict(word=' pesos',start=4,end=5)])
        self.assertEqual(words[1]['word'],' coma,')
        segment=dict(text='9,5 pesos',original_text='9, coma, 5 pesos',start=1,end=5,words=result)
        doc=dict(text=transcript_text([segment]),segments=[segment])
        self.assertEqual(playback_range(doc,2.5),(0,3))
        self.assertIn('9,5 pesos',export_text(doc,'srt'))
        self.assertEqual(export_text(doc),'9,5 pesos')
    def test_two_decimals_in_one_timed_token(self):
        tokens=[dict(word='9 coma 5 y 8 coma 2',start=0,end=8)]
        self.assertEqual(format_words(tokens,'es')[0]['word'],'9,5 y 8,2')
