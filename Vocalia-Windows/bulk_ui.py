"""Checked recordings are independent of the recording open in the editor."""
from pathlib import Path
from collections import deque
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QPushButton, QHBoxLayout, QLabel, QMenu, QMessageBox, QFileDialog, QInputDialog
from core import export_text
from library_core import word_document
from i18n import tr


class BulkUI:
    def __init__(self, window, layout):
        self.w=window;self.ids=set();self.busy=False
        row=QHBoxLayout();layout.addLayout(row)
        self.all=QPushButton();self.clear=QPushButton()
        row.addWidget(self.all);row.addWidget(self.clear)
        self.all.clicked.connect(lambda:self.select(True));self.clear.clicked.connect(lambda:self.select(False))
        self.count=QLabel();layout.addWidget(self.count)
        self.button=QPushButton();layout.addWidget(self.button)
        self.menu=QMenu(self.button);self.button.setMenu(self.menu)
        self.actions=[]
        for label,callback in [('Transcribe selected pending',self.transcribe),('Transcribe selection again…',lambda:self.transcribe(True)),('Assign project…',self.project)]:
            self.actions.append((self.menu.addAction(label,callback),label))
        self.menu.addSeparator()
        for kind in ('txt','srt','vtt','docx'):
            label='Export selection: '+kind.upper()
            self.actions.append((self.menu.addAction(label,lambda checked=False,kind=kind:self.export(kind)),label))
        self.menu.addSeparator()
        self.actions.append((self.menu.addAction('Remove selection from history…',lambda:self.remove(self.selected_ids())),'Remove selection from history…'))
        window.list.itemChanged.connect(self.changed)

    def t(self,text):return tr(text,self.w.language)

    def selected_ids(self):
        return [d['id'] for d in self.w.store.documents() if d['id'] in self.ids]

    def configure(self,row):
        flags=row.flags()|Qt.ItemFlag.ItemIsUserCheckable
        if self.busy:flags &= ~Qt.ItemFlag.ItemIsUserCheckable
        row.setFlags(flags)
        row.setCheckState(Qt.CheckState.Checked if row.data(Qt.ItemDataRole.UserRole) in self.ids else Qt.CheckState.Unchecked)

    def changed(self,row):
        if self.busy:return
        ident=row.data(Qt.ItemDataRole.UserRole)
        if row.checkState()==Qt.CheckState.Checked:self.ids.add(ident)
        else:self.ids.discard(ident)
        self.update_count()

    def select(self,all):
        if self.busy:return
        self.ids={d['id'] for d in self.w.store.documents()} if all else set()
        self.w.list.blockSignals(True)
        for i in range(self.w.list.count()):self.configure(self.w.list.item(i))
        self.w.list.blockSignals(False);self.update_count()

    def update_count(self):
        self.count.setText(self.t('{count} selected').replace('{count}',str(len(self.ids))))
        self.button.setEnabled(not self.busy and bool(self.ids))
        self.all.setEnabled(not self.busy and self.w.list.count()>0)
        self.clear.setEnabled(not self.busy and bool(self.ids))

    def retranslate(self):
        self.all.setText(self.t('Select all'));self.clear.setText('×');self.clear.setFixedWidth(30)
        self.clear.setToolTip(self.t('Clear selection'));self.clear.setAccessibleName(self.t('Clear selection'))
        self.button.setText(self.t('Actions for selection'))
        for action,label in self.actions:action.setText(self.t(label))
        self.update_count()

    def set_busy(self,busy):
        self.busy=busy
        self.w.list.blockSignals(True)
        for i in range(self.w.list.count()):self.configure(self.w.list.item(i))
        self.w.list.blockSignals(False);self.update_count()

    def remove(self,ids):
        if self.busy or not ids:return
        self.w.flush_edit()
        message=self.t('Remove {count} recordings from history? Original files are kept. You can restore the last removed group.').replace('{count}',str(len(ids)))
        if QMessageBox.question(self.w,'Vocalia',message)!=QMessageBox.StandardButton.Yes:return
        try:self.w.remove_ids(ids)
        except Exception as error:QMessageBox.warning(self.w,'Vocalia',str(error))

    def transcribe(self,again=False):
        if self.busy:return
        ids=self.selected_ids()
        if not ids:return
        if not again:self.w.start_ids(ids);return
        if QMessageBox.question(self.w,'Vocalia',self.t('Transcribe {count} selected recordings again? Existing text will be backed up before replacement.').replace('{count}',str(len(ids))))!=QMessageBox.StandardButton.Yes:return
        if not (self.w.audio_review.root/'Models'/(self.w.model.currentText()+'.ready')).exists():
            QMessageBox.information(self.w,'Vocalia',self.w.t('model_missing'));return
        self.w.flush_edit();self.w.queue=deque(ids);self.w.next_job()

    def project(self):
        if self.busy:return
        ids=self.selected_ids()
        value,ok=QInputDialog.getText(self.w,self.t('Assign project…'),self.t('Project (blank removes assignment)'))
        if ok and not self.busy:
            self.w.flush_edit()
            try:self.w.store.assign_project(ids,value);self.w.refresh()
            except Exception as error:QMessageBox.warning(self.w,'Vocalia',str(error))

    def export(self,kind):
        if self.busy:return
        self.w.flush_edit();ids=set(self.selected_ids())
        documents=[d for d in self.w.store.documents() if d['id'] in ids and d.get('text','').strip()]
        if not documents:QMessageBox.information(self.w,'Vocalia',self.t('No text to export in the selection.'));return
        folder=QFileDialog.getExistingDirectory(self.w,self.t('Actions for selection'))
        if not folder:return
        try:
            for doc in documents:
                content=word_document(doc,doc['name'],doc.get('recorded_date',''),doc.get('quotes',[]),{k:self.t(v) for k,v in [('project','Project'),('tags','Tags'),('text','Full transcript'),('quotes','Selected quotes')]}) if kind=='docx' else export_text(doc,kind).encode('utf-8')
                base=Path(doc['name']).stem;index=0
                while True:
                    target=Path(folder)/(base+('' if not index else f' ({index})')+'.'+kind)
                    try:
                        with target.open('xb') as stream:stream.write(content)
                        break
                    except FileExistsError:index+=1
            self.w.status.setText(self.t('Selection exported. Existing files were kept.'))
        except Exception as error:QMessageBox.warning(self.w,'Vocalia',str(error))
