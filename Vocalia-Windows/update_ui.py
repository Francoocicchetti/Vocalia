import threading,shutil
from pathlib import Path
from PySide6.QtCore import QObject,Signal
from PySide6.QtWidgets import QDialog,QVBoxLayout,QLabel,QProgressBar,QPushButton,QMessageBox
from i18n import tr
from update_install import download,DownloadCancelled,launch_installer
class DownloadEvents(QObject):
    progress=Signal(int,int)
    done=Signal(str,str)

class UpdateDownloadDialog(QDialog):
    def __init__(self,window,release,root,downloader=download,launcher=launch_installer):
        super().__init__(window)
        self.w=window;self.release=release;self.root=root;self.launcher=launcher
        self.cancelled=threading.Event();self.path=None;self.installing=False
        self.events=DownloadEvents(self);self.events.progress.connect(self.on_progress);self.events.done.connect(self.on_done)
        self.setWindowTitle(self.t('Update Vocalia')+' · '+release['version']);self.resize(520,230)
        layout=QVBoxLayout(self);self.status=QLabel(self.t('Downloading update…'));self.status.setWordWrap(True);layout.addWidget(self.status)
        self.progress=QProgressBar();self.progress.setRange(0,100);layout.addWidget(self.progress)
        note=QLabel(self.t('Your history, quotes and models will be preserved.'));note.setWordWrap(True);layout.addWidget(note)
        self.install=QPushButton(self.t('Install update'));self.install.setEnabled(False);self.install.clicked.connect(self.install_update);layout.addWidget(self.install)
        self.cancel_button=QPushButton(self.t('Cancel'));self.cancel_button.clicked.connect(self.reject);layout.addWidget(self.cancel_button)
        def worker():
            try:
                path=downloader(release,root,self.cancelled,lambda a,b:self.events.progress.emit(a,b));self.events.done.emit(str(path),'')
            except DownloadCancelled:pass
            except Exception:
                try:self.events.done.emit('','Could not download or verify the update. Try again.')
                except RuntimeError:pass
        threading.Thread(target=worker,daemon=True).start()
    def t(self,key):return tr(key,self.w.language)
    def on_progress(self,done,total):self.progress.setValue(int(done*100/max(1,total)))
    def on_done(self,path,error):
        if self.cancelled.is_set():
            if path:shutil.rmtree(Path(path).parent,ignore_errors=True)
            return
        if error:self.status.setText(self.t(error));self.cancel_button.setText(self.t('Close'));return
        self.path=Path(path);self.progress.setValue(100);self.install.setEnabled(True)
        self.status.setText(self.t('Update verified. Installing will close Vocalia and open the setup wizard.'))
    def install_update(self):
        if self.w.proc or self.w.queue or self.w.import_queue:
            QMessageBox.information(self,'Vocalia',self.t('Wait for transcription and imports to finish before installing.'));return
        if not self.path:return
        try:
            self.w.flush_edit()
            self.launcher(self.path,self.release)
            self.installing=True;self.accept();self.w.close()
        except Exception:self.status.setText(self.t('Could not start installation. Vocalia has not been changed.'))
    def reject(self):
        self.cancelled.set()
        if self.path and not self.installing:shutil.rmtree(self.path.parent,ignore_errors=True)
        super().reject()
