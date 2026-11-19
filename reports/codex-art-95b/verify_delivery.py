"""Validate saved candidates; does not stage, commit or run Godot."""
from pathlib import Path
import ast
import hashlib
import json
import re
import subprocess
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
R=ROOT/'reports/codex-art-95b'
checks=[]
def check(label,passed):
    checks.append({'check':label,'passed':bool(passed)})
    if not passed: raise AssertionError(label)

def git(*args):
    return subprocess.run(['git',*args],cwd=ROOT,check=True,capture_output=True,text=True,encoding='utf-8').stdout.strip()

def main():
    m=json.loads((R/'metrics.json').read_text(encoding='utf-8'))
    for k in 'ef':
        base=ROOT/f'art/bakeoff/xion/{k}'
        p=base/f'xion-idle-{k}.png';im=Image.open(p);a=np.array(im)
        check(k+' sprite 128x128 RGBA',im.size==(128,128) and im.mode=='RGBA')
        al=a[:,:,3];ys,xs=np.nonzero(al)
        check(k+' one-pixel border empty',not np.any(np.r_[al[0],al[-1],al[:,0],al[:,-1]]))
        check(k+' four-pixel margin',min(xs.min(),ys.min(),127-xs.max(),127-ys.max())>=4)
        check(k+' 95-100px height',95<=ys.max()-ys.min()+1<=100)
        check(k+' feet at y120',ys.max()==120)
        check(k+' binary alpha',set(np.unique(al).tolist())=={0,255})
        rgb=a[:,:,:3].astype(np.int16)
        check(k+' no green spill',not np.any((al>0)&(rgb[:,:,1]>rgb[:,:,0]+20)&(rgb[:,:,1]>rgb[:,:,2]+20)))
        normal=R/f'normalize-{k}/frames/xion-idle-{k}-00.png'
        check(k+' unchanged normalizer frame',np.array_equal(a,np.array(Image.open(normal))))
        check(k+' >=90% Rio detail',m['concepts'][k]['sprite']['interior_detail_ratio']>=.9)
        note=json.loads((base/f'xion-idle-{k}.json').read_text(encoding='utf-8'))
        check(k+' JSON one frame and Korean note',note['frames']==1 and any('\uac00'<=c<='\ud7a3' for c in note['note']))
        im=Image.open(base/f'xion_illustration-{k}.png');a=np.array(im);al=a[:,:,3]
        check(k+' illustration 1024x1536 RGBA',im.size==(1024,1536) and im.mode=='RGBA')
        check(k+' illustration alpha range',al.min()==0 and al.max()==255)
        check(k+' illustration border empty',not np.any(np.r_[al[0],al[-1],al[:,0],al[:,-1]]))
        stats=m['concepts'][k]['illustration']
        for field in ['transparent_rgb_residue_pixels','green_fringe_pixels','weak_alpha_beyond_2px_support']:
            check(k+' '+field,stats[field]==0)
        check(k+' main sample opaque',stats['main_sample']['min']==255)
        check(k+' hologram sample 40-70%',102<=stats['hologram_sample']['min']<=stats['hologram_sample']['max']<=179)
    check('lineup size',Image.open(R/'lineup.png').size==(2400,1360))
    check('4x review size',Image.open(R/'idle-review-4x.png').size==(1088,1128))
    roots=[R,ROOT/'art/bakeoff/xion/e',ROOT/'art/bakeoff/xion/f']
    for root in roots:
        for p in root.rglob('*'):
            if p.suffix.lower() in {'.json','.txt','.md','.py','.ps1'}:
                data=p.read_bytes();txt=data.decode('utf-8')
                check(p.relative_to(ROOT).as_posix()+' UTF8/LF','\ufffd' not in txt and b'\r\n' not in data)
                if p.suffix=='.json':json.loads(txt)
                if p.suffix=='.py':ast.parse(txt)
    script=(R/'commit.ps1').read_text(encoding='utf-8')
    pathblock=script.split('$paths = @(',1)[1].split('\n)',1)[0]
    paths=re.findall(r"'([^']+)'",pathblock)
    allowed=('art/bakeoff/xion/e/','art/bakeoff/xion/f/','reports/codex-art-95b/')
    check('commit paths literal and scoped',len(paths)>=30 and all(p=='design/tasks/CODEX-ART-95.md' or p.startswith(allowed) for p in paths))
    check('commit excludes raw and force-add',all(not p.startswith('art/raw/') for p in paths) and 'git add -f' not in script and 'ConvertFrom-Json' not in script)
    check('commit coauthor trailer','Co-Authored-By: Codex <noreply@openai.com>' in script)
    check('correct branch',git('branch','--show-current')=='codex/xion-95b')
    check('product tracked diff empty',git('diff','--name-only','--','smash-nine-prototype')=='')
    check('staging untouched',git('diff','--cached','--name-only')=='')
    roots.append(ROOT/'art/raw/xion-95b')
    total=sum(p.stat().st_size for root in roots for p in root.rglob('*') if p.is_file())
    result={'passed':all(c['passed'] for c in checks),'check_count':len(checks),'checks':checks,
      'scope':'E/F task directories only','task_total_bytes':total,
      'not_run':['Godot','game integration','commit.ps1'],
      'files':[{ 'path':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
       for k in 'ef' for p in sorted((ROOT/f'art/bakeoff/xion/{k}').iterdir()) if p.is_file()]}
    (R/'verification.json').write_bytes((json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    print(json.dumps({'passed':result['passed'],'checks':len(checks),'task_MiB':round(total/1024/1024,2),'files':result['files']},ensure_ascii=False,indent=2))

if __name__=='__main__':main()
