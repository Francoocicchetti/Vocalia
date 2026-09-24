"""Tests only the public JFK fixture from the official OpenAI Whisper test suite."""
import json
import os
import subprocess
import sys
import tempfile
import hashlib
import wave
from pathlib import Path
import av

with tempfile.TemporaryDirectory(prefix='VocaliaEngineTest-') as folder:
    root = Path(folder)
    models = Path(os.environ.get('VOCALIA_TEST_MODELS', str(root/'models'))).resolve()
    binary = sys.argv[1] if len(sys.argv)>1 else None
    command = [binary] if binary else [sys.executable, str(Path(__file__).with_name('app.py'))]
    fixture = Path(__file__).with_name('test-speech.flac').resolve()
    sources = [fixture]
    for extension, codec in [('mp3','libmp3lame'), ('mp4','aac'), ('mov','aac'), ('opus','libopus'), ('ogg','libopus')]:
        output = root / ('declaración con espacios.' + extension)
        with av.open(str(fixture)) as source, av.open(str(output), 'w') as target:
            stream = target.add_stream(codec, rate=48000 if codec=='libopus' else 16000)
            for frame in source.decode(audio=0):
                for packet in stream.encode(frame):target.mux(packet)
            for packet in stream.encode(None):target.mux(packet)
        sources.append(output)
    invalid = root/'corrupt.mp3';invalid.write_bytes(b'not an audio file')
    cases = [('prepare',fixture,True), ('transcribe',invalid,False)] + [('transcribe',s,True) for s in sources]
    cases += [('clean',invalid,False)] + [('clean',s,True) for s in sources]
    for index, (task, source, expected) in enumerate(cases):
        jobdir = root/str(index);jobdir.mkdir()
        original_hash = hashlib.sha256(source.read_bytes()).digest()
        job = dict(task=task, model='tiny', models=str(models), source=str(source), language='en', terms=[], destination=str(jobdir/'clean.wav'))
        jobfile=jobdir/'job.json';jobfile.write_text(json.dumps(job),encoding='utf-8')
        result=subprocess.run(command+['--worker',str(jobfile)],timeout=900)
        if not expected:
            assert result.returncode != 0 and not (jobdir/'result.json').exists(), 'Invalid audio incorrectly accepted'
            assert 'error' in (jobdir/'events.jsonl').read_text(encoding='utf-8')
            assert not (jobdir/'clean.wav').exists(), 'Failed cleanup left an output file'
            print(f'PASS: corrupted audio rejected by {task} without closing the parent', flush=True)
            continue
        if result.returncode or not (jobdir/'result.json').exists():
            print((jobdir/'events.jsonl').read_text(encoding='utf-8') if (jobdir/'events.jsonl').exists() else 'Worker produced no events', flush=True)
            raise SystemExit('Engine worker failed')
        value=json.loads((jobdir/'result.json').read_text(encoding='utf-8'))
        assert hashlib.sha256(source.read_bytes()).digest() == original_hash, 'Worker changed the original recording'
        if task=='clean':
            assert Path(value['path'])==jobdir/'clean.wav'
            with wave.open(value['path'],'rb') as audio:
                assert audio.getframerate()==16000 and audio.getnchannels()==1
                assert abs(audio.getnframes()/16000 - 11)<0.15, 'Cleanup shifted the recording timeline'
            assert not list(jobdir.glob('clean-*')), 'Cleanup temporary files were not removed'
            print(f'PASS: packaged worker cleans {source.suffix}, preserves the timeline and original', flush=True)
        if task=='transcribe':
            assert value['segments'] and value['duration']>0
            assert any(s.get('words') for s in value['segments'])
            text=' '.join(s['text'] for s in value['segments']).lower()
            assert 'country' in text, text
            print(f'PASS: {source.suffix} transcribed offline with word timestamps', flush=True)
