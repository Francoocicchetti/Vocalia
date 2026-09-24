"""Packaged-worker regression: independent comparison and real four-speaker diarization.
Only public fixtures are used. Downloads models first, then runs recognition offline.
"""
import hashlib,json,os,subprocess,sys,tempfile,urllib.request
from pathlib import Path
with tempfile.TemporaryDirectory(prefix='VocaliaAdvancedTest-') as folder:
    root=Path(folder);models=Path(os.environ.get('VOCALIA_TEST_MODELS',str(root/'Models'))).resolve()
    command=[sys.argv[1]] if len(sys.argv)>1 else [sys.executable,str(Path(__file__).with_name('app.py'))]
    def job(task,**kwargs):
        d=root/str(len(list(root.iterdir())));d.mkdir()
        (d/'job.json').write_text(json.dumps(dict(task=task,models=str(models),**kwargs)),encoding='utf8')
        p=subprocess.run(command+['--worker',str(d/'job.json')],timeout=900)
        events=(d/'events.jsonl').read_text(encoding='utf8') if (d/'events.jsonl').exists() else 'No worker events'
        assert p.returncode==0 and (d/'result.json').exists(),events
        return json.loads((d/'result.json').read_text(encoding='utf8')),events
    job('prepare',model='tiny.en')
    fixture=Path(__file__).with_name('test-speech.flac').resolve()
    result,events=job('compare',model='tiny.en',source=str(fixture),language='en',terms=[])
    assert 'country' in ' '.join(s['text'] for s in result['segments']).lower()
    assert not any(json.loads(line)['kind']=='segment' for line in events.splitlines())
    print('PASS: independent comparison recognizes speech offline without publishing primary-transcript events',flush=True)
    voice=root/'four-speakers.wav'
    urllib.request.urlretrieve('https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-segmentation-models/0-four-speakers-zh.wav',voice)
    assert hashlib.sha256(voice.read_bytes()).hexdigest()=='bedf036caed208386c67b4ef4b11f83d74dd0d420b102163a1c33cd09cde7010'
    job('prepare_voices')
    result,events=job('voices',source=str(voice),speaker_count=4)
    assert len({t['speaker'] for t in result['turns']})==4,result
    assert all(0<=t['start']<t['end']<=57 for t in result['turns'])
    print('PASS: packaged CPU speaker engine returns timed turns for four public-fixture speakers',flush=True)
