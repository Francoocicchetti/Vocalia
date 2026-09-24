"""Library, Word export and user-controlled update installation."""
import datetime,time,threading
from pathlib import Path
from PySide6.QtCore import Qt,QTimer,QUrl,QObject,Signal
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import QDialog,QVBoxLayout,QHBoxLayout,QLabel,QLineEdit,QComboBox,QListWidget,QListWidgetItem,QPushButton,QTextEdit,QCheckBox,QMessageBox,QFileDialog
from i18n import tr
from library_core import library_search,normalized_tags,word_document
from core import timestamp
from updates import check,VERSION

class UpdateSignal(QObject):
    ready=Signal(object,str,bool)

class LibraryUI:
    def __init__(self,w,store,header,smoke):
        self.w=w;self.store=store;self.smoke=smoke;self.checking=False;self.closed=False
        self.signal=UpdateSignal(w);self.signal.ready.connect(self.show_update)
        self.buttons=[]
        for key,action in [('Library and projects',self.library),('Review figures',self.figures),('Export Word',self.word),('Update Vocalia',self.updates)]:
            b=QPushButton();b.clicked.connect(action);header.addWidget(b);self.buttons.append((b,key))
        self.retranslate()
        if not smoke:
            QTimer.singleShot(3000,self.auto_check)
            self.update_timer=QTimer(w);self.update_timer.setInterval(3600000);self.update_timer.timeout.connect(self.auto_check);self.update_timer.start()
    def t(self,key):return tr(key,self.w.language)
    def retranslate(self):
        for b,key in self.buttons:b.setText(self.t(key))
    def label(self,layout,text):
        label=QLabel(self.t(text));label.setWordWrap(True);layout.addWidget(label);return label
    def button(self,layout,text,callback):
        b=QPushButton(self.t(text));b.clicked.connect(callback);layout.addWidget(b);return b
    def figures(self):
        self.w.features.only_figures.setChecked(True);self.w.features.only_review.setChecked(False);self.w.tabs.setCurrentWidget(self.w.features.review)
    def library(self):
        self.w.flush_edit()
        dialog=QDialog(self.w);dialog.setWindowTitle(self.t('Library and projects'));dialog.resize(820,650)
        layout=QVBoxLayout(dialog)
        query=QLineEdit();query.setPlaceholderText(self.t('Search all transcripts'));layout.addWidget(query)
        filters=QHBoxLayout();layout.addLayout(filters)
        project=QComboBox();project.addItem(self.t('All projects'),'')
        for value in sorted({d.get('project','') for d in self.store.documents()}-{''}):project.addItem(value,value)
        filters.addWidget(project)
        tag=QLineEdit();tag.setPlaceholderText(self.t('Filter by tag'));filters.addWidget(tag)
        after=QLineEdit();after.setPlaceholderText(self.t('From YYYY-MM-DD'));filters.addWidget(after)
        before=QLineEdit();before.setPlaceholderText(self.t('To YYYY-MM-DD'));filters.addWidget(before)
        self.label(layout,'Up to 200 results. Dates refer to the recording date you assign.')
        results=QListWidget();layout.addWidget(results,1)
        fields=QHBoxLayout();layout.addLayout(fields)
        project_edit=QLineEdit();project_edit.setPlaceholderText(self.t('Project'));fields.addWidget(project_edit)
        tags=QLineEdit();tags.setPlaceholderText(self.t('Tags separated by commas'));fields.addWidget(tags)
        date=QLineEdit();date.setPlaceholderText(self.t('Recording date YYYY-MM-DD'));fields.addWidget(date)
        self.label(layout,'Projects and tags organize your history without moving original files.')
        hits=[]
        def refresh():
            nonlocal hits
            hits=library_search(self.store.documents(),query.text(),project.currentData(),tag.text(),after.text(),before.text())
            results.clear()
            for hit in hits:results.addItem(hit['name']+' · '+(timestamp(hit['start'])[:-4] if hit['start'] is not None else self.t('No exact audio position'))+'\n'+hit['excerpt'])
            if hits:results.setCurrentRow(0)
            else:project_edit.clear();tags.clear();date.clear()
        def selected():
            i=results.currentRow();return hits[i] if 0<=i<len(hits) else None
        def selection():
            hit=selected();doc=self.store.get(hit['id']) if hit else None
            if doc:project_edit.setText(doc.get('project',''));tags.setText(', '.join(doc.get('tags',[])));date.setText(doc.get('recorded_date',''))
        def save():
            hit=selected()
            if not hit:return
            doc=self.store.get(hit['id'])
            if not doc:return
            value=date.text().strip()
            try:
                if value:datetime.date.fromisoformat(value)
            except ValueError:QMessageBox.warning(dialog,'Vocalia',self.t('Use a valid date in YYYY-MM-DD format.'));return
            doc.update(project=project_edit.text().strip()[:120],tags=normalized_tags(tags.text()),recorded_date=value);self.store.save(doc)
            value=doc['project']
            if value and project.findData(value)<0:project.addItem(value,value)
            self.w.refresh(self.w.selected);refresh()
        def open_hit():
            hit=selected()
            if not hit:return
            self.w.refresh(hit['id']);self.w.tabs.setCurrentWidget(self.w.editor);dialog.accept()
            if hit['start'] is not None:self.w.play(start=hit['start'],end=hit['end'])
        row=QHBoxLayout();layout.addLayout(row)
        self.button(row,'Save organization',save);self.button(row,'Open result and listen',open_hit);self.button(row,'Close',dialog.accept)
        results.currentRowChanged.connect(lambda _:selection());results.itemDoubleClicked.connect(lambda _:open_hit())
        timer=QTimer(dialog);timer.setSingleShot(True);timer.setInterval(200);timer.timeout.connect(refresh)
        for field in [query,tag,after,before]:field.textChanged.connect(lambda:timer.start())
        project.currentIndexChanged.connect(refresh);refresh();dialog.exec()
    def word(self):
        self.w.flush_edit();doc=self.store.get(self.w.selected) if self.w.selected else None
        if not doc or not doc.get('text'):QMessageBox.information(self.w,'Vocalia',self.t('Select a transcript with text first.'));return
        dialog=QDialog(self.w);dialog.setWindowTitle(self.t('Export Word'));dialog.resize(600,460);layout=QVBoxLayout(dialog)
        self.label(layout,'Document title');title=QLineEdit(Path(doc['name']).stem);layout.addWidget(title)
        self.label(layout,'Recording date YYYY-MM-DD');date=QLineEdit(doc.get('recorded_date') or datetime.date.today().isoformat());layout.addWidget(date)
        self.label(layout,'Select saved quotes to include');quotes=QListWidget();layout.addWidget(quotes)
        for q in doc.get('quotes',[]):
            item=QListWidgetItem(q['text']);item.setFlags(item.flags()|Qt.ItemFlag.ItemIsUserCheckable);item.setCheckState(Qt.CheckState.Checked);quotes.addItem(item)
        def save():
            try:datetime.date.fromisoformat(date.text())
            except ValueError:QMessageBox.warning(dialog,'Vocalia',self.t('Use a valid date in YYYY-MM-DD format.'));return
            path,_=QFileDialog.getSaveFileName(dialog,self.t('Export Word'),Path(doc['name']).stem+'.docx','Word (*.docx)')
            if not path:return
            if not path.lower().endswith('.docx'):path+='.docx'
            chosen=[q for i,q in enumerate(doc.get('quotes',[])) if quotes.item(i).checkState()==Qt.CheckState.Checked]
            try:
                data=word_document(doc,title.text().strip() or Path(doc['name']).stem,date.text(),chosen,{k:self.t(v) for k,v in [('project','Project'),('tags','Tags'),('text','Full transcript'),('quotes','Selected quotes')]})
                from PySide6.QtCore import QSaveFile,QIODevice
                target=QSaveFile(path)
                if not target.open(QIODevice.OpenModeFlag.WriteOnly) or target.write(data)!=len(data) or not target.commit():raise OSError(target.errorString())
                dialog.accept();self.w.status.setText(self.t('Word document saved.'))
            except OSError as error:QMessageBox.warning(dialog,'Vocalia',str(error))
        self.button(layout,'Save Word document',save);dialog.exec()
    def auto_check(self):
        if not self.closed and self.store.setting('automatic_updates',True) and time.time()-self.store.setting('last_update_check',0)>86400:self.start_check(False)
    def start_check(self,manual):
        if self.checking:return
        self.checking=True;self.store.set_setting("last_update_check",time.time())
        def worker():
            try:release=check();error=''
            except Exception:release=None;error='Could not check updates. Check your internet connection and try again.'
            try:self.signal.ready.emit(release,error,manual)
            except RuntimeError:pass
        threading.Thread(target=worker,daemon=True).start()
    def updates(self):
        dialog=QDialog(self.w);dialog.setWindowTitle(self.t('Updates'));layout=QVBoxLayout(dialog)
        self.label(layout,'Vocalia '+VERSION)
        option=QCheckBox(self.t('Check for updates automatically'));option.setChecked(self.store.setting('automatic_updates',True));layout.addWidget(option)
        option.toggled.connect(lambda value:self.store.set_setting('automatic_updates',value))
        self.label(layout,'Checks contact GitHub once a day. Recordings and transcripts are never sent.')
        self.button(layout,'Check now',lambda:(dialog.accept(),self.start_check(True)));self.button(layout,'Close',dialog.accept);dialog.exec()
    def show_update(self,release,error,manual):
        self.checking=False
        if self.closed:return
        if not error:self.store.set_setting('last_update_check',time.time())
        if error:
            if manual:QMessageBox.information(self.w,'Vocalia',self.t(error))
            return
        if not release:
            if manual:QMessageBox.information(self.w,'Vocalia',self.t('You have the latest available version.'))
            return
        if not manual and self.store.setting('notified_update','')==release['version']:return
        self.store.set_setting('notified_update',release['version'])
        dialog=QDialog(self.w);dialog.setWindowTitle(self.t('Update available')+' · '+release['version']);dialog.resize(650,520);layout=QVBoxLayout(dialog)
        self.label(layout,'A new version is available. Your local history and models are preserved when installing in the same location.')
        notes=QTextEdit();notes.setReadOnly(True);notes.setPlainText(release['notes']);layout.addWidget(notes)
        self.label(layout,'Download and install from Vocalia. Your history, quotes and models stay on this computer.')
        def update():
            dialog.accept()
            from update_ui import UpdateDownloadDialog
            from app import data_root
            UpdateDownloadDialog(self.w,release,data_root()/'Updates').exec()
        self.button(layout,'Update now',update)
        self.button(layout,'Release details',lambda:QDesktopServices.openUrl(QUrl(release['url'])))
        self.button(layout,'Later',dialog.accept);dialog.exec()
