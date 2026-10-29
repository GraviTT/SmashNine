"""Verify delivered ART-88 artifacts without running Godot or touching git index."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, subprocess, hashlib
from pathlib import Path
import numpy as np
from PIL import Image
from audit import ROOT, OUT, BAKE, metrics, digest
from repair import dump
def main():
    base=json.loads((OUT/'baseline.json').read_text('utf-8'));changes=json.loads((OUT/'repairs.json').read_text('utf-8'));delivery=json.loads((OUT/'delivery.json').read_text('utf-8'))
    checks=[];known=[]
    def check(name,ok,detail=None):checks.append(dict(name=name,pass_=bool(ok),detail=detail))
    rows=[]
    for c in changes:
        if not c['output']:
            p=ROOT/c['source'];expected=next(x for x in base['cases'] if x['id']==c['id'])['versions']['latest']['sha256']
            check(c['id']+' unchanged',digest(p)==expected)
            for item in c['unresolved']:known.append(dict(id=c['id'],**item))
            continue
        p=ROOT/c['output'];im=Image.open(p);a=np.asarray(im)
        check(c['id']+' RGBA 576x96',im.mode=='RGBA' and im.size==(576,96))
        check(c['id']+' review equals delivery',digest(p)==digest(OUT/'review-rows'/p.name))
        meta=json.loads(p.with_suffix('.json').read_text('utf-8'));original=next(x for x in base['cases'] if x['id']==c['id'])['versions']['latest']['metadata']
        check(c['id']+' frames fps loop cell feet preserved',all(meta.get(k)==original.get(k) for k in ['frames','fps','loop','cell','feet']))
        check(c['id']+' note replaces',c['id'] in meta['note'] and meta['replaces']==f'{c["monster"]}-{c["row"]}-v1.png')
        check(c['id']+' binary alpha',set(np.unique(a[:,:,3]))<={0,255})
        check(c['id']+' empty trailing cells',not a[:,meta['frames']*96:,3].any())
        before=Image.open(OUT/'before'/Path(c['source']).name).convert('RGBA')
        for o in c['operations']:
            i=o['frame']-1;crop=im.crop((96*i,0,96*(i+1),96));old=before.crop((96*i,0,96*(i+1),96))
            m=metrics(crop);check(c['id']+f' F{i+1} measured metrics',m==o['after'])
            check(c['id']+f' F{i+1} outer clear',m['solid']['outer_1px']==0)
            is_known=any(x['frame']==i+1 for x in c['unresolved'])
            if is_known:known.append(dict(id=c['id'],frame=i+1,reason=c['unresolved'][0]['reason'],margin=m['solid']['minimum_margin']))
            else:check(c['id']+f' F{i+1} margin4',m['visible']['minimum_margin']>=4)
            if not o['changed']:check(c['id']+f' F{i+1} untouched',np.array_equal(crop,old))
            if c['scale']==1 and c['id']!='C09':
                # Whole figure translations must preserve every visible RGBA sample.
                oldsub=np.asarray(old.crop(old.getbbox()));newsub=np.asarray(crop.crop(crop.getbbox()))
                check(c['id']+f' F{i+1} translation preserves RGBA',np.array_equal(oldsub,newsub))
            if c['id']!='C13':check(c['id']+f' F{i+1} baseline bottom kept',m['solid']['bbox'][3]==o['before']['solid']['bbox'][3])
        rows.append(dict(id=c['id'],path=c['output'],frames=meta['frames'],changed_frames=c['changed_frames']))
    for item in base['metadata']:
        p=ROOT/item['path'];before=item['before'];after=json.loads(p.read_text('utf-8'))
        added=next(x for x in delivery['metadata'] if x['path']==item['path'])['added']
        check(item['path']+' additions only',set(after)-set(before)==set(added) and all(after[k]==v for k,v in before.items()))
        check(item['path']+' complete',all(k in after for k in ['cell','feet','loop']) and type(after['loop']) is bool)
        png=Image.open(p.with_suffix('.png'));check(item['path']+' cell geometry',png.height==after['cell'] and png.width%after['cell']==0)
    for sh in delivery['sheets']:
        im=Image.open(ROOT/sh['path']).convert('RGBA');check(sh['path']+' geometry',im.size==(576,576))
        for i,r in enumerate(sh['rows']):
            p=ROOT/r['path'];check(sh['path']+' '+r['row']+' pixels',np.array_equal(im.crop((0,i*96,576,(i+1)*96)),Image.open(p).convert('RGBA')))
            latest=BAKE/(Path(r['path']).name.replace('-v1.png','-v2.png'))
            check(sh['path']+' '+r['row']+' latest',not latest.exists() or latest==p)
    allowed_png={x for x in delivery['rows'] if x.endswith('.png')}|{x['path'] for x in delivery['sheets']}
    unchanged=0
    for path,sha in base['protected'].items():
        if path not in allowed_png:
            check(path+' baseline hash',digest(ROOT/path)==sha);unchanged+=1
    for raw in [c['raw'] for c in changes if c['raw']]:check(raw['path']+' raw unchanged',digest(ROOT/raw['path'])==raw['sha256'])
    sizes=json.loads((OUT/'sizes.json').read_text('utf-8'))
    for s in sizes:
        c=next(x for x in changes if x['id']==s['id']);check(s['id']+' size sample bound to final PNG',s['output_sha256']==digest(ROOT/c['output']))
        check(s['id']+' representative size +/-5%',.95<=s['ratio']<=1.05)
    # Prior ART-76 fix-1 movement ruler, transported exactly with each frame.
    wind=Image.open(BAKE/'muspelheim_magma_boar-windup-v2.png').convert('RGBA').crop((288,0,384,96))
    attack=Image.open(BAKE/'muspelheim_magma_boar-attack-v2.png').convert('RGBA').crop((192,0,288,96))
    reach=dict(part='멧돼지 앞 엄니 외곽: windup F4 → attack F3',before_points=[[84,64],[92,59]],after_points=[[85,64],[91,59]],before_dx=8,after_dx=6,uncertainty_px=2,interpretation='정수 평행이동으로 간격이 2px 줄었음. 실제 게임 이동량/공격 판정 아님; 새 4px 여백과 종전 전진 목표를 함께 유지할 수 없어 공개.')
    check('boar reach transported points opaque',wind.getpixel((85,64))[3]==255 and attack.getpixel((91,59))[3]==255)
    changed_paths=subprocess.check_output(['git','diff','--name-only'],cwd=ROOT,text=True).splitlines()
    allowed=set(delivery['rows'])|{x['path'] for x in delivery['metadata']}|{x['path'] for x in delivery['sheets']}
    check('tracked changes within delivery',set(changed_paths)<=allowed,changed_paths)
    check('product and tools unchanged',not subprocess.check_output(['git','diff','--name-only','--','smash-nine-prototype','tools'],cwd=ROOT,text=True).strip())
    check('index empty',not subprocess.check_output(['git','diff','--cached','--name-only'],cwd=ROOT,text=True).strip())
    check('no report bytecode',not list(OUT.rglob('__pycache__')))
    failed=[x for x in checks if not x['pass_']]
    result=dict(status='PASS_WITH_DECLARED_UNRESOLVED' if not failed else 'FAIL',checks=len(checks),failures=failed,known_unresolved=known,rows=rows,sheet_count=len(delivery['sheets']),metadata_count=len(delivery['metadata']),changed_frame_count=sum(len(x['changed_frames']) for x in changes),protected_hashes_unchanged=unchanged,side_effect=reach,godot_run=False,image_tool_calls=0,all_checks=checks)
    dump(OUT/'verification.json',result)
    print(json.dumps({k:v for k,v in result.items() if k not in ['all_checks','rows']},ensure_ascii=False,indent=2))
    assert not failed
if __name__=='__main__':main()
