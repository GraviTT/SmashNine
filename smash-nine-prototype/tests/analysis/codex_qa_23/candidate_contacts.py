"""Create contacts only for numerically flagged candidates; annotate exact duplicates."""
import sys
sys.dont_write_bytecode=True
import json,collections
import numpy as np
from pathlib import Path
from PIL import Image
from audit import ROOT,OUT,ART,STEMS,contact,dump
from detail import runs

def main():
    index=json.loads((OUT/'metrics/candidate_index.json').read_text(encoding='utf-8'))
    review=[];grouped=collections.defaultdict(list)
    for x in index:
        p=Path(x['path']);d=json.loads((OUT/'metrics/candidates'/f'{p.stem}.json').read_text(encoding='utf-8'))
        if d['kind']!='portrait':
            im=Image.open(ROOT/d['path']).convert('RGBA');cw,ch=d['cell']
            for row in d['rows']:
                for f in row['frames']:
                    if not f['bbox']:continue
                    xx=(f['sheet_column']-1)*cw;yy=(f['sheet_row']-1)*ch;m=np.array(im.crop((xx,yy,xx+cw,yy+ch)))[:,:,3]>=128
                    x0,y0,x1,y1=f['bbox'];f['bbox_edge_runs']={'left':runs(m[y0:y1,x0]),'right':runs(m[y0:y1,x1-1]),'top':runs(m[y0,x0:x1]),'bottom':runs(m[y1-1,x0:x1])}
                    if max(f['bbox_edge_runs']['left'],f['bbox_edge_runs']['right'])>=16:d['flags'].append('internal_vertical_edge')
                    if len(f['component_sizes'])>1 and f['component_sizes'][1]>=25:d['flags'].append('separate_component')
                    if row['feet_mode']=='ground' and row['name'] not in ['defeat','victory'] and f['bottom_delta'] is not None and abs(f['bottom_delta'])>4:d['flags'].append('feet_offset')
            d['flags']=sorted(set(d['flags']));x['flags']=d['flags'];dump(OUT/'metrics/candidates'/f'{p.stem}.json',d)
        if not d['flags']:continue
        grouped[d['stem']].append(d)
    dump(OUT/'metrics/candidate_index.json',index)
    for stem,items in grouped.items():
        refs=ART/(stem.split('_')[0] if stem in STEMS else 'monsters')/f'{stem}_sheet.png'
        ref=Image.open(refs).convert('RGBA') if refs.exists() else None
        if ref:ref=ref.crop((0,0,ref.width//6,ref.width//6))
        # Separate rectangular projectiles, ordinary strips and full atlases.
        seen={}
        for d in sorted(items,key=lambda x:(0 if x['storage']=='six_column_atlas' else 1,x['path'])):
            sheet=Image.open(ROOT/d['path']).convert('RGBA');cw,ch=d['cell'];rows=[];equiv=[]
            for row in d['rows']:
                sig=tuple(f['rgba_sha256'] for f in row['frames'])
                if sig in seen:equiv.append({'row':row['name'],'identical_to':seen[sig]})
                rr=dict(row);rr['images']=[]
                for f in row['frames']:
                    x=(f['sheet_column']-1)*cw;y=(f['sheet_row']-1)*ch;rr['images'].append(sheet.crop((x,y,x+cw,y+ch)))
                rows.append(rr)
                seen[sig]=d['path']+' / '+row['name']
            key='candidate_'+Path(d['path']).stem
            cp,pages=contact(key,rows,ref if ref is not None and ref.width<=cw and ref.height<=ch else rows[0]['images'][0],(cw,ch),d['feet'],False)
            review.append({'path':d['path'],'contact':cp,'flags':d['flags'],'equivalent_rows':equiv,'all_rows_equivalent':len(equiv)==len(rows)})
        print(stem,len(items),flush=True)
    dump(OUT/'metrics/candidate_visual_queue.json',review)
    print('contacts',len(review),'unique',sum(not d['all_rows_equivalent'] for d in review),flush=True)

if __name__=='__main__':main()
