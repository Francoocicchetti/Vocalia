"""Local review, independent recognition comparison and speaker tools."""
from PySide6.QtCore import Qt
from PySide6.QtWidgets import (QWidget,QVBoxLayout,QHBoxLayout,QLabel,QPushButton,
    QListWidget,QTextEdit,QLineEdit,QCheckBox,QComboBox,QSpinBox,QFileDialog,QMessageBox,QDialog)
from pathlib import Path
from library_core import has_figures
from i18n import tr
from core import timestamp,transcript_text
from advanced_core import edit_segment,rename_speaker,quote_citation,comparison_rows
from voices_engine import ready

class AdvancedUI:
    def __init__(self,window,store,root,app):
        self.w=window;self.store=store;self.root=root;self.app=app;self.doc=None;self.labels=[];self.buttons=[]
        self.review,self.rlayout=self.page();self.compare,self.clayout=self.page();self.voices,self.vlayout=self.page()
        self.only_review=QCheckBox();self.labels.append((self.only_review,'only_review'));self.rlayout.addWidget(self.only_review)
        self.only_review.toggled.connect(self.refresh_review)
        self.only_figures=QCheckBox();self.rlayout.addWidget(self.only_figures);self.only_figures.toggled.connect(self.refresh_review)
        self.rnote=self.label('review_note',self.rlayout)
        self.rlist=QListWidget();self.rlayout.addWidget(self.rlist);self.rlist.currentRowChanged.connect(self.select_segment)
        self.rtext=QTextEdit();self.rlayout.addWidget(self.rtext)
        self.rspeaker=QLineEdit();self.rlayout.addWidget(self.rspeaker)
        self.reviewed=QCheckBox();self.labels.append((self.reviewed,'reviewed'));self.rlayout.addWidget(self.reviewed)
        row=QHBoxLayout();self.rlayout.addLayout(row)
        self.button('listen',row,self.listen_segment);self.button('save',row,self.save_segment);self.button('restore_original',row,self.restore_segment)
        self.label('compare_note',self.clayout)
        row=QHBoxLayout();self.clayout.addLayout(row)
        self.second_model=QComboBox();self.second_model.addItems(['small','medium','large-v3-turbo','large-v3']);self.second_model.setCurrentText('medium');row.addWidget(self.second_model)
        self.button('prepare_second',row,lambda:self.w.launch({'task':'prepare','model':self.second_model.currentText()}))
        self.button('compare_run',row,self.run_comparison)
        self.differences=QCheckBox();self.differences.setChecked(True);self.labels.append((self.differences,'differences_only'));self.clayout.addWidget(self.differences);self.differences.toggled.connect(self.refresh_comparison)
        self.clist=QListWidget();self.clayout.addWidget(self.clist);self.clist.currentRowChanged.connect(self.select_comparison)
        self.cfirst=QTextEdit();self.cfirst.setReadOnly(True);self.cfirst.setMinimumHeight(90);self.csecond=QTextEdit();self.csecond.setReadOnly(True);self.csecond.setMinimumHeight(90)
        row=QHBoxLayout();row.addWidget(self.cfirst);row.addWidget(self.csecond);self.clayout.addLayout(row)
        row=QHBoxLayout();self.clayout.addLayout(row);self.button('listen',row,self.listen_comparison);self.button('copy_second',row,self.copy_second)
        self.label('voices_note',self.vlayout)
        self.voice_status=QLabel();self.voice_status.setWordWrap(True);self.vlayout.addWidget(self.voice_status)
        row=QHBoxLayout();self.vlayout.addLayout(row)
        self.button('prepare_voices',row,lambda:self.w.launch({'task':'prepare_voices'}))
        self.count=QSpinBox();self.count.setRange(0,20);row.addWidget(self.count)
        self.button('analyze_voices',row,self.run_voices)
        self.vlist=QListWidget();self.vlist.setMaximumHeight(110);self.vlayout.addWidget(self.vlist)
        self.vsegments=QListWidget();self.vlayout.addWidget(self.vsegments)
        self.button('listen',self.vlayout,self.listen_voice)
        self.name=QLineEdit();self.vlayout.addWidget(self.name)
        self.button('assign_name',self.vlayout,self.rename)
        # Quote actions use the same saved source/timing as the Mac app.
        qlayout=self.w.tabs.widget(1).layout();row=QHBoxLayout();qlayout.addLayout(row)
        self.button('quote_plain',row,self.copy_plain_quote);self.button('quote_listen',row,self.listen_quote);self.button('export_quotes',row,self.export_quotes)
        self.dictionary_button=QPushButton();self.dictionary_button.clicked.connect(self.dictionary);self.w.vocabrow.addWidget(self.dictionary_button)
        self.speed=QComboBox()
        for value in [0.75,1.0,1.25,1.5,2.0]:self.speed.addItem(f'{value:g}×',value)
        self.speed.setCurrentIndex(1);self.speed.currentIndexChanged.connect(lambda:self.w.media.setPlaybackRate(self.speed.currentData()))
        self.w.playbackrow.addWidget(self.speed)
        for pane,key in [(self.review,'review'),(self.compare,'comparison'),(self.voices,'voices')]:self.w.tabs.addTab(pane,key)
        self.retranslate()
    def page(self):
        widget=QWidget();return widget,QVBoxLayout(widget)
    def label(self,key,layout):
        label=QLabel();label.setWordWrap(True);layout.addWidget(label);self.labels.append((label,key));return label
    def button(self,key,layout,action):
        button=QPushButton();button.clicked.connect(action);layout.addWidget(button);self.buttons.append((button,key));return button
    def retranslate(self):
        self.only_figures.setText(tr("Figures only",self.w.language))
        for label,key in self.labels+self.buttons:label.setText(self.w.t(key))
        for pane,key in [(self.review,'review'),(self.compare,'comparison'),(self.voices,'voices')]:self.w.tabs.setTabText(self.w.tabs.indexOf(pane),self.w.t(key))
        self.dictionary_button.setText(self.w.t('dictionary'));self.rspeaker.setPlaceholderText(self.w.t('speaker'));self.name.setPlaceholderText(self.w.t('speaker'))
        self.count.setSpecialValueText(self.w.t('automatic'));self.count.setPrefix(self.w.t('speaker_count')+': ');self.speed.setToolTip(self.w.t('speed'))
        self.refresh(self.doc)
    def set_busy(self,busy):
        for widget in [self.review,self.compare,self.voices,self.dictionary_button,self.speed]:widget.setEnabled(not busy)
        for button,_ in self.buttons:button.setEnabled(not busy)
    def refresh(self,doc):
        self.doc=doc;self.refresh_review();self.refresh_comparison();self.vlist.clear()
        for speaker in sorted(set(s.get('speaker','') for s in (doc or {}).get('segments',[]))-{''}):self.vlist.addItem(speaker)
        self.vsegments.clear()
        for segment in (doc or {}).get('segments',[]):self.vsegments.addItem(timestamp(segment['start'])[:-4]+' · '+segment.get('speaker','')+'\n'+segment['text'])
        self.voice_status.setText(self.w.t('voices_ready' if ready(self.root/'Models') else 'voices_missing'))
    def refresh_review(self):
        self.rlist.clear()
        self.review_indices=[]
        for i,s in enumerate((self.doc or {}).get('segments',[])):
            if self.only_review.isChecked() and s.get('reviewed'):continue
            if self.only_figures.isChecked() and not has_figures(s):continue
            self.review_indices.append(i)
            prefix='✓ ' if s.get('reviewed') else '⚑ ' if s.get('uncertain') else ''
            self.rlist.addItem(prefix+timestamp(s['start'])[:-4]+' · '+s.get('speaker','')+'\n'+s['text'])
        if self.rlist.count():self.rlist.setCurrentRow(0)
        else:self.rtext.clear();self.rspeaker.clear();self.reviewed.setChecked(False)
    def segment(self):
        row=self.rlist.currentRow()
        if self.doc and 0<=row<len(self.review_indices):return self.review_indices[row],self.doc['segments'][self.review_indices[row]]
        return None,None
    def select_segment(self,*_):
        _,s=self.segment()
        if s:self.rtext.setPlainText(s['text']);self.rspeaker.setText(s.get('speaker',''));self.reviewed.setChecked(s.get('reviewed',False))
    def save_segment(self):
        i,s=self.segment()
        if s and not self.w.proc:
            self.w.flush_edit();doc=self.store.get(self.doc['id'])
            if doc:self.store.save(edit_segment(doc,i,self.rtext.toPlainText(),self.rspeaker.text(),self.reviewed.isChecked()));self.w.refresh(doc['id'])
    def restore_segment(self):
        _,s=self.segment()
        if s:self.rtext.setPlainText(s.get('original_text',s['text']));self.reviewed.setChecked(False)
    def listen_segment(self):
        _,s=self.segment()
        if s:self.w.play(s['start'],s['end'])
    def run_comparison(self):
        if not self.doc or not self.doc.get('complete'):return
        model=self.second_model.currentText()
        if model==self.doc.get('recognition_model'):
            QMessageBox.information(self.w,'Vocalia',self.w.t('different_model'));return
        if not (self.root/'Models'/(model+'.ready')).exists():
            QMessageBox.information(self.w,'Vocalia',self.w.t('prepare_second_first'));return
        self.w.launch({'task':'compare','id':self.doc['id'],'source':self.doc['source'],'model':model,'language':self.doc.get('language'),'terms':self.w.terms.text().split(',')[:100]})
    def refresh_comparison(self):
        self.clist.clear();self.cfirst.clear();self.csecond.clear();self.comparison=[]
        if not self.doc:return
        for row in comparison_rows(self.doc.get('segments',[]),self.doc.get('comparison_segments',[])) if 'comparison_segments' in self.doc else []:
            if self.differences.isChecked() and not row['differs']:continue
            self.comparison.append(row);self.clist.addItem(('≠ ' if row['differs'] else '= ')+timestamp(row['start'])[:-4]+'–'+timestamp(row['end'])[:-4])
        if self.clist.count():self.clist.setCurrentRow(0)
    def select_comparison(self,*_):
        index=self.clist.currentRow()
        if not 0<=index<len(self.comparison):return
        row=self.comparison[index]
        self.cfirst.setPlainText(self.doc.get('recognition_model','Whisper')+'\n\n'+row['first']);self.csecond.setPlainText(self.doc.get('comparison_model','Whisper')+'\n\n'+row['second'])
    def listen_comparison(self):
        i=self.clist.currentRow()
        if 0<=i<len(self.comparison):r=self.comparison[i];self.w.play(r['start'],r['end'])
    def copy_second(self):
        if self.doc:self.app.clipboard().setText(transcript_text(self.doc.get('comparison_segments',[])))
    def run_voices(self):
        if not self.doc or not self.doc.get('complete'):return
        if not ready(self.root/'Models'):
            QMessageBox.information(self.w,'Vocalia',self.w.t('voices_missing'));return
        self.w.launch({'task':'voices','id':self.doc['id'],'source':self.doc['source'],'speaker_count':self.count.value()})
    def listen_voice(self):
        i=self.vsegments.currentRow()
        if self.doc and 0<=i<len(self.doc.get('segments',[])):
            s=self.doc['segments'][i];self.w.play(s['start'],s['end'])
    def rename(self):
        item=self.vlist.currentItem()
        if self.doc and item and self.name.text().strip() and not self.w.proc:
            self.w.flush_edit();doc=self.store.get(self.doc['id'])
            if doc:self.store.save(rename_speaker(doc,item.text(),self.name.text()));self.w.refresh(doc['id'])
    def quote(self):
        i=self.w.quote_list.currentRow();doc=self.store.get(self.w.selected) if self.w.selected else None
        return doc['quotes'][i] if doc and 0<=i<len(doc.get('quotes',[])) else None
    def copy_plain_quote(self):
        q=self.quote()
        if q:self.app.clipboard().setText(q['text'])
    def listen_quote(self):
        q=self.quote()
        if q:self.w.play(q['start'],q['end'])
    def export_quotes(self):
        doc=self.store.get(self.w.selected) if self.w.selected else None
        if not doc or not doc.get('quotes'):return
        path,_=QFileDialog.getSaveFileName(self.w,self.w.t('export_quotes'),Path(doc['name']).stem+'-quotes.txt','Text (*.txt)')
        if path:
            try:Path(path).write_text('\n\n———\n\n'.join(quote_citation(q) for q in doc['quotes']),encoding='utf8')
            except OSError as e:QMessageBox.warning(self.w,'Vocalia',str(e))
    def dictionary(self):
        dialog=QDialog(self.w);dialog.setWindowTitle(self.w.t('dictionary'));dialog.resize(520,400);layout=QVBoxLayout(dialog)
        note=QLabel(self.w.t('dictionary_note'));note.setWordWrap(True);layout.addWidget(note)
        editor=QTextEdit();editor.setPlainText('\n'.join(t.strip() for t in self.w.terms.text().split(',') if t.strip()));layout.addWidget(editor)
        save=QPushButton(self.w.t('save'));layout.addWidget(save)
        def commit():
            terms=list(dict.fromkeys(t.strip()[:100] for t in editor.toPlainText().replace('\n',',').split(',') if t.strip()))[:100]
            self.w.terms.setText(', '.join(terms));dialog.accept()
        save.clicked.connect(commit);dialog.exec()
