"""Optional CPU speaker grouping. Explicit model download; inference is offline."""
from pathlib import Path
import hashlib
import tarfile
import urllib.request
import os

BASE = 'https://github.com/k2-fsa/sherpa-onnx/releases/download/'
SEGMENTATION = 'sherpa-onnx-pyannote-segmentation-3-0.tar.bz2'
EMBEDDING = '3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx'
# Pinned to checksums of the upstream release assets; incomplete downloads never become ready.
HASHES = {SEGMENTATION:'24615ee884c897d9d2ba09bb4d30da6bb1b15e685065962db5b02e76e4996488',EMBEDDING:'1a331345f04805badbb495c775a6ddffcdd1a732567d5ec8b3d5749e3c7a5e4b'}


def ready(root):
    root = Path(root)/'speakers'
    return all((root/name).is_file() for name in ('model.onnx',EMBEDDING,'ready'))


def prepare(root, emit):
    root = Path(root)/'speakers';root.mkdir(parents=True,exist_ok=True)
    for tag,name in [('speaker-segmentation-models',SEGMENTATION),('speaker-recongition-models',EMBEDDING)]:
        dest = root/name
        if dest.exists() and hashlib.sha256(dest.read_bytes()).hexdigest()==HASHES[name]:continue
        temporary = root/(name+'.download')
        try:
            request=urllib.request.Request(BASE+tag+'/'+name,headers={'User-Agent':'Vocalia/0.0.5'})
            digest=hashlib.sha256()
            with urllib.request.urlopen(request,timeout=60) as response, temporary.open('wb') as out:
                while chunk:=response.read(1024*1024):
                    out.write(chunk);digest.update(chunk)
            if digest.hexdigest()!=HASHES[name]:raise ValueError('MODEL_CHECKSUM')
            os.replace(temporary,dest)
        finally:
            temporary.unlink(missing_ok=True)
    with tarfile.open(root/SEGMENTATION) as archive:
        for name in ('model.onnx','LICENSE','README.md'):
            member=next(m for m in archive.getmembers() if m.isfile() and Path(m.name).name==name)
            # Write named files only; archive paths and links are never extracted.
            temporary=root/(name+'.tmp');temporary.write_bytes(archive.extractfile(member).read());os.replace(temporary,root/name)
    (root/'ready').write_text('1',encoding='utf8')
    emit('status',value='ready')


def analyze(source, root, count, emit):
    if not ready(root):raise ValueError('VOICES_NOT_READY')
    import onnxruntime
    onnxruntime.disable_telemetry_events()
    import sherpa_onnx
    from faster_whisper.audio import decode_audio
    import numpy as np
    import av
    with av.open(str(source)) as media:
        duration=(media.duration or 0)/av.time_base
        if not media.streams.audio:raise ValueError('NO_AUDIO')
        if not 0<duration<7200:raise ValueError('DURATION_LIMIT')
    samples=decode_audio(str(source),sampling_rate=16000)
    folder=Path(root)/'speakers'
    config=sherpa_onnx.OfflineSpeakerDiarizationConfig(
        segmentation=sherpa_onnx.OfflineSpeakerSegmentationModelConfig(
            pyannote=sherpa_onnx.OfflineSpeakerSegmentationPyannoteModelConfig(model=str(folder/'model.onnx')),
            num_threads=2,provider='cpu'),
        embedding=sherpa_onnx.SpeakerEmbeddingExtractorConfig(model=str(folder/EMBEDDING),num_threads=2,provider='cpu'),
        clustering=sherpa_onnx.FastClusteringConfig(num_clusters=count if count>0 else -1,threshold=0.5),
        min_duration_on=0.3,min_duration_off=0.5)
    if not config.validate():raise ValueError('VOICES_NOT_READY')
    diarizer=sherpa_onnx.OfflineSpeakerDiarization(config)
    def progress(done,total):emit('progress',progress=done/max(1,total));return 0
    result=diarizer.process(np.asarray(samples,dtype=np.float32),callback=progress).sort_by_start_time()
    labels={};turns=[]
    for item in result:
        label=labels.setdefault(item.speaker,f'Speaker {len(labels)+1}')
        turns.append(dict(start=max(0,float(item.start)),end=min(duration,float(item.end)),speaker=label))
    if not turns:raise ValueError('NO_SPEECH')
    return turns
