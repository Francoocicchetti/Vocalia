"""Verified in-app downloads. The existing per-user installer handles replacement."""
import hashlib,os,re,shutil,subprocess,sys,tempfile,urllib.request
from pathlib import Path
from updates import REPOSITORY,version_tuple
MAX_DOWNLOAD=1024*1024*1024
class DownloadCancelled(Exception):pass

def validate_release(release):
    version=release.get('version','');tag=release.get('tag','v'+version)
    if not version_tuple(version) or tag!='v'+version:raise ValueError('Invalid update version')
    name=f'Vocalia-{version}-Windows-x64-Setup.exe'
    if release.get('download')!=f'{REPOSITORY}/releases/download/{tag}/{name}':raise ValueError('Invalid update URL')
    digest=release.get('digest','')
    if not re.fullmatch(r'sha256:[0-9a-fA-F]{64}',digest):raise ValueError('Missing update checksum')
    size=release.get('size',0)
    if not isinstance(size,int) or not 0<size<=MAX_DOWNLOAD:raise ValueError('Invalid update size')
    return name,digest.split(':')[1].lower(),size

def verify_file(path,release):
    _,expected,size=validate_release(release);path=Path(path)
    if path.is_symlink() or path.stat().st_size!=size:raise ValueError('Update size mismatch')
    digest=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):digest.update(chunk)
    if digest.hexdigest()!=expected:raise ValueError('Update checksum mismatch')

def download(release,root,cancel,progress,opener=urllib.request.urlopen):
    name,expected,size=validate_release(release)
    root=Path(root);root.mkdir(parents=True,exist_ok=True)
    folder=Path(tempfile.mkdtemp(prefix='download-',dir=root));partial=folder/'download.part';target=folder/name
    try:
        request=urllib.request.Request(release['download'],headers={'User-Agent':'Vocalia/update'})
        total=0;digest=hashlib.sha256()
        with opener(request,timeout=20) as response,partial.open('xb') as output:
            if getattr(response,'status',200)!=200:raise ValueError('Update download failed')
            while True:
                if cancel.is_set():raise DownloadCancelled()
                chunk=response.read(256*1024)
                if not chunk:break
                total+=len(chunk)
                if total>size:raise ValueError('Update is larger than expected')
                output.write(chunk);digest.update(chunk);progress(total,size)
        if cancel.is_set():raise DownloadCancelled()
        if total!=size or digest.hexdigest()!=expected:raise ValueError('Update checksum mismatch')
        partial.replace(target);return target
    except BaseException:
        shutil.rmtree(folder,ignore_errors=True);raise

def installer_command(path,release,executable=None):
    verify_file(path,release)
    target=Path(executable or sys.executable).resolve().parent
    return [str(Path(path).resolve()),'/NORESTART','/SP-',f'/DIR={target}']

def launch_installer(path,release):
    if sys.platform!='win32' or not getattr(sys,'frozen',False):raise RuntimeError('Install updates from the packaged Windows app')
    return subprocess.Popen(installer_command(path,release),close_fds=True)
