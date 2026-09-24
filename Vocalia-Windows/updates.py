"""Anonymous, bounded GitHub release checks; never sends local file data."""
import json,re,urllib.request,datetime
VERSION='0.0.6'
REPOSITORY='https://github.com/Francoocicchetti/Vocalia'
API='https://api.github.com/repos/Francoocicchetti/Vocalia/releases?per_page=30'
EPOCH='2026-09-17T00:00:00Z' # Earlier 1.x tags were prototype labels before the numbering reset.

def version_tuple(tag):
    match=re.fullmatch(r'v?(\d+)\.(\d+)\.(\d+)',tag)
    return tuple(map(int,match.groups())) if match else None

def choose_release(releases,platform='Windows',current=VERSION):
    candidates=[]
    for release in releases:
        tag=release.get('tag_name','');version=version_tuple(tag)
        if not version or version<=version_tuple(current) or release.get('draft') or release.get('published_at','')<EPOCH:continue
        url=REPOSITORY+'/releases/tag/'+tag
        if release.get('html_url')!=url:continue
        filename=f'Vocalia-{tag.lstrip("v")}-'+('Windows-x64-Setup.exe' if platform=='Windows' else 'macOS-AppleSilicon.zip')
        download=REPOSITORY+'/releases/download/'+tag+'/'+filename
        asset=next((a for a in release.get('assets',[]) if a.get('name')==filename and a.get('browser_download_url')==download),None)
        if not asset:continue
        candidates.append(dict(version=tag.lstrip('v'),url=url,download=download,notes=str(release.get('body') or '')[:100000],published=release['published_at'],tag=tag,digest=asset.get('digest',''),size=asset.get('size',0)))
    return max(candidates,key=lambda r:version_tuple(r['version']),default=None)

def check():
    request=urllib.request.Request(API,headers={'Accept':'application/vnd.github+json','User-Agent':'Vocalia/'+VERSION})
    with urllib.request.urlopen(request,timeout=15) as response:
        raw=response.read(2000001)
    if len(raw)>2000000:raise ValueError('Release response is too large')
    return choose_release(json.loads(raw))
