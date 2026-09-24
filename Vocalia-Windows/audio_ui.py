from pathlib import Path
from PySide6.QtCore import Qt, Signal
from PySide6.QtWidgets import QTextEdit, QHBoxLayout, QCheckBox, QPushButton
from PySide6.QtMultimedia import QMediaPlayer
from core import python_index
from audio_review import word_at, selection_times, valid_loop
from i18n import tr


class TranscriptEdit(QTextEdit):
    wordClicked = Signal(int)
    click_to_play = True

    def mousePressEvent(self, event):
        self.press_point = event.position()
        super().mousePressEvent(event)

    def mouseReleaseEvent(self, event):
        super().mouseReleaseEvent(event)
        if (self.click_to_play and not self.isReadOnly() and
                event.button() == Qt.MouseButton.LeftButton and
                not event.modifiers() and not self.textCursor().hasSelection() and
                (event.position() - getattr(self, 'press_point', event.position())).manhattanLength() < 4):
            cursor = self.cursorForPosition(event.position().toPoint())
            # Clicking blank space to the right of a line must not seek.
            rect = self.cursorRect(cursor)
            if abs(rect.x() - event.position().x()) < 24:
                self.wordClicked.emit(python_index(self.toPlainText(), cursor.position()))


class AudioReviewUI:
    def __init__(self, window, layout, root):
        self.w, self.root = window, root
        self.loop = None
        self.labels = []
        row = QHBoxLayout(); layout.addLayout(row)
        self.click = QCheckBox(); self.click.setChecked(True)
        self.click.toggled.connect(lambda value: setattr(window.editor, 'click_to_play', value))
        self.repeat = QCheckBox(); self.repeat.toggled.connect(self.repeat_changed)
        self.selection = QPushButton(); self.selection.clicked.connect(self.repeat_selection)
        for item, label in [(self.click, 'Click words to play'), (self.repeat, 'Repeat audio'), (self.selection, 'Repeat selection')]:
            row.addWidget(item); self.labels.append((item, label))
        row = QHBoxLayout(); layout.addLayout(row)
        self.clean = QPushButton(); self.clean.clicked.connect(self.prepare_clean)
        self.use_clean = QCheckBox(); self.use_clean.toggled.connect(self.switch_audio)
        for item, label in [(self.clean, 'Clean audio'), (self.use_clean, 'Use cleaned audio')]:
            row.addWidget(item); self.labels.append((item, label))
        window.editor.wordClicked.connect(self.clicked)
        window.media.mediaStatusChanged.connect(self.media_status)

    def retranslate(self):
        for item, label in self.labels: item.setText(tr(label, self.w.language))
        self.clean.setToolTip(tr('Gentle rumble removal and volume normalization. Keeps the original and all timings. Does not remove other speakers or repair clipped speech.', self.w.language))
        self.use_clean.setToolTip(tr('Listen or transcribe again using the cleaned copy. Existing text stays unchanged until you transcribe again.', self.w.language))

    def set_busy(self, busy):
        for widget, _ in self.labels: widget.setEnabled(not busy)
        doc = self.w.store.get(self.w.selected) if self.w.selected else None
        self.use_clean.setEnabled(not busy and bool(doc and Path(doc.get('cleaned_source', '')).is_file()))

    def reset(self):
        self.loop = None
        for widget in (self.repeat, self.use_clean):
            widget.blockSignals(True); widget.setChecked(False); widget.blockSignals(False)
        self.set_busy(bool(self.w.proc))

    def source(self, doc):
        if self.use_clean.isChecked() and Path(doc.get('cleaned_source', '')).is_file(): return doc['cleaned_source']
        return doc['source']

    def clicked(self, index):
        self.w.flush_edit()
        doc = self.w.store.get(self.w.selected) if self.w.selected else None
        timing = word_at(doc, index) if doc else None
        if timing:
            self.loop = None; self.repeat.setChecked(False)
            self.w.play(timing[0])
        elif doc and 0 <= index < len(doc['text']) and not doc['text'][index].isspace():
            self.w.status.setText(tr('No reliable word timing here. Use Review to listen to the original segment.', self.w.language))

    def repeat_changed(self, checked):
        if not checked: self.loop = None
        else:
            self.loop = None
            self.w.play(0)

    def repeat_selection(self):
        self.w.flush_edit()
        doc = self.w.store.get(self.w.selected) if self.w.selected else None
        cursor = self.w.editor.textCursor()
        timing = selection_times(doc, python_index(doc['text'], cursor.selectionStart()), python_index(doc['text'], cursor.selectionEnd())) if doc else None
        if not timing or not valid_loop(*timing):
            self.w.status.setText(tr('Select unchanged words with timestamps to repeat them.', self.w.language)); return
        self.repeat.blockSignals(True); self.repeat.setChecked(True); self.repeat.blockSignals(False)
        self.loop = timing
        self.w.play(timing[0])

    def position(self, ms):
        if (self.loop and self.repeat.isChecked() and ms >= self.loop[1] * 1000 and
                self.w.media.playbackState() == QMediaPlayer.PlaybackState.PlayingState):
            self.w.media.setPosition(round(self.loop[0] * 1000))
            return True
        return False

    def media_status(self, status):
        if status == QMediaPlayer.MediaStatus.EndOfMedia and self.repeat.isChecked():
            self.w.media.setPosition(round((self.loop[0] if self.loop else 0) * 1000)); self.w.media.play()

    def prepare_clean(self):
        doc = self.w.store.get(self.w.selected) if self.w.selected else None
        if doc and not self.w.proc:
            import uuid
            self.w.launch(dict(task='clean', id=doc['id'], source=doc['source'], destination=str(self.root / 'Cleaned' / (str(uuid.uuid4()) + '.wav'))))

    def switch_audio(self):
        self.w.media.pause(); self.w.loaded_source = None
        self.loop = None; self.repeat.setChecked(False)
