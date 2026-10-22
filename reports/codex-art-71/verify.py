"""Read final PNGs/metadata, check the card contract, and write measured evidence."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, statistics, hashlib
from pathlib import Path
import process as p
from PIL import Image, ImageDraw, ImageFont

IDS=['mossling','ember_imp','asgard_aegis_ram','asgard_runic_raven','alfheim_moon_stag','alfheim_moon_moth']
results=[]; failures=[]
frey=Image.open(p.ROOT/'art/bakeoff/frey/frey-idle-v2.png').convert('RGBA')
frey_detail=statistics.mean(p.n.interior_detail(frey.crop((128*i,0,128*(i+1),128))) for i in range(6))
tables=[]
for mid in IDS:
    assembled=Image.open(p.BAKE/f'{mid}_sheet-v1.png').convert('RGBA')
    assert assembled.size==(576,576)
    old=Image.open(p.ROOT/f'smash-nine-prototype/assets/art/monsters/{mid}_sheet.png').convert('RGBA')
    old_detail=statistics.mean(p.n.interior_detail(old.crop((96*i,0,96*(i+1),96))) for i in range(4))
    tables+=['',f'### `{mid}`','', '| 행 | 프레임 | fps | 공통 factor | 최소 여백 px | 디테일 범위 | 전달 |','|---|---:|---:|---:|---:|---:|---|']
    for ri,row in enumerate(p.ROWS):
        path=p.BAKE/f'{mid}-{row}-v1.png'; im=Image.open(path).convert('RGBA'); meta=json.loads(path.with_suffix('.json').read_text('utf-8'))
        assert im.size==(576,96) and meta['cell']==96 and meta['feet']==72 and meta['frames']==p.COUNTS[row]
        assert isinstance(meta['loop'],bool) and isinstance(meta['note'],str) and meta['factor']>0
        assert bool(meta['loop'])==(row in ['idle','walk'] or row=='attack' and mid in ['asgard_aegis_ram','asgard_runic_raven'])
        fps=4/p.WINDUP[mid] if row=='windup' else dict(idle=6,walk=10,attack=12,hurt=8,defeat=8)[row]
        assert abs(meta['fps']-fps)<.000001
        assert assembled.crop((0,96*ri,576,96*(ri+1))).tobytes()==im.tobytes()
        assert im.crop((96*p.COUNTS[row],0,576,96)).getbbox() is None
        data=p.audit(mid,row)
        bad=[x for x in data if x['margin']<3 or x['spill'] or not x['alpha_binary']]
        if bad:failures.append((mid,row,bad))
        details=[x['detail'] for x in data];margin=min(x['margin'] for x in data)
        hashes=[hashlib.sha256(frame.tobytes()).hexdigest() for frame in p.frames(path,p.COUNTS[row])]
        if len(set(hashes))!=len(hashes):failures.append((mid,row,'duplicate frames'))
        if mid not in ['asgard_runic_raven','alfheim_moon_moth'] and row!='attack':assert all(x['bottom']==72 for x in data)
        if row=='defeat':assert data[-1]['bottom']==72
        result=dict(monster=mid,row=row,**meta,margin_min=margin,detail_min=min(details),detail_max=max(details),detail_mean=round(statistics.mean(details),2),detail_ratio_to_frey=round(statistics.mean(details)/frey_detail,3),old_idle_detail_mean=round(old_detail,2),frames_audit=data,delivered=True)
        results.append(result)
        tables.append(f"| {row} | {meta['frames']} | {meta['fps']:.3f} | {meta['factor']:.8g} | {margin} | {min(details):.2f}–{max(details):.2f} | 후보 전달 |")
        mp=p.REPORT/mid/row/'metrics.json';m=json.loads(mp.read_text('utf-8'))
        m['final_summary']={k:result[k] for k in ['margin_min','detail_min','detail_max','detail_mean','detail_ratio_to_frey']}
        m['final_summary'].update(border_clear=all(x['margin']>0 for x in data),alpha_binary=all(x['alpha_binary'] for x in data),spill=sum(x['spill'] for x in data),bottoms=[x['bottom'] for x in data])
        mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8')
        # Actual accepted anchor beside every row at exactly 4x, no generated pixels.
        anchor=p.frames(p.BAKE/f'{mid}-idle-v1.png',1)[0]
        comparison=[anchor,*p.frames(path,p.COUNTS[row])]
        panel=Image.new('RGB',(160+384*len(comparison),412),(24,29,40));pd=ImageDraw.Draw(panel)
        pd.text((8,8),'ANCHOR / ROW',font=p.n.font(16),fill='white')
        for ci,frame in enumerate(comparison):
            tile=p.n.checker((96,96)).convert('RGB');tile.paste(frame,(0,0),frame)
            tile=tile.resize((384,384),Image.Resampling.NEAREST)
            panel.paste(tile,(160+384*ci,28));pd.text((168+384*ci,5),'ANCHOR' if ci==0 else f'F{ci}',font=p.n.font(16),fill='white')
        pd.line((160,28+73*4,panel.width,28+73*4),fill=(235,90,110),width=1)
        # Regression: every opaque anchor pixel survives the 96px/4x comparison.
        expected=p.n.checker((96,96)).convert('RGB');expected.paste(anchor,(0,0),anchor)
        expected=expected.resize((384,384),Image.Resampling.NEAREST)
        visible=p.n.np.asarray(anchor.resize((384,384),Image.Resampling.NEAREST))[:,:,3]>0
        actual=p.n.np.asarray(panel.crop((160,28,544,412)))
        assert p.n.np.array_equal(actual[visible],p.n.np.asarray(expected)[visible]),'anchor clipped in 4x board'
        panel.save(p.REPORT/mid/row/'anchor-4x.png')
    p.board(mid)
summary=dict(monsters=6,rows=len(results),frames=sum(x['frames'] for x in results),frey_idle_detail_mean=round(frey_detail,2),failures=failures,results=results)
(p.REPORT/'verification.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),'utf-8')
(p.REPORT/'tables.md').write_text('\n'.join(tables)+'\n','utf-8')
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
overview=Image.new('RGB',(6*220,330),(24,29,40));d=ImageDraw.Draw(overview)
for i,mid in enumerate(IDS):
    d.text((i*220+8,8),mid.replace('asgard_','').replace('alfheim_',''),font=font,fill='white')
    old=Image.open(p.ROOT/f'smash-nine-prototype/assets/art/monsters/{mid}_sheet.png').convert('RGBA').crop((0,0,96,96))
    new=p.frames(p.BAKE/f'{mid}-idle-v1.png',1)[0]
    d.text((i*220+8,35),'OLD 1x       NEW 1x',font=font,fill=(175,190,210))
    overview.paste(old,(i*220+8,61),old);overview.paste(new,(i*220+112,61),new)
    wind=p.frames(p.BAKE/f'{mid}-windup-v1.png',2)[1].resize((144,144),Image.Resampling.NEAREST)
    d.text((i*220+8,159),'WINDUP F2 / 1.5x',font=font,fill=(175,190,210))
    overview.paste(wind,(i*220+38,182),wind)
overview.save(p.REPORT/'overview.png')
print('VERIFY',json.dumps({k:v for k,v in summary.items() if k!='results'}))
if failures:raise SystemExit(1)
