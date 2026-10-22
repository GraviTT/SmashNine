"""Validate final files, raw reconstruction, scope and contact constraints."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, math
from PIL import Image, ImageDraw
import numpy as np
import rebuild as r

def reach_board():
    motion=r.load_json(r.REPORT/'manual_motion.json')['reach']
    for mid in r.IDS[:2]:
        panel=Image.new('RGB',(860,950),(22,27,39));d=ImageDraw.Draw(panel)
        d.text((10,3),f'{mid} | old top / new bottom | exact 4x',font=r.n.font(18),fill='white')
        for phase in [0,1]:
            for col,(row,idx) in enumerate([('windup',3),('attack',2)]):
                path=(r.FIX/'before' if phase==0 else r.BAKE)/f'{mid}-{row}-v1.png'
                im=r.frames(path,row)[idx]
                x=40+col*420;y=65+phase*440
                panel.paste(r.cell_tile(im),(x,y))
                d.text((x,y-38),f'{row} F{idx+1} {"before" if phase==0 else "after"}',font=r.n.font(18),fill='white')
                for k in range(0,97,8):
                    d.line((x+k*4,y,x+k*4,y+384),fill=(72,79,94),width=1)
                    d.line((x,y+k*4,x+384,y+k*4),fill=(72,79,94),width=1)
                    d.text((x+k*4,y-18),str(k),font=r.n.font(10),fill='white')
                    d.text((x-24,y+k*4),str(k),font=r.n.font(10),fill='white')
        panel.save(r.FIX/f'{mid}-reach-grid-4x.png')

def main():
    base=r.load_json(r.FIX/'baseline.json'); config=r.load_json(r.FIX/'config.json')
    sizes=r.load_json(r.FIX/'sizes.json')
    failures=[]; checked=[]; changed=[]; raw_checks=[]
    for mid in r.IDS:
        assembled=Image.open(r.BAKE/f'{mid}_sheet-v1.png').convert('RGBA')
        if assembled.size!=(576,576): failures.append(f'{mid}: assembled size')
        for ri,row in enumerate(r.ROWS):
            name=f'{mid}-{row}-v1';path=r.BAKE/f'{name}.png'
            ims=r.frames(path,row); old=r.frames(r.FIX/'before'/path.name,row)
            before_meta=r.load_json(r.FIX/'before'/f'{name}.json');meta=r.load_json(r.BAKE/f'{name}.json')
            factor=config['factors'][mid][ri]
            assert meta['factor']==factor
            assert {k:v for k,v in meta.items() if k not in ['note','factor','size_review']}=={k:v for k,v in before_meta.items() if k not in ['note','factor','size_review']}
            sheet=Image.open(path).convert('RGBA')
            if sheet.size!=(576,96):failures.append(f'{name}: row size')
            if sheet.tobytes()!=assembled.crop((0,ri*96,576,(ri+1)*96)).tobytes():failures.append(f'{name}: assembly mismatch')
            if np.count_nonzero(np.array(sheet.crop((r.COUNTS[row]*96,0,576,96)))[:,:,3]):failures.append(f'{name}: unused cells')
            is_changed=r.sha(path)!=r.sha(r.FIX/'before'/path.name)
            if is_changed:
                rebuilt,moves=r.rebuild_row(mid,row,factor,config.get('extra_x',{}).get(mid,{}).get(row))
                equal=all(a.tobytes()==b.tobytes() for a,b in zip(ims,rebuilt))
                if not equal:failures.append(f'{name}: raw reproduction mismatch')
                changed.append(dict(monster=mid,row=row,frames=len(ims),sha256=r.sha(path)))
                raw_checks.append(dict(monster=mid,row=row,raw_sha256=r.sha(r.RAW/f'{mid}-{row}.png'),
                    common_factor=factor,pixel_equal=equal,alpha_pixels_preserved=True,placements=moves))
            seen=set()
            for i,im in enumerate(ims):
                box=im.getbbox();a=np.array(im);minmargin=r.n.margins(box,96)['minimum']
                digest=__import__('hashlib').sha256(im.tobytes()).hexdigest()
                detail=r.n.interior_detail(im)
                item=dict(monster=mid,row=row,frame=i+1,bbox=list(box),margin=minmargin,detail=detail,
                          spill=r.n.spill_pixel_count(im),bottom=box[3]-1,alpha_binary=set(np.unique(a[:,:,3]))<={0,255})
                checked.append(item)
                if minmargin<3 or not item['alpha_binary'] or item['spill'] or digest in seen:
                    failures.append(f'{name} F{i+1}: margin/alpha/spill/duplicate')
                seen.add(digest)
                # Ground and wolf's existing leap arc must not be sacrificed to fit.
                if mid in [r.IDS[0],r.IDS[1],r.IDS[2],r.IDS[4]] or row=='defeat':
                    if item['bottom']!=old[i].getbbox()[3]-1:failures.append(f'{name} F{i+1}: contact/arc changed')
    for d in sizes:
        if not d['nominal_within_5pct']:failures.append(f"{d['monster']}/{d['row']}: nominal ruler outside 5pct")
    protected_changes=[p for p,h in base['protected'].items() if not (r.ROOT/p).is_file() or r.sha(r.ROOT/p)!=h]
    raw_changes=[p for p,h in base['raws'].items() if r.sha(r.RAW/p)!=h]
    index_unchanged=r.sha(__import__('pathlib').Path(base['git_index_path']))==base['git_index_sha256']
    if protected_changes or raw_changes or not index_unchanged:failures.append('protected files/raw/git index changed')
    out=dict(monsters=6,rows=36,frames=len(checked),changed_rows=changed,changed_frame_count=sum(d['frames'] for d in changed),
             min_margin=min(d['margin'] for d in checked),detail_below_85=[d for d in checked if d['detail']<85],
             source_raw_rebuild_checks=raw_checks,frame_checks=checked,protected_file_count=len(base['protected']),
             protected_changes=protected_changes,raw_changes=raw_changes,index_unchanged=index_unchanged,
             failures=failures)
    r.dump(r.FIX/'verification.json',out)
    reach_board()
    print(json.dumps({k:out[k] for k in ['monsters','rows','frames','changed_frame_count','min_margin','detail_below_85','protected_file_count','protected_changes','raw_changes','index_unchanged','failures']},ensure_ascii=False))
    assert not failures,failures

if __name__=='__main__': main()
