"""Independent saved-artifact checks; no writes to candidates or game sources."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
REPORT=Path(__file__).resolve().parent
FORMS=[('frey','frey'),('luna','luna'),('luna','luna_brave'),('yuki','yuki'),('nova','nova_male'),('nova','nova_female'),('rio','rio_male'),('rio','rio_female')]
EXPRESSIONS=['happy','angry','hurt']

def run():
    counts=dict(candidate_count=0,neutral_sources_unchanged=0,size_256_rgba_pass=0,alpha_exact_pass=0,outside_mask_rgba_exact_pass=0,metadata_pass=0,composite_reconstruction_pass=0,seam_measure_recalculation_pass=0)
    expected_hashes=json.loads((REPORT/'source-sha256.json').read_text(encoding='utf-8'))
    rows=json.loads((REPORT/'composite-measurements.json').read_text(encoding='utf-8'))
    for folder,stem in FORMS:
        original=ROOT/f'smash-nine-prototype/assets/art/{folder}/{stem}_face.png'
        assert original.read_bytes()==(ROOT/f'art/raw/faces-73/sources/{stem}_face.png').read_bytes(),stem
        assert hashlib.sha256(original.read_bytes()).hexdigest()==expected_hashes[original.relative_to(ROOT).as_posix()]
        counts['neutral_sources_unchanged']+=1
        neutral=Image.open(original).convert('RGBA');n=np.array(neutral)
        for expr in EXPRESSIONS:
            path=ROOT/f'art/bakeoff/{folder}/{stem}_face-{expr}-v1.png'
            im=Image.open(path);o=np.array(im)
            assert im.size==(256,256) and im.mode=='RGBA',path
            counts['candidate_count']+=1;counts['size_256_rgba_pass']+=1
            meta=json.loads(path.with_suffix('.json').read_text(encoding='utf-8'));c=meta['composite']
            assert meta['expression']==expr and meta['review_status']=='candidate' and meta['delivered'] is True
            assert meta['edited_from']==original.relative_to(ROOT).as_posix()
            assert any(0xAC00 <= ord(ch) <= 0xD7A3 for ch in meta['note'])
            assert len(c['offset'])==2 and all(isinstance(v,int) and abs(v)<=4 for v in c['offset']) and c['feather']==4
            counts['metadata_pass']+=1
            mask=Image.open(REPORT/f'{stem}-{expr}-mask.png');m=np.array(mask)
            assert mask.size==(256,256) and mask.mode=='L' and mask.getbbox()==tuple(c['mask_bbox'])
            assert np.array_equal(n[m==0],o[m==0]),(stem,expr,'outside')
            assert np.array_equal(n[:,:,3],o[:,:,3]),(stem,expr,'alpha')
            counts['outside_mask_rgba_exact_pass']+=1;counts['alpha_exact_pass']+=1
            raw=Image.open(ROOT/meta['source_raw']).convert('RGBA').resize((256,256),Image.Resampling.LANCZOS)
            aligned=Image.new('RGBA',(256,256));aligned.paste(raw,tuple(c['offset']))
            reconstructed=Image.composite(aligned,neutral,mask);reconstructed.putalpha(neutral.getchannel('A'))
            assert np.array_equal(o,np.array(reconstructed)),(stem,expr,'reconstruction')
            counts['composite_reconstruction_pass']+=1
            band=(m>0)&(m<255)
            delta=np.abs(np.array(aligned)[:,:,:3].astype(np.int16)-n[:,:,:3].astype(np.int16))
            measured=round(float(delta[band].mean()),4)
            row=next(r for r in rows if r['form']==stem and r['expression']==expr)
            assert measured==meta['measurements']['seam_edit_neutral_rgb_mae']==row['seam_edit_neutral_rgb_mae']
            counts['seam_measure_recalculation_pass']+=1
    counts['artifact_checks_pass']=all(v==(8 if k=='neutral_sources_unchanged' else 24) for k,v in counts.items())
    counts['game_execution_tested']=False
    counts['seam_visual_check']='manual; see visual-review.json; seam MAE is a diagnostic, not a visual pass threshold'
    (REPORT/'verification.json').write_text(json.dumps(counts,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(counts,ensure_ascii=False,indent=2))
    return 0 if counts['artifact_checks_pass'] else 1
if __name__=='__main__':raise SystemExit(run())
