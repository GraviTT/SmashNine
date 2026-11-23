"""Validate delivered files; keep technical integrity separate from art acceptance."""
from pathlib import Path
from PIL import Image
import hashlib
import json
import re
import subprocess
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
R = ROOT / 'reports/codex-art-96b'
sheet_path = ROOT / 'art/bakeoff/xion/b/xion-idle-b2.png'
sheet = Image.open(sheet_path)
assert sheet.mode == 'RGBA' and sheet.size == (768,128)
meta = json.loads(sheet_path.with_suffix('.json').read_text(encoding='utf-8'))
assert meta['frames'] == 6 and meta['fps'] == 6.3 and meta['loop'] is True
assert re.search('[가-힣]',meta['note'])
frames=[]
for i in range(6):
    a=np.asarray(sheet.crop((i*128,0,(i+1)*128,128)))
    mask=a[:,:,3]>0; yy,xx=np.nonzero(mask)
    height=int(yy.max()-yy.min()+1)
    margin=int(min(xx.min(),yy.min(),127-xx.max(),127-yy.max()))
    assert 95<=height<=100 and yy.max()==120 and margin>=4
    assert set(np.unique(a[:,:,3]).tolist())=={0,255}
    rgb=a[:,:,:3].astype(int)
    spill=int(np.sum(mask&(rgb[:,:,1]>np.maximum(rgb[:,:,0],rgb[:,:,2])+20)))
    stricter=int(np.sum(mask&(rgb[:,:,1]>np.maximum(rgb[:,:,0],rgb[:,:,2])+16)))
    assert spill==0
    frames.append({'frame':i+1,'height':height,'bottom':int(yy.max()),'minimum_margin':margin,'green_dominance_pixels_threshold20':spill,'green_dominance_pixels_threshold16':stricter})
gif=Image.open(R/'idle-4x.gif')
assert gif.size==(512,512) and gif.n_frames==6 and gif.info['loop']==0
durations=[]
for i in range(gif.n_frames):
    gif.seek(i);durations.append(gif.info['duration'])
assert durations==[160,160,160,160,160,150]
assert Image.open(R/'compare.png').size==(3072,1104)
for i in range(6):assert Image.open(R/f'review-{i+1}.png').size==(1040,552)
metrics=json.loads((R/'metrics.json').read_text(encoding='utf-8'))
scarf=json.loads((R/'scarf.json').read_text(encoding='utf-8'))
assert metrics['head_scale']['self']['used']==6
assert 0.96<=metrics['head_scale']['self']['median']<=1.04
assert metrics['normalization']['summary']['interior_detail_ratio']>=0.9
assert scarf['upper_consistency']['within_plus_minus_2px']
assert scarf['lower_consistency']['within_plus_minus_2px']
for relative,expected in metrics['sha256'].items():
    assert hashlib.sha256((ROOT/relative).read_bytes()).hexdigest()==expected
text_count=0
for root in (R,ROOT/'art/bakeoff/xion/b'):
    for path in root.rglob('*'):
        if path.is_file() and path.suffix in ('.md','.json','.txt','.py','.ps1'):
            if root.name=='b' and path.name!='xion-idle-b2.json':continue
            value=path.read_text(encoding='utf-8')
            assert '\ufffd' not in value
            if path.suffix=='.json':json.loads(value)
            text_count+=1
commit=(R/'commit.ps1').read_text(encoding='utf-8')
path_block=commit.split('$paths = @(',1)[1].split('\n)',1)[0]
paths=re.findall("'([^']+)'",path_block)
assert paths and len(paths)==len(set(paths))
for relative in paths:
    assert (ROOT/relative).is_file(),relative
    assert relative.startswith('reports/codex-art-96b/') or relative in (
      'art/bakeoff/xion/b/xion-idle-b2.png','art/bakeoff/xion/b/xion-idle-b2.json','design/tasks/CODEX-ART-96.md')
assert 'git add -f' not in commit and 'Co-Authored-By: Codex <noreply@openai.com>' in commit
product_diff=subprocess.check_output(['git','diff','--name-only','--','smash-nine-prototype'],cwd=ROOT,text=True).strip()
assert not product_diff
result={'file_integrity':'PASS','art_acceptance':'HOLD','frames':frames,'gif_durations_ms':durations,
 'utf8_text_files':text_count,'commit_explicit_paths':len(paths),'commit_executed':False,'product_tracked_diff':[],
 'known_remaining':['수평 도달거리 원화 비율 대비 +10.62% / +16.82%',
 '발 외곽 중점 변동 1.0px / 0.5px','수동 약 3.46등신, 엄밀한 3등신 아님',
 'Rio 자동 머리 비교 신뢰도 부족(유효 0/6)','머리카락 지연과 호흡이 희미함; 게임 재생 미검증']}
(R/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=False))
