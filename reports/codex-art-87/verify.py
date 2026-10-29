"""Read-only candidate checks; writes only ART-87 measurements.json."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
from pathlib import Path
import hashlib,json,ast
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-art-87'
OUT=ROOT/'art/bakeoff/monsters/legacy'
RAW=ROOT/'art/raw/monsters-87'
ROWS=['idle','walk','attack','hurt']; COUNTS=[4,6,4,1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):
    im=Image.open(p);assert im.mode=='RGBA' and im.size==(576,384),(p,im.mode,im.size)
    return np.array(im)
def box(a):
    y,x=np.where(a[:,:,3]>0)
    return [int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)] if len(x) else None
def cell(a,r,c):return a[r*96:(r+1)*96,c*96:(c+1)*96]
items=[];total_changed=total_identical=total_used_identical=0
for jp in sorted(OUT.glob('*.json')):
    d=json.loads(jp.read_text(encoding='utf-8'));id=d['id'];p=jp.with_suffix('.png');gp=ROOT/d['replaces']
    assert sha(gp)==d['original_file_sha256']==sha(RAW/(id+'_sheet.png'))
    assert sha(p)==d['candidate_file_sha256']
    before=read(gp);after=read(p)
    claimed={(ROWS.index(f['row']),f['frame']-1):f for f in d['frames']}
    actual=[];same=[];checks=[];used_same=0
    for r in range(4):
        for c in range(6):
            old=cell(before,r,c);new=cell(after,r,c)
            if c>=COUNTS[r]:assert not new[:,:,3].any()
            if old.tobytes()==new.tobytes():
                same.append([r,c]);used_same+=int(c<COUNTS[r]);continue
            actual.append((r,c));assert (r,c) in claimed
            f=claimed[(r,c)];b=box(new);assert b==f['after']['bbox_alpha1']
            assert b[0]>=4 and b[1]>=4 and b[2]<=92 and b[3]<=92,(id,r,c,b)
            if 'feet_boundary' in f:
                target=f['feet_boundary']
                if 'body_feet_roi' in f:
                    x1,y1,x2,y2=f['body_feet_roi'];assert box(new[y1:y2,x1:x2])[3]+y1==target
                else:assert b[3]==target,(id,r,c,b,target)
            assert (ROOT/f['source']).is_file(),f['source']
            checks.append({'row':ROWS[r],'frame':c+1,'bbox_alpha1':b,'rgba_sha256':hashlib.sha256(new.tobytes()).hexdigest(),'minimum_margin_px':min(b[0],b[1],96-b[2],96-b[3])})
    assert set(actual)==set(claimed)
    assert same==d['unchanged_cells_rgba_identical']
    total_changed+=len(actual);total_identical+=len(same);total_used_identical+=used_same
    items.append({'id':id,'changed':len(actual),'identical_cells':len(same),'identical_used_frames':used_same,'candidate_sha256':sha(p),'frames':checks})

# Rim provenance: ART-17 added outlines but did not alter the preserved solid body.
rim=[]
for id in ['ember_imp','mossling']:
    base=read(RAW/(id+'_before_art17.png'));game=read(ROOT/f'smash-nine-prototype/assets/art/monsters/{id}_sheet.png')
    solid=base[:,:,3]>30
    assert np.array_equal(base[solid],game[solid])
    rim.append({'id':id,'pre_art17_solid_rgba_exact_in_game':True,'solid_pixels':int(solid.sum()),'added_or_changed_rim_pixels':int(np.any(base!=game,axis=2).sum())})

# Every copied repository input still matches its read-only original.
inputs=[]
for p in sorted(RAW.glob('*_source.png')):
    gp=ROOT/'smash-nine-prototype/assets/art/monsters'/p.name
    assert gp.exists() and sha(gp)==sha(p)
    inputs.append({'path':str(gp.relative_to(ROOT)).replace('\\','/'),'sha256':sha(p)})
assert len(items)==15 and total_changed==76 and total_identical==284 and total_used_identical==149
for name in ['repair.py','verify.py','package.py']:ast.parse((REPORT/name).read_text(encoding='utf-8'))
result={'status':'PASS','scope':'PNG, source provenance, metadata, untouched RGBA, static script syntax; no Godot or runtime test','sheets':15,'changed_frames':total_changed,'unchanged_used_frames':total_used_identical,'unchanged_cells_including_empty':total_identical,'empty_cells':135,'changed_frames_minimum_margin_px':min(f['minimum_margin_px'] for i in items for f in i['frames']),'rim_comparison':rim,'inputs':inputs,'candidates':items}
(REPORT/'measurements.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k not in ['rim_comparison','inputs','candidates']},ensure_ascii=True))
