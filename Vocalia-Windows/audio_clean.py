"""Local, gentle rumble removal and bounded level normalization.

No silence removal, speed change, speech synthesis or source-file writes.
The output keeps the audio timeline (including timestamp gaps).
"""
from array import array
import math
import os
from pathlib import Path
import tempfile
import wave

RATE = 16000


class RumbleFilter:
    def __init__(self):
        self.alpha = 1 / (1 + 2 * math.pi * 70 / RATE)
        self.x = self.y = 0.0

    def process(self, values):
        out = array('f')
        for value in values:
            value = float(value)
            if not math.isfinite(value):
                raise ValueError('INVALID_AUDIO_SAMPLE')
            self.y = self.alpha * (self.y + value - self.x)
            self.x = value
            out.append(self.y)
        return out


def normalization_gain(peak):
    return min(2.0, 0.95 / peak) if peak > 0.0001 else 1.0


def clean_audio(source, destination, emit=lambda *args, **kwargs: None, work_dir=None):
    import av
    source, destination = Path(source), Path(destination)
    if source.resolve() == destination.resolve():
        raise ValueError('SOURCE_MUST_BE_PRESERVED')
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Unique temporary files are removed even after decoding errors.
    with tempfile.TemporaryDirectory(prefix='clean-', dir=work_dir or destination.parent) as folder:
        raw = Path(folder) / 'filtered.f32'
        result = Path(folder) / 'clean.wav'
        filtering = RumbleFilter()
        count, peak = 0, 0.0
        with av.open(str(source)) as media, raw.open('wb') as output:
            if not media.streams.audio:
                raise ValueError('NO_AUDIO')
            stream = media.streams.audio[0]
            resampler = av.AudioResampler(format='flt', layout='mono', rate=RATE)

            def write(values):
                nonlocal count, peak
                if count + len(values) >= RATE * 7200:
                    raise ValueError('DURATION_LIMIT')
                filtered = filtering.process(values)
                peak = max(peak, max(map(abs, filtered), default=0))
                output.write(filtered.tobytes())
                count += len(filtered)

            def consume(frame):
                position = round(float(frame.pts * frame.time_base) * RATE) if frame.pts is not None else count
                if position >= RATE * 7200: raise ValueError('DURATION_LIMIT')
                while position - count > 2:
                    write([0.0] * min(position - count, 8192))
                samples = frame.to_ndarray().reshape(-1)
                # Decoder preroll before t=0 does not belong to the playable timeline.
                skip = max(0, count - position)
                write(samples[skip:])

            emit('status', value='cleaning_audio')
            for frame in media.decode(stream):
                for converted in resampler.resample(frame):
                    consume(converted)
            for converted in resampler.resample(None):
                consume(converted)
        if not count:
            raise ValueError('NO_AUDIO')
        gain = normalization_gain(peak)
        with raw.open('rb') as input_file, wave.open(str(result), 'wb') as output:
            output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            while block := input_file.read(8192 * 4):
                values = array('f'); values.frombytes(block)
                samples = array('h', (round(max(-1, min(1, x * gain)) * 32767) for x in values))
                if __import__('sys').byteorder != 'little': samples.byteswap()
                output.writeframesraw(samples.tobytes())
        os.replace(result, destination)
    return dict(path=str(destination), duration=count / RATE, gain=gain)
