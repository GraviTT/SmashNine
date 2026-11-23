from pathlib import Path
import sys,json,hashlib
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
O=ROOT/'reports/codex-art-97b'
DEST=ROOT/'art/bakeoff/xion/b'
sys.stdout.reconfigure(encoding='utf-8')
m=json.loads((O/'metrics.json').read_text(encoding='utf-8'))
feet=json.loads((O/'feet-motion.json').read_text(encoding='utf-8'))
bob=json.loads((O/'bob.json').read_text(encoding='utf-8'))
assert feet['max_distance']<=25
assert all(x['planted_runs']==1 and abs(x['error'])<=6 and 6<=x['lift_px']<=12 for x in feet['passing'])
assert max(abs(x) for x in bob['shifts'])<=3 and bob['feet_rows_unchanged']
notes={
'walk':'B2 대기 기준 8프레임 걷기. 회색 마네킹, 고정 1번 참조, 3·7번 통과 자세. 양손 산탄총을 낮게 유지. 최종 원본 조립 후 보브 1회.',
'jump':'B2 기준 도약·상승·정점 3프레임. 모두 발선 위. 마지막 프레임 유지. 기본 시트에는 2번 권장.',
'fall':'B2 기준 낙하 2프레임 반복. 머리·코트·스카프가 위로 흔들림. 아래 꼬리 길이를 2차 생성에서 보완. 기본 시트에는 1번 권장.',
'hurt':'B2 기준 피격 반동·최대 젖힘·회복 3프레임. 발 y120. 자동 머리 신뢰 프레임 1개로 4배 머리 비교를 적용. 기본 시트에는 1번 권장.',
'land':'B2 기준 착지 웅크림·대기 복귀 2프레임. 발 y120. 이펙트 없음.'}
result=[]
overview=Image.new('RGB',(2072,5*292),(28,32,42));draw=ImageDraw.Draw(overview);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',19)
for row_i,(row,v) in enumerate(m['rows'].items()):
    assert v['border_clear'] and v['min_margin']>=4 and v['spill']==0
    assert min(v['detail_percent_range'])>=90
    assert v['scarf_nominal_within_10_percent']
    assert row=='hurt' or .96<=v['head_median']<=1.04
    src=O/'walk-after-bob.png' if row=='walk' else O/('fall-a2' if row=='fall' else row)/'frame.png'
    sheet=Image.open(src).convert('RGBA').crop((0,0,v['frames']*128,128))
    dest=DEST/f'xion-{row}-b2.png';sheet.save(dest)
    meta={'note':notes[row],'fps':v['fps'],'frames':v['frames'],'loop':v['loop']}
    dest.with_suffix('.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    v['delivered']=True;v['path']=dest.relative_to(ROOT).as_posix();v['sha256']=hashlib.sha256(dest.read_bytes()).hexdigest()
    assert sheet.size==(v['frames']*128,128)
    for i in range(v['frames']):
        f=sheet.crop((i*128,0,(i+1)*128,128));a=np.asarray(f)
        assert set(np.unique(a[...,3]))=={0,255}
        assert not(a[0,:,3].any() or a[-1,:,3].any() or a[:,0,3].any() or a[:,-1,3].any())
    # Overview uses a consistent 2x pixel scale; dedicated QA boards are 4x.
    draw.text((12,row_i*292+4),row.upper()+f"  {v['frames']}f / {v['fps']}fps",fill=(225,233,245),font=font)
    show=sheet.resize((sheet.width*2,sheet.height*2),Image.Resampling.NEAREST)
    overview.paste(show.convert('RGB'),(12,row_i*292+28),show.getchannel('A'))
    result.append({'row':row,'size':sheet.size,'frames':v['frames'],'verified':True})
overview.save(O/'overview.png')
(O/'metrics.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'verification.json').write_text(json.dumps({'artifact_checks':result,'walk_checks':{'max_foot_step':feet['max_distance'],'passing':feet['passing'],'bob':bob['shifts']},'manual_visual_review':'18/18 프레임을 앵커와 4× 비교. 두 총·손·얼굴·코트·부츠·스카프 및 효과 없음 확인.','game_runtime_tested':False,'commit_script_executed':False},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result))
