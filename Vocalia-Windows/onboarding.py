"""Local language selection and anchored, replayable in-app coach marks."""
from PySide6.QtCore import Qt, QTimer, QPoint
from PySide6.QtWidgets import (QDialog, QVBoxLayout, QLabel, QComboBox,
    QPushButton, QHBoxLayout, QFrame, QRubberBand)

from i18n import LANGUAGES, tr, normalize

class WelcomeDialog(QDialog):
    def __init__(self, language='en', parent=None):
        super().__init__(parent)
        self.setWindowTitle('Vocalia'); self.setMinimumWidth(420)
        self.language = language
        layout = QVBoxLayout(self); layout.setSpacing(20)
        self.heading = QLabel();self.heading.setWordWrap(True);self.heading.setStyleSheet('font-size:20px;font-weight:700');layout.addWidget(self.heading)
        self.description=QLabel();self.description.setWordWrap(True);layout.addWidget(self.description)
        self.language_box = QComboBox()
        for code,name in LANGUAGES:self.language_box.addItem(name,code)
        self.language_box.setCurrentIndex(self.language_box.findData(normalize(language)))
        layout.addWidget(self.language_box)
        self.next_button = QPushButton()
        self.next_button.clicked.connect(self.advance); layout.addWidget(self.next_button)
        self.language_box.currentIndexChanged.connect(self.render)
        self.render()
    def render(self):
        language=self.language_box.currentData()
        self.heading.setText(tr('Welcome to Vocalia',language));self.description.setText(tr('Choose your language before starting.',language));self.next_button.setText(tr('Continue',language))
    def advance(self):
        self.language = self.language_box.currentData(); self.accept()

# key, Spanish title/body, English title/body
STEPS = [
 ('add', 'Agrega tus grabaciones', 'Agrega o arrastra grabaciones para iniciar la transcripción automáticamente. Los archivos se procesan uno a uno, incluidos OPUS.', 'Add your recordings', 'Add or drop recordings to start transcription automatically. Multiple files are processed one at a time, including OPUS.'),
 ('audio', 'Idioma de la grabación', 'Elige el idioma que habla la persona. Este ajuste es independiente del idioma de los botones.', 'Recording language', 'Choose the audio language before adding recordings. It is independent of the interface language.'),
 ('prepare', 'Prepara el reconocimiento', 'Descarga el modelo una vez con internet. Después puedes transcribir sin conexión. Tus grabaciones se quedan en este equipo.', 'Prepare speech recognition', 'If a model is missing, download it once; transcription continues when it is ready. Recordings stay on this computer.'),
 ('run', 'Retoma grabaciones detenidas', 'Los archivos nuevos empiezan automáticamente. Este botón reintenta grabaciones pendientes o detenidas. Cancelar detiene la cola; el análisis de voces sigue siendo manual.', 'Resume stopped recordings', 'New files start automatically. This button retries pending or stopped recordings. Cancel stops the queue; speaker analysis remains manual.'),
 ('status', 'Sigue el progreso', 'Aquí verás si Vocalia está preparando el modelo, transcribiendo o ha encontrado un problema. Espera a que termine para copiar el resultado completo.', 'Follow progress', 'This area shows preparation, transcription and any problems. Wait for completion before copying the full result.'),
 ('play', 'Escucha y revisa', 'Reproducir solo permite escuchar; no transcribe. Cuando haya texto, Seguir audio resaltará la posición mientras escuchas.', 'Listen and review', 'Play only plays the recording; it does not transcribe. Once text is available, Follow audio highlights your position as you listen.'),
 ('tabs', 'Texto completo y cuñas', 'Aquí aparecerá el texto editable. Revisa nombres y cifras. Selecciona una frase y usa Guardar cuña para conservar una cita.', 'Full text and quotes', 'Your editable transcript appears here. Check names and numbers. Select a passage and use Save quote to keep a quote.'),
 ('copy', 'Copia o exporta', 'Copia todo el texto de una vez. El botón Exportar también permite guardar el resultado para trabajar fuera de Vocalia.', 'Copy or export', 'Copy the full text in one go. Export also saves the result for use outside Vocalia.'),
 ('interface', 'Cambia el idioma cuando quieras', 'Aquí cambias los botones entre español e inglés. Puedes repetir este recorrido desde Cómo usar Vocalia.', 'Change language any time', 'Choose one of the six interface languages here. Reopen this tour from How to use Vocalia.')
]

class GuidedTour(QFrame):
    def __init__(self, parent, targets, language, finished):
        super().__init__(parent)
        self.targets = targets; self.language = language; self.finished = finished; self.index = 0
        self.setObjectName('tourBubble')
        self.setStyleSheet('#tourBubble{background:#fff;border:2px solid #6960ad;border-radius:14px} QLabel{color:#292654;border:0} QPushButton{padding:7px}')
        self.setFixedWidth(350)
        layout = QVBoxLayout(self); layout.setContentsMargins(18,16,18,16); layout.setSpacing(12)
        self.counter = QLabel(); layout.addWidget(self.counter)
        self.heading = QLabel(); self.heading.setWordWrap(True); self.heading.setStyleSheet('font-size:18px;font-weight:700');layout.addWidget(self.heading)
        self.detail = QLabel();self.detail.setWordWrap(True);layout.addWidget(self.detail)
        row = QHBoxLayout(); layout.addLayout(row)
        self.skip = QPushButton(tr('Skip',language)); row.addWidget(self.skip)
        row.addStretch()
        self.back = QPushButton(tr('Back',language));row.addWidget(self.back)
        self.next = QPushButton();row.addWidget(self.next)
        self.skip.clicked.connect(self.finish); self.back.clicked.connect(lambda:self.go(-1)); self.next.clicked.connect(lambda:self.go(1))
        self.ring = QRubberBand(QRubberBand.Shape.Rectangle, parent)
        self.ring.setAttribute(Qt.WidgetAttribute.WA_TransparentForMouseEvents)
        self.arrow = QLabel(parent);self.arrow.setStyleSheet('color:#6960ad;font-size:22px;background:transparent')
        self.arrow.setAttribute(Qt.WidgetAttribute.WA_TransparentForMouseEvents)
        self.timer = QTimer(self);self.timer.setInterval(120);self.timer.timeout.connect(self.place)
        self.render();self.show();self.timer.start()
    def render(self):
        step = STEPS[self.index]
        self.counter.setText(f'{self.index+1} / {len(STEPS)}')
        self.heading.setText(tr(step[3],self.language)); self.detail.setText(tr(step[4],self.language))
        self.back.setEnabled(self.index > 0)
        self.next.setText(tr('Done' if self.index == len(STEPS)-1 else 'Next',self.language))
        self.adjustSize();self.place();self.next.setFocus()
        self.setAccessibleName(self.heading.text());self.detail.setAccessibleName(self.detail.text())
    def place(self):
        target = self.targets[STEPS[self.index][0]]
        point = target.mapTo(self.parentWidget(), QPoint(0,0))
        rect = target.rect().translated(point).adjusted(-3,-3,3,3)
        self.ring.setGeometry(rect);self.ring.show();self.ring.raise_()
        bounds = self.parentWidget().rect(); margin=12
        # Prefer a side with enough space, keeping the highlighted control exposed.
        if bounds.width()-rect.right() >= self.width()+24:
            x=rect.right()+18;y=rect.center().y()-self.height()//2;glyph='◀'
        elif rect.left() >= self.width()+24:
            x=rect.left()-self.width()-18;y=rect.center().y()-self.height()//2;glyph='▶'
        else:
            x=rect.center().x()-self.width()//2
            below=bounds.height()-rect.bottom()
            y=rect.bottom()+18 if below>=self.height()+24 else rect.top()-self.height()-18
            glyph='▲' if below>=self.height()+24 else '▼'
        x=max(margin,min(x,bounds.width()-self.width()-margin));y=max(margin,min(y,bounds.height()-self.height()-margin))
        self.move(x,y);self.raise_()
        self.arrow.setText(glyph);self.arrow.adjustSize()
        if glyph in ('◀','▶'):
            ax=x-16 if glyph=='◀' else x+self.width()-2
            ay=max(y+12,min(rect.center().y()-12,y+self.height()-28))
        else:
            ax=max(x+12,min(rect.center().x()-10,x+self.width()-28));ay=y-19 if glyph=='▲' else y+self.height()-3
        self.arrow.move(ax,ay);self.arrow.show();self.arrow.raise_()
    def go(self, delta):
        if self.index+delta >= len(STEPS):self.finish();return
        self.index=max(0,self.index+delta);self.render()
    def finish(self):
        self.timer.stop();self.ring.hide();self.arrow.hide();self.ring.deleteLater();self.arrow.deleteLater();self.hide();self.finished();self.deleteLater()
    def keyPressEvent(self,event):
        if event.key()==Qt.Key.Key_Escape:self.finish()
        else:super().keyPressEvent(event)
