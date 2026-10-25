"""L14 lead follow-up: deterministic F5 repair, measurements, and 4x evidence.

Run from the repository root. Only the explicitly requested uncommitted
candidate and ART-86 reports are replaced. No Godot, staging, or commits.
"""
from common import *
from rebuild import l14_sources, sample, shift, l14_restore_position

REL='rio/rio_female-mana_combo-v2.png'

def measure(frame):
    a=np.array(frame)
    xs=np.nonzero(a[60:111,:,3]==255)[1]
    feet=np.nonzero(a[148:153,:,3]==255)[1]
    return {'torso_median_x':float(np.median(xs)),
            'feet_span_x':[int(feet.min()),int(feet.max())],
            'feet_y':frame.getbbox()[3]-1}

def previous_frames():
    fs=cells(RAW/'L14-adopted.png');raw=l14_sources()
    fs[4]=shift(sample(raw[0],.260,[-.125,-.125],192),19)
    fs[5]=shift(sample(raw[1],.260,[.25,.375],192),17)
    return fs

def handoff_board(before,after):
    scale=4;tile=192*scale;header=88;rowheight=tile+64
    im=Image.new('RGB',(tile*3,header+2*rowheight),(24,30,43));d=ImageDraw.Draw(im)
    d.text((16,12),'L14 F4 > F5 > F6 | body placement repair',fill='white',font=n.font(27))
    d.text((16,49),'4x nearest | cyan = median x, rows 60-110 | orange = feet span, rows 148-152 | yellow = F5',fill='white',font=n.font(22))
    for row,fs in enumerate([before,after]):
        for col,i in enumerate([3,4,5]):
            x=col*tile;y=header+row*rowheight;m=measure(fs[i])
            bg=n.checker((tile,tile));f=fs[i].resize((tile,tile),Image.Resampling.NEAREST);bg.paste(f,(0,0),f);im.paste(bg,(x,y+64))
            label='BEFORE review' if row==0 else 'AFTER repair'
            d.text((x+12,y+5),f'{label}  F{i+1} | torso {m["torso_median_x"]:g}',fill='white',font=n.font(24))
            d.text((x+12,y+34),f'feet x={m["feet_span_x"][0]}..{m["feet_span_x"][1]}, y=152',fill='white',font=n.font(21))
            cy=y+64;mx=x+int(m['torso_median_x']*scale)
            d.line((mx,cy+60*scale,mx,cy+111*scale),fill='#67e8f9',width=2)
            left,right=m['feet_span_x'];fy=cy+153*scale
            d.line((x+left*scale,fy,x+(right+1)*scale-1,fy),fill='#ffbd69',width=3)
            for edge in [left,right+1]:d.line((x+edge*scale,fy-7,x+edge*scale,fy+7),fill='#ffbd69',width=2)
            if i==4:d.rectangle((x+2,y+2,x+tile-3,y+rowheight-3),outline='#ffe066',width=3)
    im.save(OUT/'handoff-comparison.png')

def run():
    target=ROOT/'art/bakeoff'/REL;current=cells(target)
    before=previous_frames();after=before.copy();after[4]=l14_restore_position(before[4])
    # Safe repeat: only the known pre-review or repaired candidate may be replaced.
    assert strip(current).tobytes() in [strip(before).tobytes(),strip(after).tobytes()]
    adopted=cells(RAW/'L14-adopted.png')
    assert all(before[i].tobytes()==after[i].tobytes() for i in [0,1,2,3,5])
    a=np.array(after[4]);translated=np.array(shift(before[4],8))
    outside=np.ones((192,192),dtype=bool);outside[95:113,140:]=False
    assert np.array_equal(a[outside],translated[outside])
    mm=metrics(after[4]);comps=components(after[4]);tip=np.flatnonzero(a[:,187,3])
    assert mm['margin']['has_4px_margin'] and mm['remaining_spill_pixels']==0 and mm['alpha_binary']
    assert len(comps)==1 and tip.tolist()==[108]
    measurements=[{'frame':i+1,'adopted_v1':measure(adopted[i]),'before':measure(before[i]),'after':measure(after[i])} for i in [3,4,5]]
    assert [r['after']['torso_median_x'] for r in measurements]==[98,102,105]
    assert measurements[1]['after']['feet_span_x']==[57,160]
    assert all(r['after']['feet_y']==152 for r in measurements)
    strip(after).save(target)
    meta=json.loads(target.with_suffix('.json').read_text(encoding='utf8'))
    meta['note']='QA-23 L14. F5 온전한 칼끝 재추출, F6 분리 칼 조각 제거. 리드 재검토: F5 몸만 +8px 복원하고 칼날 부분만 가로 56→48px로 줄여 끝까지 보존(프레임/몸/머리 배율 변경 없음). F4/F5/F6 몸통 중심 98/94/105→98/102/105px, 발 범위 61–155/49–152/88–166→61–155/57–160/88–166px, 발선 모두 y152. F5 v1 몸통101 대비 +1px는 원본 재추출 및 길어진 칼을 포함한 중앙값 차이. 칼끝 (187,108) 한 픽셀, 오른쪽 여백4px, 전체 연결요소1개. F1~F4 및 직전 v2 F6 RGBA 동일. 얼굴 눈 간격0.963/1.034, 폭1.000 유지.'
    meta['position_review']={'measurement':'torso: opaque pixels, y60..110 inclusive; feet span: opaque pixels, y148..152 inclusive; local cell coordinates','frames':measurements,'body_translation':[8,0],'body_scale':1.0,'blade_crop_before':[132,95,188,113],'blade_output_size':[48,18],'blade_destination':[140,95],'blade_tip':[187,108],'right_margin':4,'connected_components':1}
    target.with_suffix('.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    report={'candidate':str(target.relative_to(ROOT)).replace('\\','/'),'png_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'position_review':meta['position_review'],'only_f5_changed_since_review':True,'body_rgba_identical_after_translation_outside_blade':True,'head_rgba_identical_after_translation':True,'frame_scale_unchanged':True,'f5_metrics':mm,'component_sizes':[len(c) for c in comps],'tip_column_opaque_y':tip.tolist(),'godot_run':False}
    (OUT/'L14-position-review.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    handoff_board(before,after)
    # Refresh previously delivered L14 row/close-up evidence without changing other rows.
    boardpath=OUT/'rio_female-mana_combo.png'
    # common.board refuses overwrites; capture it in memory through its save hook.
    import common
    original_save=common.save
    common.save=lambda im,path:im.save(path)
    try:board(adopted,after,[5,6],boardpath,'L14 adopted v1 / final v2 | F5 body restored; whole blade; F6 fragment removed')
    finally:common.save=original_save
    n.render_row(after[4:],'L14 final F5 / F6 | body restored; whole blade',152,4).save(OUT/'L14-final-4x.png')
    print('PASS: torso 98/94/105 -> 98/102/105; F5 feet 49..152 -> 57..160; tip (187,108); 4px margin; 1 component')

if __name__=='__main__':run()
