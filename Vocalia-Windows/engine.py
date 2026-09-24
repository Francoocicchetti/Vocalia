"""Runs in a disposable child process: native decoding failures cannot crash the editor."""
import json
import os
from pathlib import Path
from core import atomic_json

MODELS = ('small', 'medium', 'large-v3-turbo', 'large-v3', 'tiny', 'tiny.en')


def run(job_path):
    job_path = Path(job_path)
    job = json.loads(job_path.read_text(encoding='utf-8'))
    events = job_path.parent / 'events.jsonl'

    def emit(kind, **payload):
        with events.open('a', encoding='utf-8') as out:
            out.write(json.dumps(dict(kind=kind, **payload), ensure_ascii=False) + '\n')
            out.flush()

    try:
        if job['task'] == 'clean':
            from audio_clean import clean_audio
            atomic_json(job_path.parent / 'result.json', clean_audio(job['source'], job['destination'], emit, work_dir=job_path.parent))
            emit('done'); return 0
        if job['task'] == 'scan':
            from core import collect_files
            atomic_json(job_path.parent / 'result.json', {'files': collect_files(job['inputs'])})
            emit('done')
            return 0
        os.environ['HF_HUB_DISABLE_TELEMETRY'] = '1'
        os.environ['HF_HUB_DISABLE_PROGRESS_BARS'] = '1'
        if job['task'] in ('prepare_voices','voices'):
            from voices_engine import prepare, analyze
            if job['task']=='prepare_voices':
                prepare(job['models'],emit);result={'prepared':True}
            else:
                emit('status',value='analyzing_voices')
                result={'turns':analyze(job['source'],job['models'],int(job.get('speaker_count',0)),emit)}
            atomic_json(job_path.parent/'result.json',result);emit('done');return 0
        os.environ['HF_HUB_DISABLE_TELEMETRY'] = '1'
        os.environ['HF_HUB_DISABLE_PROGRESS_BARS'] = '1'
        if job['task'] != 'prepare':
            os.environ['HF_HUB_OFFLINE'] = '1'
        # Import heavy native libraries only in this isolated process.
        import onnxruntime
        onnxruntime.disable_telemetry_events()
        from faster_whisper import WhisperModel
        import av
        model_name = job['model']
        if model_name not in MODELS:
            raise ValueError('Unsupported model')
        model_root = Path(job['models'])
        model_root.mkdir(parents=True, exist_ok=True)
        emit('status', value='loading')
        ready = model_root / (model_name + '.ready')
        if job['task'] != 'prepare' and not ready.exists():
            raise RuntimeError('MODEL_NOT_READY')
        model = WhisperModel(model_name, device='cpu', compute_type='int8',
                             cpu_threads=max(1, min(4, (os.cpu_count() or 2) - 1)),
                             num_workers=1, download_root=str(model_root),
                             local_files_only=job['task'] != 'prepare')
        if job['task'] == 'prepare':
            ready.write_text('ready', encoding='utf-8')
            atomic_json(job_path.parent / 'result.json', {'prepared': True})
            emit('done')
            return 0
        source = Path(job['source'])
        if not source.is_file():
            raise FileNotFoundError('SOURCE_MISSING')
        with av.open(str(source)) as media:
            if not media.streams.audio:
                raise ValueError('NO_AUDIO')
            duration = (media.duration or 0) / av.time_base
            if not duration or duration <= 0 or duration >= 7200:
                raise ValueError('DURATION_LIMIT')
        emit('status', value='transcribing')
        segments, info = model.transcribe(str(source), language=job.get('language') or None,
                                         beam_size=5, word_timestamps=True, vad_filter=True,
                                         condition_on_previous_text=False,
                                         initial_prompt=', '.join(job.get('terms', []))[:1000] or None,
                                         hotwords=', '.join(job.get('terms', []))[:1000] or None)
        from number_format import format_numbers,format_words
        result = []
        for segment in segments:
            item = dict(start=float(segment.start), end=float(segment.end), text=segment.text.strip(),
                        words=[dict(start=float(w.start), end=float(w.end), word=w.word, probability=float(w.probability)) for w in (segment.words or [])],
                        original_text=segment.text.strip(), reviewed=False, speaker='',
                        uncertain=segment.avg_logprob < -0.8 or segment.no_speech_prob > 0.4 or any(w.probability < 0.65 for w in (segment.words or [])))
            item['text']=format_numbers(item['text'],info.language)
            item['words']=format_words(item['words'],info.language)
            item['uncertain']=item['uncertain'] or any(c.isdecimal() for c in item['text'])
            result.append(item)
            emit('segment' if job['task']=='transcribe' else 'progress', segment=item, progress=min(0.99, segment.end / duration))
        if not any(s['text'].strip() for s in result):raise ValueError('NO_SPEECH')
        atomic_json(job_path.parent / 'result.json', dict(segments=result, language=info.language, duration=duration))
        emit('done')
        return 0
    except Exception as error:
        # Local diagnostics omit tracebacks/recognized text; user chooses any sharing.
        emit('error', message=f'{type(error).__name__}: {error}')
        return 1
