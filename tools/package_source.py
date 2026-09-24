"""Package tracked source and pinned vendor archives; never user data or models."""
import subprocess
import sys
import zipfile
from pathlib import Path
paths=subprocess.check_output(['git','ls-files','-z']).decode().split('\0')
with zipfile.ZipFile(sys.argv[1],'w',zipfile.ZIP_DEFLATED) as archive:
    for name in paths:
        if not name:continue
        path=Path(name)
        if path.suffix=='.zip' and name not in ('Vendor.zip','OpusDecoder-source.zip'):continue
        if path.suffix.lower() in ('.caf','.wav','.m4a','.mp3','.mp4','.mov','.exe','.sqlite3'):continue
        if path.is_file():archive.write(path,'Vocalia-source/'+name)
