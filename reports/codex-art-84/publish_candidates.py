"""Publish reviewed candidates once, exclusive creation for every output."""
import hashlib
from build_hurt import *
from build_shadows_final import final_transform

def copy_new(src,dest):
    with dest.open('xb') as f: f.write(src.read_bytes())

def broad_edges(before,after,protect):
    a=np.array(before); b=np.array(after); valid=(a[:,:,3]>=240)&(protect<.01)
    total=kept=0
    for axis in [0,1]:
        delta=np.max(np.abs(np.diff(a[:,:,:3].astype(float),axis=axis)),axis=2)
        delta2=np.max(np.abs(np.diff(b[:,:,:3].astype(float),axis=axis)),axis=2)
        v=(valid[:-1]&valid[1:]) if axis==0 else (valid[:,:-1]&valid[:,1:])
        strong=(delta>=12)&v; total+=int(strong.sum()); kept+=int((strong&(delta2>=3)).sum())
    return {'sample':'alpha>=240, eye protection<0.01; horizontal+vertical adjacent RGB max-channel difference',
            'before_delta_ge12_pairs':total,'after_delta_ge3_pairs':kept,'retention_percent':round(100*kept/total,4)}

if __name__=='__main__':
    hurts=json.loads((RAW/'hurt-selected/measurements.json').read_text(encoding='utf-8'))
    shadows=json.loads((RAW/'shadow-final/measurements.json').read_text(encoding='utf-8'))
    records=hurts+shadows
    # Refuse the entire publish before writing anything if any candidate exists.
    targets=[]
    for r in records:
        stem=r['stem']; e=r['expression']; folder=old.FORMS[stem]['folder']
        p=ROOT/f'art/bakeoff/{folder}/{stem}_face-{e}-v2.png'
        targets.extend([p,p.with_suffix('.json'),REPORT/f'{stem}-{e}.png'])
    assert not any(p.exists() for p in targets), 'Existing destination; never overwrite.'
    for r in records:
        stem=r['stem']; e=r['expression']; folder=old.FORMS[stem]['folder']
        draft=RAW/('hurt-selected' if e=='hurt' else 'shadow-final')
        p=ROOT/f'art/bakeoff/{folder}/{stem}_face-{e}-v2.png'
        copy_new(draft/f'{stem}-{e}.png',p)
        copy_new(draft/f'{stem}-{e}-board.png',REPORT/f'{stem}-{e}.png')
        if e=='hurt':
            for suffix in ['mask','seam']:
                copy_new(draft/f'{stem}-hurt-{suffix}.png',REPORT/f'{stem}-hurt-{suffix}.png')
            copy_new(draft/f'{stem}-alignment-scores.json',REPORT/f'{stem}-hurt-alignment-scores.json')
            note='중립 얼굴을 내장 이미지 도구로 편집하고 ART-73 정수 정렬·4px 내부 페더 마스크로 합성했다. 두 눈을 감고 통증으로 벌어진 입을 만들었으며 유키는 땀방울을 강조했다. 마스크 밖 RGBA 및 전체 알파는 중립과 같다. 미채택 v2 후보이며 게임 미연결.'
            source=f'art/raw/faces-84/{stem}-hurt-generated-{r["selected_attempt"]}.png'
        else:
            for suffix in ['detail','eye-protect']:
                name=f'{stem}-shadow-detail.png' if suffix=='detail' else f'{stem}-eye-protect.png'
                copy_new(draft/name,REPORT/name)
            v1=Image.open(RAW/f'{stem}-shadow-v1.png').convert('RGBA')
            out=Image.open(p).convert('RGBA'); _,protect,_,_=final_transform(stem,v1)
            r['detail_check_alpha_ge240']=broad_edges(v1,out,protect)
            note='ART-80에서 중립 얼굴을 직접 편집한 v1의 선화·좌표·알파를 유지하고 승인된 Pillow 점별 톤 곡선으로 피부·금속·부적을 어둡게 했다. 기존 눈 색 영역은 보호하거나 밝기를 보강했다. 리오 여성형의 감긴 눈을 새로 그리지 않았다. 미채택 v2 후보이며 게임 미연결.'
            source=f'art/raw/faces-84/{stem}-shadow-v1.png'
        r['candidate_sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
        meta={'note':note,'expression':e,'edited_from':f'smash-nine-prototype/assets/art/{folder}/{stem}_face.png',
              'replaces':f'art/bakeoff/{folder}/{stem}_face-{e}-v1.png',
              'source_raw':source,'review_status':'candidate','candidate_only':True,'delivered':True,
              'size':[256,256],'mode':'RGBA','measurements':r,
              'review_board':f'reports/codex-art-84/{stem}-{e}.png'}
        if e=='shadow':
            meta.update(processed_from=meta['replaces'],offset=r['inherited_generation_offset'],additional_offset=[0,0],tone_config='reports/codex-art-84/shadow-tone-config.json')
        else:
            meta.update(offset=r['offset'],mask=f'reports/codex-art-84/{stem}-hurt-mask.png',feather_pixels=4,selected_attempt=r['selected_attempt'])
        dump(p.with_suffix('.json'),meta)
    copy_new(RAW/'hurt-selected/config.json',REPORT/'hurt-mask-config.json')
    copy_new(RAW/'shadow-final/final-tone-config.json',REPORT/'shadow-tone-config.json')
    dump(REPORT/'measurements.json',records)
    # A concise comparison index: each portrait remains a true 142px square.
    overview=Image.new('RGBA',(960,1080),'#151621')
    text(overview,(18,10),'ART-84 · v1 → v2 후보 · 142×164 비교 (실제 게임 화면 아님)',22)
    for i,r in enumerate(records):
        stem=r['stem']; e=r['expression']; x=(i%2)*480; y=55+(i//2)*204
        text(overview,(x+15,y),f'{old.FORMS[stem]["label"]} · {e}',18)
        for j,v in enumerate([1,2]):
            im=Image.open(ROOT/f'art/bakeoff/{old.FORMS[stem]["folder"]}/{stem}_face-{e}-v{v}.png').convert('RGBA')
            overview.alpha_composite(old.dialogue_preview(im),(x+50+j*205,y+28))
            text(overview,(x+17+j*205,y+88),f'v{v}',15)
    save(overview.convert('RGB'),REPORT/'overview.png')
    print('Published',len(records),'PNG+JSON pairs, with boards and measurements. No overwrite.')
