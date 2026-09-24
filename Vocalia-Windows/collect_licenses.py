import importlib.metadata as metadata
import shutil
import sys
from pathlib import Path
root=Path(sys.argv[1]);root.mkdir(parents=True,exist_ok=True)
count=0
for dist in metadata.distributions():
    name=dist.metadata['Name']
    for entry in dist.files or []:
        if any(word in str(entry).lower() for word in ['license','licence','copyright','copying','notice']):
            path=Path(dist.locate_file(entry))
            if path.is_file():
                relative=Path(str(entry))
                safe=[p for p in relative.parts if p not in ('.','..')]
                target=root/name/Path(*safe);target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(path,target);count+=1
if not count:raise SystemExit('No dependency license files found')
print(f'Included {count} dependency license/notice files')
