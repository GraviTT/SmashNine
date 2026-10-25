"""Head estimates for all fighter candidates, exact pixel cache from live frames."""
import sys
sys.dont_write_bytecode=True
import json,importlib.util,time
from pathlib import Path
from PIL import Image
from head_check import fft_scale
from audit import ROOT,OUT,ART,STEMS,dump,contact

def main():
    spec=importlib.util.spec_from_file_location('qa23_head_scale',ROOT/'tools/sprite_pipeline/head_scale.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
    cache={};templates={};refs={};started=time.monotonic()
    for stem in STEMS:
        ref=Image.open(ART/stem.split('_')[0]/f'{stem}_sheet.png').convert('RGBA').crop((0,0,128,128));refs[stem]=ref
        try:templates[stem]=mod.head_template(ref)
        except ValueError:continue
        heads=json.loads((OUT/'metrics/heads'/f'{stem}.json').read_text(encoding='utf-8'))
        for hr in heads['rows']:
            d=json.loads((OUT/'metrics'/f'{hr["sheet"]}.json').read_text(encoding='utf-8'));row=next(r for r in d['rows'] if r['name']==hr['row'])
            for f,h in zip(row['frames'],hr['frames']):cache[(stem,f['rgba_sha256'])]=h
    index=json.loads((OUT/'metrics/candidate_index.json').read_text(encoding='utf-8'));results=[]
    prev=OUT/'metrics/candidate_head_contacts.json'
    new_contacts=json.loads(prev.read_text(encoding='utf-8')) if prev.exists() else []
    for entry in index:
        if entry['kind']!='fighter_candidate':continue
        key=Path(entry['path']).stem;d=json.loads((OUT/'metrics/candidates'/f'{key}.json').read_text(encoding='utf-8'))
        stem=d['stem'];im=Image.open(ROOT/d['path']).convert('RGBA');cw,ch=d['cell'];result={'path':d['path'],'rows':[]}
        if stem not in templates:continue
        for r in d['rows']:
            fs=[];ims=[]
            for f in r['frames']:
                x=(f['sheet_column']-1)*cw;y=(f['sheet_row']-1)*ch;frame=im.crop((x,y,x+cw,y+ch));ims.append(frame);ck=(stem,f['rgba_sha256'])
                if ck in cache:h=dict(cache[ck]);h['cached']=True
                else:
                    scale,score=fft_scale(frame,templates[stem],mod);h={'scale':scale,'score':round(score,4),'accepted':scale is not None and score>=.6,'cached':False};cache[ck]=h
                h=dict(h);h['frame']=f['frame'];fs.append(h)
            accepted=[h['scale'] for h in fs if h['accepted']]
            import numpy as np
            median=float(np.median(accepted)) if accepted else None
            robust=len(accepted)>=max(1,(len(fs)+1)//2)
            flag=robust and median is not None and (median<.96 or median>1.04)
            result['rows'].append({'row':r['name'],'frames':fs,'median':median,'accepted':len(accepted),'total':len(fs),'review_flag':flag})
            if flag:
                cp=OUT/'contact'/f'candidate_{key}_2x.png'
                if not cp.exists():
                    rr=dict(r);rr['images']=ims
                    contact('candidate_'+key,[rr],refs[stem],(cw,ch),d['feet'],False)
                    new_contacts.append({'path':d['path'],'contact':cp.relative_to(ROOT).as_posix(),'reason':'head_median','median_at_flag':median,'accepted':len(accepted)})
        dump(OUT/'metrics/candidate_heads'/f'{key}.json',result);results.append(result)
        print(key,[(r['median'],r['accepted'],r['total']) for r in result['rows']],round(time.monotonic()-started,1),flush=True)
    dump(OUT/'metrics/candidate_head_contacts.json',new_contacts)
    dump(OUT/'metrics/candidate_head_index.json',[{'path':r['path'],'rows':len(r['rows']),'frames':sum(x['total'] for x in r['rows']),'flagged':any(x['review_flag'] for x in r['rows'])} for r in results])

if __name__=='__main__':main()
