import json,hashlib,re,subprocess
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];REP=ROOT/'reports/codex-art-99b'
result={'automatic_checks':[],'manual_limits':['Doron 2 approximately 2.51 heads; Jupi 3 approximately 2.57 heads, manual +/-1px.','Doron 3 and Jupi illustrations use less than 88% canvas height for the human figure.'],'commit_script_executed':False,'godot_execution':False}
def check(name,ok):
    result['automatic_checks'].append({'name':name,'passed':bool(ok)})
    if not ok:raise AssertionError(name)
metrics=json.loads((REP/'metrics.json').read_text(encoding='utf-8'))
for c,n in [('doron',1),('doron',2),('doron',3),('jupi',2),('jupi',3)]:
    folder=ROOT/f'art/bakeoff/newchar-2026-11-26/{c}/{n}';key=f'{c}-{n}'
    for typ,name,size in [('illustration',f'{c}_illustration-{n}.png',(1024,1536)),('face',f'{c}_face-{n}.png',(256,256)),('idle',f'{c}-idle-{n}.png',(128,128))]:
        p=folder/name;im=Image.open(p);a=np.asarray(im)
        check(key+' '+typ+' size/mode',im.size==size and im.mode=='RGBA')
        check(key+' '+typ+' alpha',a[:,:,3].min()==0 and a[:,:,3].max()==255)
        if typ=='idle':
            visible=a[:,:,3]>0;ys,xs=np.where(visible)
            check(key+' feet',int(ys.max())==120)
            check(key+' margin',min(int(xs.min()),int(ys.min()),127-int(xs.max()),127-int(ys.max()))>=4)
            check(key+' binary alpha',set(np.unique(a[:,:,3]).tolist())=={0,255})
            rgb=a[:,:,:3].astype(np.int16)
            check(key+' no green spill',not np.any(visible&(rgb[:,:,1]>np.maximum(rgb[:,:,0],rgb[:,:,2])+20)))
            check(key+' detail >=90%',metrics['looks'][key]['sprite']['detail_ratio_percent']>=90)
            normalized=next((REP/f'normalize-{c}-{n}/frames').glob('*.png'))
            check(key+' copied frame exact',Image.open(normalized).tobytes()==im.tobytes())
    meta=json.loads((folder/f'{c}-idle-{n}.json').read_text(encoding='utf-8'))
    check(key+' metadata',meta.get('frames')==1 and bool(re.search('[가-힣]',meta.get('note',''))))
    for entry in metrics['looks'][key]['files']:
        p=ROOT/entry['path'];check(entry['path']+' sha256',hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'])
for name in ['concepts.png','lineup.png','faces.png','attempts-contact.png']:
    check(name+' exists',(REP/name).is_file())
check('lineup dimensions',Image.open(REP/'lineup.png').size==(4000,1340))
for p in REP.iterdir():
    if p.suffix in {'.md','.txt','.json','.py','.ps1'} and p.name!='verification.json':
        txt=p.read_text(encoding='utf-8-sig');check(p.name+' UTF-8', '\ufffd' not in txt)
script=(REP/'commit.ps1').read_text(encoding='utf-8');literal=re.search(r'\[string\[\]\]\$paths = @\((.*?)\n\)',script,re.S).group(1)
paths=re.findall(r"^\s*'([^']+)'\s*$",literal,re.M)
allowed=['art/bakeoff/newchar-2026-11-26/doron/','art/bakeoff/newchar-2026-11-26/jupi/2/','art/bakeoff/newchar-2026-11-26/jupi/3/','reports/codex-art-99b/']
check('commit literal array',len(paths)>=20)
check('commit paths scope',all(p=='design/tasks/CODEX-ART-99.md' or any(p.startswith(prefix) for prefix in allowed) for p in paths))
check('no forced add or raw path','git add -f' not in script and not any(p.startswith('art/raw/') for p in paths))
check('commit footer',(REP/'commit-message.txt').read_text(encoding='utf-8').rstrip().endswith('Co-Authored-By: Codex <noreply@openai.com>'))
check('expected branch',subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()=='codex/newchar-99b')
for args,name in [(['git','diff','--name-only'],'tracked diff'),(['git','diff','--cached','--name-only'],'staged diff')]:
    lines=subprocess.check_output(args,cwd=ROOT,text=True).splitlines();result[name]=lines
    check(name+' contains no unrelated changes',all(any(p.startswith(prefix) for prefix in allowed) for p in lines))
roots=[ROOT/'art/raw/newchar-99b',REP,ROOT/'art/bakeoff/newchar-2026-11-26/doron',ROOT/'art/bakeoff/newchar-2026-11-26/jupi/2',ROOT/'art/bakeoff/newchar-2026-11-26/jupi/3']
result['task_folder_bytes']={p.relative_to(ROOT).as_posix():sum(f.stat().st_size for f in p.rglob('*') if f.is_file()) for p in roots}
result['all_automatic_checks_passed']=True
result['automatic_check_count']=len(result['automatic_checks'])
(REP/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(result['automatic_checks']),'passed':True,'task_bytes':sum(result['task_folder_bytes'].values()),'product_changed':False},ensure_ascii=False))
