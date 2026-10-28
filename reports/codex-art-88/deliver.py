"""Deliver reviewed files only; add metadata fields without altering old values."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json
from pathlib import Path
from PIL import Image
from audit import ROOT, OUT, BAKE, digest
from repair import dump
def main():
    if (OUT/'delivery.json').exists():raise RuntimeError('Already delivered: do not overwrite delivery baseline')
    base=json.loads((OUT/'baseline.json').read_text('utf-8'))
    repairs=json.loads((OUT/'repairs.json').read_text('utf-8'))
    sizes=json.loads((OUT/'sizes.json').read_text('utf-8'));assert all(x['within_5_percent'] for x in sizes)
    rows=[];metadata=[];sheets=[]
    # PNG version 1 and existing metadata values are immutable.
    for c in repairs:
        if not c['output']:continue
        src=ROOT/c['source'];expected=next(x for x in base['cases'] if x['id']==c['id'])['versions']['latest']['sha256']
        assert digest(src)==expected,(src,'changed after baseline')
        out=ROOT/c['output'];assert out.name.endswith('-v2.png')
        for suffix in ['.png','.json']:
            dst=out.with_suffix(suffix);review=OUT/'review-rows'/dst.name
            dst.write_bytes(review.read_bytes());rows.append(dst.relative_to(ROOT).as_posix())
    for item in base['metadata']:
        p=ROOT/item['path'];assert digest(p)==item['sha256']
        before=item['before'];row=p.stem.split('-')[-2]
        # ART-69 defeat / ART-68 move rows / ART-72,75,77 victory are 192.
        cell=96 if p.parent.name=='monsters' else 192 if row in ['defeat','victory','low_sweep','dimension_slash'] else 128
        expected=dict(cell=cell,feet=72 if cell==96 else 152 if cell==192 else 120,loop=row in ['idle','walk','fall'])
        added={k:v for k,v in expected.items() if k not in before}
        assert added,(p,'no missing fields')
        raw=p.read_bytes();text=raw.decode('utf-8');end=text.rfind('}')
        # Preserve all existing token spelling and note bytes; append only.
        prefix=text[:end].rstrip();tail=text[end:]
        new=prefix+',\n'+',\n'.join('  '+json.dumps(k)+': '+json.dumps(v) for k,v in added.items())+'\n'+tail
        after=json.loads(new);assert all(after[k]==v for k,v in before.items())
        assert set(after)-set(before)==set(added)
        p.write_bytes(new.encode('utf-8'))
        metadata.append(dict(path=item['path'],added=added,before_sha256=item['sha256'],after_sha256=digest(p)))
    for mid in sorted({x['monster'] for x in repairs if x['output']}):
        sheet=Image.new('RGBA',(576,576));parts=[]
        for i,row in enumerate(['idle','walk','windup','attack','hurt','defeat']):
            p=BAKE/f'{mid}-{row}-v2.png'
            if not p.exists():p=BAKE/f'{mid}-{row}-v1.png'
            im=Image.open(p).convert('RGBA');assert im.size==(576,96)
            sheet.paste(im,(0,96*i));parts.append(dict(row=row,path=p.relative_to(ROOT).as_posix(),sha256=digest(p)))
        path=BAKE/f'{mid}_sheet-v2.png';sheet.save(path)
        sheets.append(dict(path=path.relative_to(ROOT).as_posix(),rows=parts,sha256=digest(path)))
    dump(OUT/'delivery.json',dict(rows=rows,metadata=metadata,sheets=sheets))
    print('row PNG/JSON pairs',len(rows)//2,'metadata completed',len(metadata),'sheets',len(sheets),'changed frames',sum(len(x['changed_frames']) for x in repairs))
if __name__=='__main__':main()
