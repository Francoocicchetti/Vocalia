"""Vocalia 0.0.6 for Windows. UI and storage stay outside the speech process."""
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from collections import deque
from i18n import tr, LANGUAGES, normalize
from core import Store, new_document, transcript_text, timestamp, export_text, selection_match, playback_range, qt_index, python_index, atomic_json


def data_root():
    return Path(os.environ.get('LOCALAPPDATA', str(Path.home() / '.local' / 'share'))) / 'Vocalia'


def command(job):
    if getattr(sys, 'frozen', False):
        return [sys.executable, '--worker', str(job)]
    return [sys.executable, str(Path(__file__).resolve()), '--worker', str(job)]


ES = {
    'tutorial': 'Cómo usar Vocalia', 'no_pending': 'No hay archivos pendientes. Agrega una grabación nueva para transcribir.', 'prepare_question': 'Primero hay que descargar el modelo de voz. ¿Descargarlo ahora y transcribir los archivos pendientes al terminar? Solo se descarga el modelo; tus grabaciones no se envían.', 'empty_import': 'No se agregaron archivos nuevos compatibles. Comprueba si ya están en el historial.', 'no_speech': 'No se detectó voz. Revisa el audio y el idioma seleccionado.',
    'title': 'Vocalia 0.0.6 · Windows', 'add': 'Agregar archivos', 'folder': 'Agregar carpeta',
    'run': 'Transcribir pendientes', 'cancel': 'Cancelar', 'remove': 'Quitar del historial',
    'undo': 'Recuperar última eliminada', 'language': 'Idioma del audio', 'interface': 'Cambiar idioma',
    'model': 'Modelo local', 'prepare': 'Descargar / preparar modelo', 'ready': 'Modelo listo',
    'terms': 'Diccionario: nombres, lugares y siglas separados por comas',
    'text': 'Texto completo', 'quotes': 'Cuñas', 'copy': 'Copiar texto completo',
    'export': 'Exportar', 'batch_export': 'Exportar todos los TXT', 'play': 'Reproducir / pausar',
    'listen': 'Escuchar selección', 'save_quote': 'Guardar cuña', 'speaker': 'Nombre del hablante',
    'follow': 'Seguir audio', 'relink': 'Vincular original', 'quote_copy': 'Copiar cuña con fuente',
    'welcome': 'Agrega grabaciones. Todo se procesa en este equipo; los originales se conservan.',
    'pending': 'Pendiente', 'running': 'Transcribiendo', 'done': 'Terminada',
    'error': 'Error · puedes reintentar', 'partial': 'Parcial · cancelada o interrumpida',
    'loading': 'Preparando el modelo local…', 'transcribing': 'Transcribiendo en este equipo…',
    'model_missing': 'Prepara primero el modelo. La descarga no envía tus grabaciones.',
    'source_missing': 'No encuentro el original. Conecta el disco o pulsa Vincular original.',
    'invalid_selection': 'Selecciona una frase intacta de la transcripción para conservar sus tiempos.',
    'remove_confirm': '¿Quitar esta transcripción del historial? El audio se conserva y puedes recuperar la entrada.',
    'close_confirm': 'Hay un trabajo en curso. ¿Cancelarlo y cerrar? Se conserva el texto parcial.',
    'model_info': 'small: equilibrado · medium: mayor consumo · large-v3-turbo: más precisión, más memoria',
    'limitations': 'Windows: Whisper local; hablantes manuales en cuñas. Sin motor Apple ni separación automática de voces.',
    'saved': 'Guardado.', 'copied': 'Copiado.', 'finished': 'Cola terminada. Revisa nombres, cifras y citas.',
    'preparing': 'Descargando / preparando el modelo. Puedes cancelar.', 'scanning': 'Buscando archivos…',
    'export_note': 'TXT conserva tus ediciones. SRT/VTT usan los fragmentos originales con sus tiempos.',
    'errors': 'El proceso no pudo terminar. El resto del historial se conserva.',
}
EN = {
    'tutorial': 'How to use Vocalia', 'no_pending': 'No pending files. Add a new recording to transcribe.', 'prepare_question': 'The speech model needs to be downloaded first. Download it now and transcribe pending files when it is ready? Only the model is downloaded; your recordings are not uploaded.', 'empty_import': 'No new supported files were added. Check whether they are already in your history.', 'no_speech': 'No speech detected. Check the recording and selected audio language.',
    'title': 'Vocalia 0.0.6 · Windows', 'add': 'Add files', 'folder': 'Add folder',
    'run': 'Transcribe pending', 'cancel': 'Cancel', 'remove': 'Remove from history',
    'undo': 'Restore last removed', 'language': 'Audio language', 'interface': 'Change language',
    'model': 'Local model', 'prepare': 'Download / prepare model', 'ready': 'Model ready',
    'terms': 'Dictionary: names, places and acronyms separated by commas',
    'text': 'Full text', 'quotes': 'Quotes', 'copy': 'Copy full text', 'export': 'Export',
    'batch_export': 'Export all TXT files', 'play': 'Play / pause', 'listen': 'Listen to selection',
    'save_quote': 'Save quote', 'speaker': 'Speaker name', 'follow': 'Follow audio',
    'relink': 'Relink original', 'quote_copy': 'Copy quote with source',
    'welcome': 'Add recordings. Processing stays on this computer; originals are preserved.',
    'pending': 'Pending', 'running': 'Transcribing', 'done': 'Complete', 'error': 'Error · retry available',
    'partial': 'Partial · canceled or interrupted', 'cleaning_audio': 'Cleaning audio locally…', 'loading': 'Preparing the local model…',
    'transcribing': 'Transcribing on this computer…', 'model_missing': 'Prepare the model first. Downloads do not upload your recordings.',
    'source_missing': 'Original not found. Connect the drive or choose Relink original.',
    'invalid_selection': 'Select unchanged transcript text to preserve its source timing.',
    'remove_confirm': 'Remove this transcript? Original audio is kept and the entry can be restored.',
    'close_confirm': 'A job is running. Cancel it and close? Partial text will be preserved.',
    'model_info': 'small: fast · medium / turbo: more detail · large-v3: full model, slower and more memory. Compare names and figures with the original.',
    'limitations': 'Windows: local Whisper; manual speaker names in quotes. No Apple engine or automatic speaker separation.',
    'saved': 'Saved.', 'copied': 'Copied.', 'finished': 'Queue complete. Review names, numbers and quotes.',
    'preparing': 'Downloading / preparing the model. You can cancel.', 'scanning': 'Finding files…',
    'export_note': 'TXT preserves edits. SRT/VTT use original segments with timestamps.',
    'errors': 'The process could not finish. The rest of your history is preserved.',
}

ES.update({'review': 'Revisar', 'comparison': 'Comparación', 'voices': 'Voces', 'only_review': 'Solo sin revisar', 'review_note': 'Revisa cada fragmento con el audio. La bandera indica baja confianza, no una medición de precisión. Los cambios actualizan los subtítulos; el texto completo editado se conserva.', 'reviewed': 'Revisado', 'save': 'Guardar', 'restore_original': 'Restaurar original', 'compare_note': 'Compara dos modelos locales de Whisper. Se resaltan las diferencias; ninguna lectura se considera automáticamente correcta. Descarga el segundo modelo antes de comparar.', 'prepare_second': 'Preparar segundo modelo', 'compare_run': 'Comparar grabación', 'differences_only': 'Solo diferencias', 'copy_second': 'Copiar segunda transcripción', 'voices_note': 'Agrupa voces automáticamente y después asígnales nombres. Las etiquetas corresponden a esta grabación y pueden confundirse con ruido o voces superpuestas. Indica la cantidad si la conoces.', 'prepare_voices': 'Descargar modelos de voces', 'analyze_voices': 'Analizar voces', 'assign_name': 'Asignar nombre', 'quote_plain': 'Copiar cita', 'quote_listen': 'Escuchar cuña', 'export_quotes': 'Exportar cuñas', 'dictionary': 'Diccionario personal', 'automatic': 'Automática', 'speaker_count': 'Cantidad de voces', 'speed': 'Velocidad de reproducción', 'voices_ready': 'Modelos de voces listos. El análisis funciona sin conexión.', 'voices_missing': 'Descarga primero los modelos de voces. Solo se descargan modelos; tus audios no se envían.', 'different_model': 'Elige un modelo diferente al usado en la transcripción original.', 'prepare_second_first': 'Pulsa Preparar segundo modelo antes de comparar.', 'dictionary_note': 'Un término por línea, hasta 100. Se usan como contexto al transcribir, sin reemplazar palabras automáticamente.', 'analyzing_voices': 'Analizando voces en este equipo…', 'limitations': 'Windows: reconocimiento y voces locales. Revisa las etiquetas y las citas con el original.', 'export_note': 'TXT conserva tus ediciones. SRT/VTT usan los fragmentos de Revisar.'})
EN.update({'retranscribe':'Transcribe selected again','retranscribe_confirm':'Transcribe this recording again? A copy of the current transcript will be saved in Revisions before replacing it.','import_queued':'Files will be added after the current transcription queue finishes.','review': 'Review', 'comparison': 'Comparison', 'voices': 'Speakers', 'only_review': 'Only unreviewed', 'review_note': 'Review flags indicate low recognition confidence or figures to check against the audio. They are not accuracy scores.', 'reviewed': 'Reviewed', 'save': 'Save', 'restore_original': 'Restore original', 'compare_note': 'Compare two local Whisper models. Differences are highlighted; neither reading is automatically correct. Download the second model before comparing.', 'prepare_second': 'Prepare second model', 'compare_run': 'Compare recording', 'differences_only': 'Differences only', 'copy_second': 'Copy second transcript', 'voices_note': 'Group speakers automatically, then assign names. Labels belong to this recording and may be wrong with noise or overlapping speech. Set the count if you know it.', 'prepare_voices': 'Download speaker models', 'analyze_voices': 'Analyze speakers', 'assign_name': 'Assign name', 'quote_plain': 'Copy quote', 'quote_listen': 'Listen to quote', 'export_quotes': 'Export quotes', 'dictionary': 'Personal dictionary', 'automatic': 'Automatic', 'speaker_count': 'Speaker count', 'speed': 'Playback speed', 'voices_ready': 'Speaker models ready. Analysis works offline.', 'voices_missing': 'Download the speaker models first. Only models are downloaded; recordings are not uploaded.', 'different_model': 'Choose a model different from the original transcript model.', 'prepare_second_first': 'Choose Prepare second model before comparing.', 'dictionary_note': 'One term per line, up to 100. Terms provide transcription context without automatically replacing words.', 'analyzing_voices': 'Analyzing speakers on this computer…', 'limitations': 'Windows: local recognition and speaker analysis. Check labels and quotes against the original.', 'export_note': 'TXT preserves your edits. SRT/VTT use segments from Review.'})


def main(smoke=False):
    from PySide6.QtCore import Qt, QTimer, QUrl, QLockFile, QLocale
    from PySide6.QtGui import QIcon, QTextCursor, QColor, QPixmap
    from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
                                  QPushButton, QLabel, QListWidget, QListWidgetItem, QComboBox,
                                  QTextEdit, QLineEdit, QCheckBox, QTabWidget, QSplitter,
                                  QFileDialog, QMessageBox, QProgressBar, QSlider)
    from PySide6.QtMultimedia import QMediaPlayer, QAudioOutput

    app = QApplication(sys.argv[:1])
    app.setApplicationName('Vocalia')
    app.setOrganizationName('Vocalia')
    root = Path(tempfile.mkdtemp(prefix='VocaliaSmoke-')) if smoke else data_root()
    root.mkdir(parents=True, exist_ok=True)
    lock = QLockFile(str(root / 'instance.lock'))
    if not lock.tryLock(0):
        QMessageBox.information(None, 'Vocalia', tr('Vocalia is already running.',normalize(QLocale.system().name())))
        return 0
    try:
        store = Store(root / 'history.sqlite3')
    except Exception as error:
        QMessageBox.critical(None, 'Vocalia', tr('Could not open history:',normalize(QLocale.system().name()))+'\n'+str(error))
        return 1

    from onboarding import WelcomeDialog, GuidedTour, STEPS
    if not smoke and not store.setting('language_choice_102_release', False):
        welcome = WelcomeDialog(store.setting('ui_language', normalize(QLocale.system().name())))
        if not welcome.exec():
            store.close();lock.unlock();return 0
        store.set_setting('ui_language', welcome.language)
        store.set_setting('language_choice_102_release', True)

    class Window(QMainWindow):
        def __init__(self):
            super().__init__()
            self.store = store
            self.selected = None
            self.tour = None
            self.pending_edit = None
            self.proc = None
            self.job_dir = None
            self.job = None
            self.events_offset = 0
            self.event_error = ''
            self.queue = deque()
            self.import_queue = []
            self.cancelled = False
            self.run_after_prepare = False
            self.auto_generation = 0
            self.play_until = None
            self.loaded_source = None
            self.last_highlight = None
            self.language = store.setting('ui_language', normalize(QLocale.system().name()))
            for doc in store.documents():
                if doc['status'] == 'running':
                    doc['status'] = 'partial'
                    store.save(doc)
            self.setAcceptDrops(True)
            self.setMinimumSize(1000, 650)
            available = app.primaryScreen().availableGeometry()
            self.resize(min(1220, available.width()-40), min(840, available.height()-60))
            central = QWidget()
            self.setCentralWidget(central)
            outer = QVBoxLayout(central)
            header = QHBoxLayout()
            image = QLabel()
            icon_path = Path(__file__).parent / 'logo.png'
            if icon_path.exists():
                image.setPixmap(QPixmap(str(icon_path)).scaled(58, 58, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation))
                self.setWindowIcon(QIcon(str(icon_path)))
            header.addWidget(image)
            title = QLabel('Vocalia');title.setStyleSheet('font-size:28px;font-weight:700;color:#292654')
            header.addWidget(title);header.addStretch()
            self.interface_label = QLabel();header.addWidget(self.interface_label)
            self.interface = QComboBox()
            for code,name in LANGUAGES:self.interface.addItem(name,code)
            self.interface.setCurrentIndex(self.interface.findData(normalize(self.language)))
            header.addWidget(self.interface);outer.addLayout(header)
            splitter = QSplitter();outer.addWidget(splitter, 1)
            side = QWidget();left = QVBoxLayout(side);side.setMinimumWidth(245)
            self.buttons = {}
            def button(key, target, handler):
                obj = QPushButton();obj.clicked.connect(handler);target.addWidget(obj);self.buttons[key] = obj
                return obj
            button('tutorial', left, self.tutorial)
            button('add', left, self.add_files);button('folder', left, self.add_folder)
            self.list = QListWidget();left.addWidget(self.list, 1)
            button('run', left, self.begin);button('retranscribe', left, self.retranscribe);button('batch_export', left, self.export_all)
            button('remove', left, self.remove_doc);button('undo', left, self.undo_remove)
            splitter.addWidget(side)
            content = QWidget();right = QVBoxLayout(content);splitter.addWidget(content);splitter.setSizes([270, 920])
            settings = QHBoxLayout();right.addLayout(settings)
            self.audio_label = QLabel();settings.addWidget(self.audio_label)
            self.audio = QComboBox()
            for label, code in [('Español', 'es'), ('English', 'en'), ('Português', 'pt'), ('Français', 'fr'), ('Deutsch', 'de'), ('Italiano', 'it'), ('日本語', 'ja'), ('中文', 'zh'), ('Auto', '')]:
                self.audio.addItem(label, code)
            self.audio.setCurrentIndex(max(0, self.audio.findData(store.setting('audio_language', 'es'))));settings.addWidget(self.audio)
            self.model_label = QLabel();settings.addWidget(self.model_label)
            self.model = QComboBox();self.model.addItems(['small', 'medium', 'large-v3-turbo', 'large-v3'])
            self.model.setCurrentText(store.setting('model', 'small'));settings.addWidget(self.model)
            button('prepare', settings, self.prepare)
            self.model_ready = QLabel();self.model_ready.setWordWrap(True);right.addWidget(self.model_ready)
            self.model_info = QLabel();self.model_info.setWordWrap(True);right.addWidget(self.model_info)
            self.vocabrow=QHBoxLayout();right.addLayout(self.vocabrow)
            self.terms = QLineEdit(store.setting('terms', ''));self.vocabrow.addWidget(self.terms,1)
            actions = QHBoxLayout();self.playbackrow=actions;right.addLayout(actions)
            button('play', actions, self.play);button('relink', actions, self.relink)
            self.clock = QLabel('00:00:00');actions.addWidget(self.clock)
            self.follow = QCheckBox();self.follow.setChecked(True);actions.addWidget(self.follow)
            self.slider = QSlider(Qt.Orientation.Horizontal);self.slider.setRange(0, 0);right.addWidget(self.slider)
            self.tabs = QTabWidget();right.addWidget(self.tabs, 1)
            from audio_ui import TranscriptEdit, AudioReviewUI
            self.editor = TranscriptEdit();self.editor.setAcceptRichText(False);self.editor.setPlaceholderText('');self.editor.setStyleSheet('font-size:16px;padding:12px;background:white;')
            self.tabs.addTab(self.editor, '')
            quote_page = QWidget();q_layout = QVBoxLayout(quote_page)
            self.quote_list = QListWidget();q_layout.addWidget(self.quote_list)
            button('quote_copy', q_layout, self.copy_quote);self.tabs.addTab(quote_page, '')
            actions2 = QHBoxLayout();right.addLayout(actions2)
            button('listen', actions2, self.listen_selection)
            self.speaker = QLineEdit();actions2.addWidget(self.speaker)
            button('save_quote', actions2, self.save_quote)
            export_row = QHBoxLayout();right.addLayout(export_row)
            button('copy', export_row, self.copy_text);button('export', export_row, self.export)
            self.export_note = QLabel();self.export_note.setWordWrap(True);right.addWidget(self.export_note)
            self.limits = QLabel();self.limits.setWordWrap(True);self.limits.setStyleSheet('color:#666;font-size:11px');outer.addWidget(self.limits)
            footer = QHBoxLayout();outer.addLayout(footer)
            self.status = QLabel();self.status.setWordWrap(True);footer.addWidget(self.status, 1)
            self.progress = QProgressBar();self.progress.setRange(0, 100);self.progress.setValue(0);self.progress.setMaximumWidth(180);footer.addWidget(self.progress)
            button('cancel', footer, self.cancel)
            self.media = QMediaPlayer(self);self.output = QAudioOutput(self);self.media.setAudioOutput(self.output)
            self.audio_review = AudioReviewUI(self, right, root)
            self.media.positionChanged.connect(self.position)
            self.media.durationChanged.connect(lambda duration:self.slider.setRange(0, duration))
            self.media.errorOccurred.connect(lambda *_:self.status.setText(self.media.errorString()))
            self.slider.sliderReleased.connect(self.seek_slider)
            self.list.currentItemChanged.connect(self.selection_changed)
            self.editor.textChanged.connect(self.edit_changed)
            self.interface.currentIndexChanged.connect(self.change_language)
            self.audio.currentIndexChanged.connect(lambda:store.set_setting('audio_language', self.audio.currentData()))
            self.model.currentTextChanged.connect(self.model_changed)
            self.terms.textChanged.connect(lambda value:store.set_setting('terms', value))
            self.edit_timer = QTimer(self);self.edit_timer.setSingleShot(True);self.edit_timer.setInterval(250);self.edit_timer.timeout.connect(self.flush_edit)
            self.poller = QTimer(self);self.poller.setInterval(200);self.poller.timeout.connect(self.poll);self.poller.start()
            from advanced_ui import AdvancedUI
            self.features = AdvancedUI(self, store, root, app)
            from library_ui import LibraryUI
            library_row=QHBoxLayout();outer.insertLayout(1,library_row)
            self.library_ui=LibraryUI(self,store,library_row,smoke)
            self.retranslate();self.refresh();self.set_busy(False);self.update_readiness()
            self.status.setText(self.t('welcome'))
            self.status.setStyleSheet('font-size:14px;font-weight:600;padding:8px;background:#eceaf7;color:#292654')
            self.buttons['run'].setStyleSheet('background:#393368;color:white;font-weight:bold;padding:12px')
            self.setStyleSheet('QMainWindow{background:#f7f7fb} QPushButton{padding:7px} QLineEdit,QComboBox{padding:5px} QListWidget{background:white;border:1px solid #ddd;border-radius:6px} QTabWidget::pane{border:1px solid #ddd}')

        def t(self, key):
            return tr(EN.get(key,key),self.language)

        def retranslate(self):
            self.setWindowTitle(self.t('title'))
            for key, obj in self.buttons.items():obj.setText(self.t(key));obj.setToolTip(self.t(key))
            self.interface_label.setText(self.t('interface'));self.audio_label.setText(self.t('language'));self.model_label.setText(self.t('model'))
            self.model_info.setText(self.t('model_info'));self.terms.setPlaceholderText(self.t('terms'));self.speaker.setPlaceholderText(self.t('speaker'))
            self.follow.setText(self.t('follow'));self.tabs.setTabText(0, self.t('text'));self.tabs.setTabText(1, self.t('quotes'))
            self.editor.setPlaceholderText(tr('New recordings start automatically. Use Transcribe pending to resume a stopped recording.',self.language))
            self.export_note.setText(self.t('export_note'));self.limits.setText(self.t('limitations'))
            if hasattr(self,'audio_review'):self.audio_review.retranslate()
            if hasattr(self,'features'):self.features.retranslate()
            if hasattr(self,'library_ui'):self.library_ui.retranslate()

        def tutorial(self):
            if self.tour is not None:
                self.tour.finish()
            targets = dict(self.buttons, audio=self.audio, tabs=self.tabs, status=self.status, interface=self.interface)
            def finished():
                self.tour = None
                store.set_setting('guided_tour_102_release', True)
            self.tour = GuidedTour(self, targets, self.language, finished)

        def update_readiness(self):
            ready = (root / 'Models' / (self.model.currentText() + '.ready')).exists()
            self.model_ready.setText(('✓ ' + self.t('ready')) if ready else self.t('model_missing'))

        def change_language(self):
            old_status=self.status.text();source_status=next((value for value in EN.values() if tr(value,self.language)==old_status),None)
            self.language = self.interface.currentData();store.set_setting('ui_language', self.language)
            if source_status:self.status.setText(tr(source_status,self.language))
            self.retranslate();self.refresh(self.selected);self.update_readiness()
            if self.tour is not None:
                self.tour.language = self.language;self.tour.finish();self.tutorial()

        def model_changed(self):
            store.set_setting('model', self.model.currentText());self.update_readiness()

        def set_busy(self, busy):
            for key in ['run','retranscribe','prepare','remove','undo','relink','play','listen']:
                self.buttons[key].setEnabled(not busy)
            self.buttons['cancel'].setEnabled(busy)
            for item in (self.audio, self.model, self.terms):item.setEnabled(not busy)
            if hasattr(self,'library_ui'):
                for button,key in self.library_ui.buttons:
                    if key!='Update Vocalia':button.setEnabled(not busy)
            self.editor.setReadOnly(busy)
            self.buttons['save_quote'].setEnabled(not busy)
            self.features.set_busy(busy)
            self.audio_review.set_busy(busy)

        def refresh(self, selected=None):
            selected = selected or self.selected
            self.list.blockSignals(True);self.list.clear()
            target = None
            for doc in store.documents():
                row = QListWidgetItem(doc['name'] + '\n' + self.t(doc['status']))
                row.setData(Qt.ItemDataRole.UserRole, doc['id']);self.list.addItem(row)
                if doc['id'] == selected:target = row
            if target is None and self.list.count():target = self.list.item(0)
            self.list.setCurrentItem(target);self.list.blockSignals(False)
            self.selection_changed(target, None)

        def selection_changed(self, item, previous):
            self.flush_edit()
            ident = item.data(Qt.ItemDataRole.UserRole) if item else None
            if ident != self.selected:
                self.media.stop();self.loaded_source = None;self.play_until = None
                self.audio_review.reset()
            self.selected = ident
            self.audio_review.set_busy(bool(self.proc))
            doc = store.get(ident) if ident else None
            self.editor.blockSignals(True);self.editor.setPlainText(doc['text'] if doc else '');self.editor.blockSignals(False)
            self.editor.setExtraSelections([]);self.last_highlight = None
            self.features.refresh(doc)
            self.quote_list.clear()
            for quote in (doc or {}).get('quotes', []):
                self.quote_list.addItem(f"{quote.get('speaker','')} · {timestamp(quote['start'])}\n{quote['text']}")

        def edit_changed(self):
            if self.selected:
                self.pending_edit = (self.selected, self.editor.toPlainText());self.edit_timer.start()

        def flush_edit(self):
            pending = self.pending_edit;self.pending_edit = None
            if pending:
                doc = store.get(pending[0])
                if doc:
                    doc['text'] = pending[1];store.save(doc)

        def add_files(self):
            paths, _ = QFileDialog.getOpenFileNames(self, self.t('add'), '', 'Audio/video (*.mp3 *.mp4 *.mov *.m4a *.wav *.flac *.aac *.aiff *.aif *.caf *.m4v *.opus *.ogg)')
            if paths:self.import_paths(paths)

        def add_folder(self):
            path = QFileDialog.getExistingDirectory(self, self.t('folder'))
            if path:self.import_paths([path])

        def dragEnterEvent(self, event):
            if event.mimeData().hasUrls() and any(u.isLocalFile() for u in event.mimeData().urls()):event.acceptProposedAction()

        def dropEvent(self, event):
            paths=[u.toLocalFile() for u in event.mimeData().urls() if u.isLocalFile()]
            if paths:self.import_paths(paths);event.acceptProposedAction()

        def import_paths(self, paths):
            if self.proc or self.queue:
                self.import_queue.extend(paths)
                self.status.setText(self.t('import_queued'))
            else:self.launch({'task':'scan','inputs':paths,'auto_generation':self.auto_generation})

        def retranscribe(self):
            if self.proc or not self.selected:return
            doc=store.get(self.selected)
            if not doc:return
            if not (root/'Models'/(self.model.currentText()+'.ready')).exists():
                QMessageBox.information(self,'Vocalia',self.t('model_missing'));return
            if QMessageBox.question(self,'Vocalia',self.t('retranscribe_confirm'))!=QMessageBox.StandardButton.Yes:return
            self.flush_edit();self.queue=deque([doc['id']]);self.next_job()

        def prepare(self):
            self.launch({'task':'prepare', 'model':self.model.currentText()})

        def begin(self):
            self.start_ids([d['id'] for d in store.documents() if not d.get('complete')])

        def start_ids(self, pending):
            if self.proc:return
            self.flush_edit();self.media.stop();self.play_until = None
            pending = [ident for ident in pending if store.get(ident) and not store.get(ident).get('complete')]
            if not pending:
                self.status.setText(self.t('no_pending'))
                QMessageBox.information(self, 'Vocalia', self.t('no_pending'));return
            if not (root / 'Models' / (self.model.currentText() + '.ready')).exists():
                self.status.setText(self.t('model_missing'))
                if QMessageBox.question(self, 'Vocalia', self.t('prepare_question')) == QMessageBox.StandardButton.Yes:
                    self.queue = deque(pending);self.run_after_prepare = True;self.prepare()
                return
            self.queue = deque(pending)
            self.next_job()

        def next_job(self):
            while self.queue:
                ident = self.queue.popleft();doc = store.get(ident)
                if not doc:continue
                if doc.get('text'):
                    try:
                        revisions = root / 'Revisions';revisions.mkdir(exist_ok=True)
                        atomic_json(revisions / (doc['id']+'-'+str(time.time_ns())+'.json'), doc)
                    except OSError as error:
                        self.queue.clear();self.status.setText(self.t('errors')+' '+str(error));return
                doc['status'] = 'running';doc['complete'] = False;doc['segments'] = [];doc['text'] = '';doc.pop('comparison_segments',None);doc.pop('speaker_turns',None);store.save(doc)
                self.refresh(ident)
                self.launch({'task':'transcribe', 'id':ident, 'source':self.audio_review.source(doc) if ident == self.selected else doc['source'], 'model':self.model.currentText(),
                             'language':self.audio.currentData(), 'terms':[t.strip()[:100] for t in self.terms.text().split(',') if t.strip()][:100]})
                return
            self.set_busy(False);self.status.setText(self.t('finished'))
            self.drain_imports()

        def drain_imports(self):
            if self.proc or self.queue or not self.import_queue:return
            paths,self.import_queue=self.import_queue,[]
            self.launch({'task':'scan','inputs':paths,'auto_generation':self.auto_generation})

        def launch(self, job):
            if self.proc:return
            self.flush_edit();self.media.stop();self.cancelled = False;self.event_error = ''
            self.job_dir = Path(tempfile.mkdtemp(prefix='job-', dir=root))
            job['models'] = str(root / 'Models');atomic_json(self.job_dir / 'job.json', job)
            self.job = job;self.events_offset = 0;self.started = time.monotonic()
            self.set_busy(True);self.progress.setRange(0,0)
            self.status.setText(self.t('scanning' if job['task'] == 'scan' else 'preparing' if job['task'] == 'prepare' else 'loading'))
            try:
                self.proc = subprocess.Popen(command(self.job_dir / 'job.json'), stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                             creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0) if sys.platform=='win32' else 0)
            except Exception as error:
                self.event_error = str(error);self.finish(1)

        def poll(self):
            if not self.proc:return
            self.read_events()
            code = self.proc.poll()
            if code is not None:self.finish(code)
            elif time.monotonic() - self.started > (3600 if self.job['task']=='prepare' else 21600):
                self.event_error = 'Timeout';self.proc.kill()

        def read_events(self):
            events = self.job_dir / 'events.jsonl'
            if not events.exists():return
            with events.open('rb') as stream:
                stream.seek(self.events_offset)
                while True:
                    line = stream.readline()
                    if not line or not line.endswith(b'\n'):break
                    self.events_offset = stream.tell()
                    try:event = json.loads(line)
                    except (ValueError,UnicodeError):continue
                    if event['kind']=='error':self.event_error = event['message']
                    elif event['kind']=='status':self.status.setText(self.t(event['value']))
                    elif event['kind']=='progress':
                        self.progress.setRange(0,100);self.progress.setValue(int(event['progress']*100))
                    elif event['kind']=='segment':
                        doc = store.get(self.job.get('id'))
                        if doc:
                            doc['segments'].append(event['segment']);doc['text'] = transcript_text(doc['segments']);store.save(doc)
                            if self.selected==doc['id']:
                                self.editor.blockSignals(True);self.editor.setPlainText(doc['text']);self.editor.blockSignals(False)
                        self.progress.setRange(0,100);self.progress.setValue(int(event['progress']*100))

        def finish(self, code):
            self.read_events()
            job, folder = self.job, self.job_dir
            self.proc = None
            result_file = folder / 'result.json'
            success = code==0 and result_file.exists() and not self.cancelled
            result = None;added_ids = []
            try:
                if success:result = json.loads(result_file.read_text(encoding='utf-8'))
            except (OSError,ValueError):success = False
            if job['task']=='scan' and success:
                before = len(store.documents())
                known = {os.path.normcase(d['source']) for d in store.documents()}
                for path in result['files']:
                    if os.path.normcase(path) not in known:
                        doc = new_document(path);store.add(doc);added_ids.append(doc['id']);known.add(os.path.normcase(path))
            elif job['task']=='clean' and success:
                doc=store.get(job['id'])
                if doc:
                    doc['cleaned_source']=result['path'];store.save(doc)
            elif job['task']=='clean' and not success:
                Path(job['destination']).unlink(missing_ok=True)
            elif job['task']=='transcribe':
                doc = store.get(job['id'])
                if doc:
                    if success:
                        doc.update(segments=result['segments'], text=transcript_text(result['segments']), language=result['language'], duration=result['duration'], complete=True, status='done', recognition_model=job['model'])
                    else:doc['status'] = 'partial' if self.cancelled else 'error'
                    store.save(doc)
            elif job['task'] in ('compare','voices') and success:
                doc=store.get(job['id'])
                if doc:
                    if job['task']=='compare':
                        doc.update(comparison_segments=result['segments'],comparison_model=job['model'])
                    else:
                        from advanced_core import apply_speakers
                        doc=apply_speakers(doc,result['turns'])
                    store.save(doc)
            self.progress.setRange(0,100);self.progress.setValue(100 if success else 0)
            self.refresh(self.selected);self.set_busy(False)
            self.status.setText(self.t('ready') if success and job['task']=='prepare' else self.t('saved') if success else self.t('partial') if self.cancelled else self.t('errors') + ' ' + self.friendly_error(self.event_error))
            import shutil
            shutil.rmtree(folder, ignore_errors=True)
            self.job = None;self.job_dir = None
            self.update_readiness()
            if job['task']=='scan' and success:
                self.status.setText(self.t('empty_import') if len(store.documents())==before else tr('New recordings will be transcribed automatically.',self.language))
            if job['task']=='prepare':
                resume = self.run_after_prepare and success
                self.run_after_prepare = resume
                if not resume:self.queue.clear()
                if resume:
                    def continue_queue():
                        self.run_after_prepare = False
                        if self.queue and not self.cancelled:self.next_job()
                    QTimer.singleShot(0, continue_queue)
            if not success and not self.cancelled:
                message = self.friendly_error(self.event_error) or tr('The engine exited (code %@).',self.language).replace('%@',str(code))
                self.status.setText(self.t('errors')+' '+message)
                if not smoke:QMessageBox.warning(self, 'Vocalia', self.t('errors')+'\n\n'+message)

            if job['task']=='scan' and success and added_ids and job.get('auto_generation') == self.auto_generation:
                # Only this import is eligible; historical partial/edited files stay untouched.
                generation = self.auto_generation
                def start_imported():
                    if generation == self.auto_generation:self.start_ids(added_ids)
                start_imported()
                if not self.proc and not self.queue:QTimer.singleShot(0,self.drain_imports)
            elif job['task']=='transcribe' and not self.cancelled and self.queue:QTimer.singleShot(0, self.next_job)
            elif not self.run_after_prepare:QTimer.singleShot(0,self.drain_imports)

        def friendly_error(self, message):
            for code, es, en in [
                ('VOICES_NOT_READY', 'Descarga primero los modelos de voces.', 'Download the speaker models first.'),
                ('MODEL_CHECKSUM', 'La descarga está incompleta o cambió. Vuelve a preparar los modelos.', 'The download is incomplete or changed. Prepare the models again.'),
                ('NO_SPEECH', 'No se detectó voz. Comprueba el audio y el idioma.', 'No speech detected. Check the recording and audio language.'),
                ('MODEL_NOT_READY', 'Descarga o prepara el modelo primero.', 'Download or prepare the model first.'),
                ('SOURCE_MISSING', 'Conecta el disco o vuelve a vincular el archivo original.', 'Connect the drive or relink the original file.'),
                ('DURATION_LIMIT', 'Usa una grabación de menos de dos horas con duración legible.', 'Use a recording shorter than two hours with a readable duration.'),
                ('NO_AUDIO', 'El archivo no contiene una pista de audio.', 'The file contains no audio track.'),
                ('Timeout', 'El trabajo excedió el tiempo máximo. Puedes reintentarlo con un modelo menor.', 'The job timed out. Try again with a smaller model.')]:
                if code in message:return tr(en,self.language)
            return message

        def cancel(self):
            self.auto_generation += 1;self.import_queue.clear()
            self.queue.clear();self.cancelled = True;self.run_after_prepare = False
            if self.proc:self.proc.kill()

        def remove_doc(self):
            if self.proc or not self.selected:return
            if QMessageBox.question(self, 'Vocalia', self.t('remove_confirm')) != QMessageBox.StandardButton.Yes:return
            self.remove_id(self.selected)

        def remove_id(self, ident):
            self.flush_edit();self.media.stop();self.selected = None;store.remove(ident);self.refresh()

        def undo_remove(self):
            ident = store.undo_remove();self.refresh(ident)

        def seek_slider(self):
            self.audio_review.repeat.setChecked(False)
            self.media.setPosition(self.slider.value())

        def play(self, start=None, end=None):
            doc = store.get(self.selected) if self.selected else None
            if not doc:return
            source = self.audio_review.source(doc)
            if not Path(source).is_file():self.status.setText(self.t('source_missing'));return
            if self.loaded_source != source:
                self.media.setSource(QUrl.fromLocalFile(source));self.loaded_source = source
            if isinstance(start, bool):start = None
            if start is None and self.media.playbackState()==QMediaPlayer.PlaybackState.PlayingState:
                self.media.pause();return
            if end is not None:self.audio_review.repeat.setChecked(False)
            if start is None and self.media.mediaStatus()==QMediaPlayer.MediaStatus.EndOfMedia:start=0
            if start is not None:self.media.setPosition(round(start*1000))
            self.play_until = end;self.media.play()

        def position(self, ms):
            if self.audio_review.position(ms):return
            self.clock.setText(timestamp(ms/1000)[:-4])
            if not self.slider.isSliderDown():self.slider.setValue(ms)
            if self.play_until is not None and ms>=self.play_until*1000:
                self.media.pause();self.play_until = None
            doc = store.get(self.selected) if self.selected else None
            if not doc or self.loaded_source != self.audio_review.source(doc):return
            doc['text'] = self.editor.toPlainText()
            active = playback_range(doc, ms/1000)
            if active == self.last_highlight:return
            self.last_highlight = active;selections = []
            if active:
                selected = QTextEdit.ExtraSelection();cursor = QTextCursor(self.editor.document())
                cursor.setPosition(qt_index(doc['text'], active[0]));cursor.setPosition(qt_index(doc['text'], active[1]), QTextCursor.MoveMode.KeepAnchor)
                selected.cursor = cursor;selected.format.setBackground(QColor('#ffedaa'));selections.append(selected)
                if self.follow.isChecked() and not self.editor.textCursor().hasSelection():
                    bar = self.editor.verticalScrollBar();rect = self.editor.cursorRect(cursor)
                    if rect.bottom()>self.editor.viewport().height() or rect.top()<0:bar.setValue(bar.value()+rect.top()-self.editor.viewport().height()//3)
            self.editor.setExtraSelections(selections)

        def match(self):
            self.flush_edit();doc = store.get(self.selected) if self.selected else None
            if not doc:return None
            cursor = self.editor.textCursor()
            return selection_match(doc, python_index(doc['text'],cursor.selectionStart()), python_index(doc['text'],cursor.selectionEnd()))

        def listen_selection(self):
            match = self.match()
            if match:self.play(match['start'], match['end'])
            else:self.status.setText(self.t('invalid_selection'))

        def save_quote(self):
            match = self.match();doc = store.get(self.selected) if self.selected else None
            if not match or not doc:self.status.setText(self.t('invalid_selection'));return
            match.update(speaker=self.speaker.text(), source=doc['name'])
            doc['quotes'].append(match);store.save(doc);self.refresh(doc['id']);self.status.setText(self.t('saved'))

        def copy_quote(self):
            doc = store.get(self.selected) if self.selected else None;index = self.quote_list.currentRow()
            if not doc or not 0<=index<len(doc['quotes']):return
            q = doc['quotes'][index]
            app.clipboard().setText(f"{q['text']}\n\n{q.get('speaker','')} · {q['source']} · {timestamp(q['start'])}–{timestamp(q['end'])}")
            self.status.setText(self.t('copied'))

        def copy_text(self):
            app.clipboard().setText(self.editor.toPlainText());self.status.setText(self.t('copied'))

        def export(self):
            self.flush_edit();doc = store.get(self.selected) if self.selected else None
            if not doc:return
            name, filter_used = QFileDialog.getSaveFileName(self, self.t('export'), Path(doc['name']).stem+'.txt', 'Text (*.txt);;SubRip (*.srt);;WebVTT (*.vtt)')
            if name:
                kind = 'srt' if '*.srt' in filter_used else 'vtt' if '*.vtt' in filter_used else 'txt'
                path = Path(name)
                if path.suffix.lower() not in ('.txt','.srt','.vtt'):path = path.with_suffix('.'+kind)
                try:path.write_text(export_text(doc,kind),encoding='utf-8');self.status.setText(self.t('saved'))
                except OSError as error:QMessageBox.warning(self,'Vocalia',str(error))

        def export_all(self):
            self.flush_edit();folder = QFileDialog.getExistingDirectory(self,self.t('batch_export'))
            if not folder:return
            try:
                for doc in store.documents():
                    if not doc['text']:continue
                    name = Path(doc['name']).stem;index = 0
                    while True:
                        target = Path(folder)/(name+('' if index==0 else f' ({index})')+'.txt')
                        try:
                            with target.open('x',encoding='utf-8') as stream:stream.write(doc['text'])
                            break
                        except FileExistsError:index += 1
                self.status.setText(self.t('saved'))
            except OSError as error:QMessageBox.warning(self,'Vocalia',str(error))

        def relink(self):
            doc = store.get(self.selected) if self.selected else None
            if not doc:return
            path,_ = QFileDialog.getOpenFileName(self,self.t('relink'))
            if path:
                self.media.stop();self.audio_review.reset();doc.pop('cleaned_source',None);doc['source'] = str(Path(path).resolve());store.save(doc);self.loaded_source = None

        def closeEvent(self, event):
            if self.proc:
                if QMessageBox.question(self,'Vocalia',self.t('close_confirm')) != QMessageBox.StandardButton.Yes:
                    event.ignore();return
                self.cancel()
                try:self.proc.wait(timeout=5)
                except subprocess.TimeoutExpired:event.ignore();return
                self.read_events();self.finish(self.proc.returncode)
            if self.tour is not None:self.tour.finish()
            self.library_ui.closed=True
            self.flush_edit();self.media.stop();store.close();lock.unlock();event.accept()

    window = Window()
    window.show()
    if not smoke and not store.setting('guided_tour_102_release', False):
        QTimer.singleShot(250, window.tutorial)
    if smoke:
        def test_gui():
            try:
                a = new_document('synthetic.wav');a.update(text='Hello world.',segments=[dict(start=0,end=2,text='Hello world.')],complete=True,status='done')
                b = new_document('second.wav')
                store.add(a);store.add(b);window.refresh(a['id'])
                window.pending_edit = (a['id'], 'Edited quote')
                window.remove_id(a['id'])
                window.pending_edit = (a['id'], 'Stale callback');window.flush_edit()
                assert store.get(b['id'])['text']=='' and store.get(a['id']) is None
                window.remove_id(b['id']);assert not store.documents()
                window.undo_remove();assert len(store.documents())==1
                window.interface.setCurrentIndex(1);assert window.buttons['add'].text()=='Add files'
                window.interface.setCurrentIndex(0);assert window.buttons['add'].text()=='Agregar archivos'
                # Check recovery from an abruptly terminated worker and from cancellation.
                failed = new_document('missing.mp3');failed['status'] = 'running';store.add(failed)
                for cancelled in (False, True):
                    window.job_dir = Path(tempfile.mkdtemp(prefix='failure-', dir=root))
                    window.job = {'task':'transcribe', 'id':failed['id']}
                    window.cancelled = cancelled;window.finish(-1)
                    assert store.get(failed['id'])['status'] == ('partial' if cancelled else 'error')
                    assert window.buttons['add'].isEnabled() and window.proc is None
                # Retrying cannot discard the edited partial transcript without a revision.
                partial = store.get(failed['id']);partial['text'] = 'Keep this edited partial quote';store.save(partial)
                original_launch = window.launch
                window.launch = lambda job: None
                window.queue = deque([partial['id']]);window.next_job()
                window.launch = original_launch
                revisions = list((root/'Revisions').glob('*.json'))
                assert len(revisions)==1 and json.loads(revisions[0].read_text(encoding='utf-8'))['text']=='Keep this edited partial quote'
                assert 'dos horas' in window.friendly_error('ValueError: DURATION_LIMIT')
                # Advanced results target their recording ID, preserve independently edited prose,
                # and cannot leak into the selected recording or be accepted after cancellation.
                advanced=new_document('voices.opus');advanced.update(complete=True,status='done',text='Editorially corrected quote',segments=[dict(start=0,end=2,text='Hello world.',words=[])])
                store.add(advanced);window.refresh(b['id'])
                for task,result in [('voices',{'turns':[dict(start=0,end=2,speaker='Speaker 1')]}),('compare',{'segments':[dict(start=0,end=2,text='Alternative') ]})]:
                    window.job_dir=Path(tempfile.mkdtemp(prefix='advanced-',dir=root))
                    atomic_json(window.job_dir/'result.json',result)
                    window.job={'task':task,'id':advanced['id'],'model':'medium'};window.cancelled=False;window.finish(0)
                    assert store.get(advanced['id'])['text']=='Editorially corrected quote'
                    assert window.selected!=advanced['id']
                window.refresh(advanced['id']);window.features.rlist.setCurrentRow(0)
                window.features.rtext.setPlainText('Human correction');window.features.reviewed.setChecked(True);window.features.save_segment()
                assert store.get(advanced['id'])['segments'][0]['reviewed']
                assert store.get(advanced['id'])['text']=='Editorially corrected quote'
                window.features.vlist.setCurrentRow(0);window.features.name.setText('María');window.features.rename()
                assert store.get(advanced['id'])['segments'][0]['speaker']=='María'
                assert window.features.vsegments.count()==1
                window.job_dir=Path(tempfile.mkdtemp(prefix='cancel-advanced-',dir=root))
                atomic_json(window.job_dir/'result.json',{'turns':[dict(start=0,end=2,speaker='Wrong')]})
                window.job={'task':'voices','id':advanced['id']};window.cancelled=True;window.finish(0)
                assert store.get(advanced['id'])['segments'][0]['speaker']=='María'
                window.cancelled=False
                # Real child process remains usable after the failed job; Unicode paths survive.
                folder = root / 'Entrevistas José';folder.mkdir()
                (folder / 'declaración.mp3').write_bytes(b'test')
                window.launch({'task':'scan', 'inputs':[str(folder)]})
                deadline = time.monotonic() + 30
                while window.proc and time.monotonic() < deadline:
                    app.processEvents();time.sleep(0.01)
                assert window.proc is None and any(d['name']=='declaración.mp3' for d in store.documents())
                # First launch must choose language before opening the main workspace.
                guide = WelcomeDialog('en')
                guide.language_box.setCurrentIndex(0);guide.next_button.click()
                assert guide.language=='es' and guide.result()==1
                guide2 = WelcomeDialog('en');guide2.next_button.click()
                assert guide2.language=='en' and guide2.result()==1
                # Coach marks stay inside the window, navigate, dismiss and reopen without doing work.
                before = len(store.documents())
                for language,_ in LANGUAGES:
                    window.interface.setCurrentIndex(window.interface.findData(language))
                    first=WelcomeDialog(language);assert first.language_box.currentData()==language
                    assert first.next_button.text()==tr('Continue',language)
                    assert window.features.dictionary_button.text()==tr('Personal dictionary',language)
                    window.tutorial();app.processEvents()
                    tour = window.tour
                    for index in range(len(STEPS)):
                        assert tour.index == index
                        assert window.rect().contains(tour.geometry())
                        assert tour.ring.isVisible() and tour.heading.text()
                        if index == 1:
                            tour.back.click();assert tour.index == 0;tour.next.click()
                        tour.next.click();app.processEvents()
                    assert window.tour is None and store.setting('guided_tour_102_release',False)
                    window.tutorial();window.tour.skip.click();assert window.tour is None
                assert len(store.documents()) == before and window.proc is None
                window.interface.setCurrentIndex(0)
                # The actual Transcribe button must prompt for the missing model, never play audio.
                original_question = QMessageBox.question
                QMessageBox.question = lambda *args: QMessageBox.StandardButton.No
                window.buttons['run'].click()
                assert window.status.text()==window.t('model_missing')
                assert window.media.playbackState()!=QMediaPlayer.PlaybackState.PlayingState
                QMessageBox.question = original_question
                fixture = os.environ.get('VOCALIA_E2E_FIXTURE')
                if fixture:
                    import shutil
                    for item in store.documents():store.remove(item['id'])
                    source = root/('Entrevista José'+Path(fixture).suffix);shutil.copyfile(fixture, source)
                    def wait_worker(timeout=900):
                        deadline=time.monotonic()+timeout
                        while time.monotonic()<deadline:
                            app.processEvents();time.sleep(0.02)
                            if window.proc is None and not window.run_after_prepare and not window.queue and not window.import_queue:return
                        raise AssertionError('GUI worker timeout')
                    # Declining the download still imports every queued recording.
                    declined=root/'declined.opus';shutil.copyfile(fixture,declined)
                    QMessageBox.question=lambda *args: QMessageBox.StandardButton.No
                    window.import_paths([str(source)]);window.import_paths([str(declined)]);wait_worker()
                    assert len(store.documents())==2 and all(not d.get('complete') for d in store.documents())
                    for item in store.documents():store.remove(item['id'])
                    window.model.addItem('tiny');window.model.setCurrentText('tiny')
                    window.audio.setCurrentIndex(window.audio.findData('en'))
                    # Import triggers the model prompt and real recognition without clicking Transcribe.
                    QMessageBox.question=lambda *args: QMessageBox.StandardButton.Yes
                    window.import_paths([str(source)]);wait_worker()
                    QMessageBox.question=original_question
                    finished=store.documents()[0]
                    assert finished['complete'] and 'country' in finished['text'].lower(), (finished, window.status.text())
                    assert window.media.playbackState()!=QMediaPlayer.PlaybackState.PlayingState
                    window.buttons['copy'].click();assert 'country' in app.clipboard().text().lower()
                    assert 'country' in export_text(finished, 'txt').lower()
                    # Duplicate imports must neither recognize again nor replace an edited transcript.
                    finished['text']='Protected edited quote';store.save(finished)
                    window.import_paths([str(source),str(source)]);wait_worker()
                    assert len(store.documents())==1 and store.get(finished['id'])['text']=='Protected edited quote'
                    old=new_document(str(root/'old-missing.wav'));old.update(text='Historical partial quote',status='partial');store.add(old)
                    extra=root/'extra.opus';later=root/'later.opus'
                    shutil.copyfile(fixture,extra);shutil.copyfile(fixture,later)
                    window.import_paths([str(extra)]);window.import_paths([str(later)])
                    wait_worker()
                    assert store.get(old['id'])['text']=='Historical partial quote' and store.get(old['id'])['status']=='partial'
                    assert sum(d.get('complete',False) for d in store.documents())==3
                    assert store.get(finished['id'])['text']=='Protected edited quote'
                    # Cancel the scan and discard deferred import requests. No automatic restart.
                    canceled=root/'canceled.opus';shutil.copyfile(fixture,canceled)
                    window.import_paths([str(canceled)]);window.import_paths([str(canceled)])
                    window.cancel();wait_worker()
                    assert not window.import_queue and not window.queue
                    assert not any(d['source']==str(canceled) for d in store.documents())
                    store.remove(old['id'])
                    original_info=QMessageBox.information
                    QMessageBox.information=lambda *args: QMessageBox.StandardButton.Ok
                    window.buttons['run'].click();assert window.status.text()==window.t('no_pending')
                    QMessageBox.information=original_info
                from PySide6.QtWidgets import QDialog,QLineEdit,QPushButton,QListWidget
                from PySide6.QtCore import QTimer
                window.interface.setCurrentIndex(window.interface.findData('en'))
                sample=new_document('sample.opus');sample.update(complete=True,status='done',text='The budget is 9.5 million.',segments=[dict(text='The budget is 9.5 million.',start=2,end=5,original_text='9 comma 5')],quotes=[dict(text='The budget is 9.5 million.',speaker='Ana',start=2,end=5)])
                store.add(sample);window.refresh(sample['id'])
                window.library_ui.figures();assert window.features.only_figures.isChecked() and window.features.rlist.count()==1
                def edit_metadata():
                    dialog=app.activeModalWidget();fields={f.placeholderText():f for f in dialog.findChildren(QLineEdit)}
                    listing=dialog.findChild(QListWidget)
                    for i in range(listing.count()):
                        if 'sample.opus' in listing.item(i).text():listing.setCurrentRow(i);break
                    fields['Project'].setText('Municipality');fields['Tags separated by commas'].setText('budget, interview');fields['Recording date YYYY-MM-DD'].setText('2026-09-17')
                    for b in dialog.findChildren(QPushButton):
                        if b.text()=='Save organization':b.click();break
                    dialog.accept()
                QTimer.singleShot(50,edit_metadata);window.library_ui.library()
                assert store.get(sample['id'])['project']=='Municipality'
                playback=[];old_play=window.play
                window.play=lambda **kw:playback.append(kw)
                def search_and_open():
                    dialog=app.activeModalWidget();fields={f.placeholderText():f for f in dialog.findChildren(QLineEdit)}
                    fields['Search all transcripts'].setText('budget')
                    def open_result():
                        if os.environ.get('VOCALIA_QA_IMAGES'):
                            target=Path(os.environ['VOCALIA_QA_IMAGES']);target.mkdir(parents=True,exist_ok=True);dialog.grab().save(str(target/'library-dialog.png'))
                        for b in dialog.findChildren(QPushButton):
                            if b.text()=='Open result and listen':b.click();break
                    QTimer.singleShot(300,open_result)
                QTimer.singleShot(50,search_and_open);window.library_ui.library();window.play=old_play
                assert playback==[dict(start=2,end=5)] and window.selected==sample['id']
                export_path=root/'Exported.docx';old_dialog=QFileDialog.getSaveFileName
                QFileDialog.getSaveFileName=lambda *a,**k:(str(export_path),'Word (*.docx)')
                def save_word():
                    dialog=app.activeModalWidget()
                    for b in dialog.findChildren(QPushButton):
                        if b.text()=='Save Word document':b.click();break
                QTimer.singleShot(50,save_word);window.library_ui.word();QFileDialog.getSaveFileName=old_dialog
                import zipfile
                assert '9.5 million' in zipfile.ZipFile(export_path).read('word/document.xml').decode()
                QTimer.singleShot(50,lambda:app.activeModalWidget().accept());window.library_ui.updates()
                assert not window.library_ui.checking
                from PySide6.QtGui import QDesktopServices
                opened=[];old_open=QDesktopServices.openUrl;QDesktopServices.openUrl=lambda url:opened.append(url.toString())
                update=dict(version='0.0.6',notes='Changes',download='https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.6/Vocalia-0.0.6-Windows-x64-Setup.exe',url='https://github.com/Francoocicchetti/Vocalia/releases/tag/v0.0.6')
                def inspect_update():
                    dialog=app.activeModalWidget();assert '0.0.6' in dialog.windowTitle()
                    assert dialog.findChild(QTextEdit).toPlainText()=='Changes'
                    if os.environ.get('VOCALIA_QA_IMAGES'):dialog.grab().save(str(Path(os.environ['VOCALIA_QA_IMAGES'])/'update-dialog.png'))
                    for b in dialog.findChildren(QPushButton):
                        if b.text()=='Release details':b.click();break
                    dialog.accept()
                QTimer.singleShot(50,inspect_update);window.library_ui.show_update(update,'',True);QDesktopServices.openUrl=old_open
                assert opened==[update['url']]
                from update_ui import UpdateDownloadDialog
                from types import SimpleNamespace
                install_calls=[]
                def local_download(release,root,cancel,progress):
                    folder=root/'synthetic-update';folder.mkdir(parents=True,exist_ok=True);path=folder/'setup.exe';path.write_bytes(b'synthetic fixture');progress(1,1);return path
                install_dialog=UpdateDownloadDialog(window,update,root/'Updates',downloader=local_download,launcher=lambda p,r:install_calls.append(str(p)))
                install_dialog.w=SimpleNamespace(language='en',proc=None,queue=[],import_queue=[],flush_edit=lambda:install_calls.append('saved'),close=lambda:install_calls.append('closed'))
                def install_fixture():
                    if not install_dialog.path:QTimer.singleShot(30,install_fixture);return
                    assert install_dialog.install.isEnabled() and install_dialog.progress.value()==100
                    if os.environ.get('VOCALIA_QA_IMAGES'):install_dialog.grab().save(str(Path(os.environ['VOCALIA_QA_IMAGES'])/'install-dialog.png'))
                    install_dialog.install.click()
                QTimer.singleShot(50,install_fixture);install_dialog.exec()
                assert install_calls[0]=='saved' and install_calls[-1]=='closed' and len(install_calls)==3
                if os.environ.get('VOCALIA_QA_IMAGES'):
                    target=Path(os.environ['VOCALIA_QA_IMAGES']);target.mkdir(parents=True,exist_ok=True)
                    for language,_ in LANGUAGES:
                        window.interface.setCurrentIndex(window.interface.findData(language));app.processEvents()
                        for tab in range(window.tabs.count()):
                            window.tabs.setCurrentIndex(tab);app.processEvents();window.grab().save(str(target/f'{language}-{tab}.png'))
                (root / 'GUI-PASS').write_text('PASS')
                if os.environ.get('VOCALIA_SMOKE_RESULT'):Path(os.environ['VOCALIA_SMOKE_RESULT']).write_text('PASS')
                window.close();app.exit(0)
            except Exception:
                import traceback
                traceback.print_exc();app.exit(1)
        QTimer.singleShot(200, test_gui)
    return app.exec()


if __name__ == '__main__':
    import multiprocessing
    multiprocessing.freeze_support()
    if len(sys.argv)>2 and sys.argv[1]=='--worker':
        from engine import run
        sys.exit(run(sys.argv[2]))
    sys.exit(main('--smoke-test' in sys.argv))
