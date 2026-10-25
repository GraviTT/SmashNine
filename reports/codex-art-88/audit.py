"""Read-only input inventory and QA-23's alpha boundary measurements."""
import os
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'
import json, re, hashlib
from pathlib import Path
import numpy as np
from PIL import Image
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'reports/codex-art-88'
BAKE = ROOT/'art/bakeoff/monsters'
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def metrics(im):
    a=np.asarray(im.convert('RGBA'))[:,:,3]
    result={}
    for name,mask in [('solid',a>=128),('visible',a>0)]:
        yy,xx=np.where(mask)
        box=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
        margin=[box[0],box[1],96-box[2],96-box[3]]
        edge=np.ones((96,96),bool);edge[4:92,4:92]=False
        outer=np.ones((96,96),bool);outer[1:95,1:95]=False
        top=mask[box[1],:];runs=[];run=0
        for v in top:
            run=run+1 if v else 0;runs.append(run)
        result[name]=dict(bbox=box,margins_ltrb=margin,minimum_margin=min(margin),inside_4px=int((mask&edge).sum()),outer_1px=int((mask&outer).sum()),area=int(mask.sum()),top_run=max(runs))
    return result
def main():
    target=OUT/'baseline.json'
    if target.exists(): raise RuntimeError('Baseline already exists; never overwrite original evidence')
    lines=(ROOT/'qa23/fix-list.md').read_text('utf-8').splitlines()
    cases=[]
    for line in lines:
        if not re.match(r'\| C\d\d ',line):continue
        cols=line.split('|'); cid=re.search(r'C\d\d',cols[1])[0]
        mid=re.search(r'\[([^]]+)_sheet-v1.png\]',cols[2])[1]
        row,fs=cols[3].strip().split(' · ')
        indices=[int(x) for x in re.findall(r'\d+',fs)]
        v1=BAKE/f'{mid}-{row}-v1.png';v2=BAKE/f'{mid}-{row}-v2.png';latest=v2 if v2.exists() else v1
        meta=json.loads(latest.with_suffix('.json').read_text('utf-8'))
        versions={}
        for key,p in [('qa_v1',v1),('latest',latest)]:
            im=Image.open(p).convert('RGBA')
            versions[key]=dict(path=p.relative_to(ROOT).as_posix(),sha256=digest(p),metadata=json.loads(p.with_suffix('.json').read_text('utf-8')),frames=[dict(frame=i+1,**metrics(im.crop((i*96,0,(i+1)*96,96)))) for i in range(meta['frames'])])
        cases.append(dict(id=cid,monster=mid,row=row,listed_frames=indices,versions=versions))
    metadata=[]
    for issue in json.loads((ROOT/'ref81/issues.json').read_text('utf-8')):
        if issue['check']!='metadata':continue
        p=ROOT/Path(issue['path']).with_suffix('.json')
        metadata.append(dict(path=p.relative_to(ROOT).as_posix(),sha256=digest(p),before=json.loads(p.read_text('utf-8')),audit_value=issue['value']))
    protected={}
    for folder,pattern in [('art/bakeoff','*.png'),('qa23','*'),('ref81','*')]:
        for p in (ROOT/folder).rglob(pattern):
            if p.is_file(): protected[p.relative_to(ROOT).as_posix()]=digest(p)
    data=dict(cases=cases,metadata=metadata,protected=protected)
    target.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n','utf-8')
    for c in cases:
        f=c['versions']['latest']['frames']
        print(c['id'],c['monster'],c['row'],Path(c['versions']['latest']['path']).stem)
        for v in f:
            if v['frame'] in c['listed_frames'] or v['solid']['inside_4px']:
                print(' F',v['frame'],'bbox',v['solid']['bbox'],'margin',v['solid']['minimum_margin'],'4px count',v['solid']['inside_4px'])
    print('metadata',len(metadata),'protected',len(protected))
if __name__=='__main__':main()
