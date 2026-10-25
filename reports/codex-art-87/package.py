"""Build final explanatory boards, visual review ledger and explicit staging list."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
from pathlib import Path
import json,hashlib
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2];REPORT=ROOT/'reports/codex-art-87';RAW=ROOT/'art/raw/monsters-87';OUT=ROOT/'art/bakeoff/monsters/legacy'
FONT=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
SMALL=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',14)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def bg(size):
    im=Image.new('RGB',size);d=ImageDraw.Draw(im)
    for y in range(0,size[1],12):
        for x in range(0,size[0],12):d.rectangle((x,y,x+11,y+11),fill=(42,46,56) if (x//12+y//12)%2 else (57,62,73))
    return im
def paste(canvas,im,at,scale=1):
    im=im.resize((im.width*scale,im.height*scale),Image.Resampling.NEAREST);b=bg(im.size);b.paste(im,(0,0),im);canvas.paste(b,at)
def frame(p,r,c):return Image.open(p).convert('RGBA').crop((c*96,r*96,c*96+96,r*96+96))
examples=[('jotunheim_rune_golem',0,0,'L01 / L07: full lower body + shoulder margin'),('muspelheim_magma_boar',0,0,'L02: belly and legs restored'),('niflheim_glacier_wolf',0,0,'L03: source confirms missing legs'),('alfheim_moon_stag',2,2,'L12: complete head; smaller attack-row scale'),('ember_imp',0,0,'L04 / L06: added rim removed; 4px top margin'),('jotunheim_storm_wisp',2,3,'L24: overlapping shot removed by redraw')]
board=Image.new('RGB',(1000,1120),(23,28,36));d=ImageDraw.Draw(board)
d.text((16,12),'ART-87 | Legacy fallback candidates | NOT installed in game',font=FONT,fill='white')
for k,(id,r,c,label) in enumerate(examples):
    x=16+(k%2)*500;y=55+(k//2)*350
    d.text((x,y),label,font=SMALL,fill='#ffdc8c')
    d.text((x,y+24),'BEFORE 2x',font=SMALL,fill='white');d.text((x+220,y+24),'AFTER 2x',font=SMALL,fill='white')
    paste(board,frame(RAW/(id+'_sheet.png'),r,c),(x,y+48),2)
    paste(board,frame(OUT/(id+'_sheet-fix1.png'),r,c),(x+220,y+48),2)
    d.text((x,y+250),id,font=SMALL,fill='#c0cad8')
board.save(REPORT/'overview.png')

# The red line is the former fixed source-cell boundary, not a generated guide.
evidence=Image.new('RGB',(1160,460),(23,28,36));d=ImageDraw.Draw(evidence)
d.text((16,12),'Source evidence: body continues below the old y=256 slice boundary',font=FONT,fill='white')
for k,id in enumerate(['jotunheim_rune_golem','muspelheim_magma_boar','niflheim_glacier_wolf']):
    src=Image.open(RAW/(id+'_source.png')).convert('RGBA');a=src.getchannel('A').point(lambda x:0 if x<41 else x);src.putalpha(a)
    crop=src.crop((0,95,280,300));x=20+k*385;paste(evidence,crop,(x,70));d.text((x,40),id,font=SMALL,fill='white');d.line((x,70+161,x+279,70+161),fill='#ff6b6b',width=2)
    d.text((x,290),'Red: former crop at source y=256',font=SMALL,fill='#ff8d8d')
d.text((20,350),'Full source outline exists below the line. Repair used explicit source regions, not invented legs.',font=FONT,fill='#d9e1e9')
d.text((20,390),'Ember Imp / Mossling: no *_source.png; preserved pre-ART-17 sheets restore the original body.',font=SMALL,fill='#d9e1e9')
evidence.save(REPORT/'source_evidence.png')

judgments={
'jotunheim_rune_golem':'15프레임 하단 닫힌 바위 발과 어깨 여백 확인. 원본의 납작한 발 모양 유지. 기존보다 작아진 덩치는 한계.',
'muspelheim_magma_boar':'대기 다리, 공격 코·엄니, 피격 등 가시 보존 확인. 공격3 발굽 y72, 엄니 궤적만 y73.',
'alfheim_moon_stag':'공격 머리·앞몸과 피격 뿔 완전함. F4=F1 재사용 및 대기 대비 공격 체격 감소는 한계.',
'yggdrasil_root_guardian':'공격4칸 얼굴과 전방 주먹 모두 닫힘. 포즈별 팔 길이 차이는 원본에 존재.',
'niflheim_glacier_wolf':'대기4칸 발 복원, 공격2 코 복원. 원본에서 y256 아래 다리 확인.',
'asgard_runic_raven':'부리와 발 보존, 앞 발사체 분리.',
'midgard_rooftop_slinger':'새총 끝의 고리 윤곽 완전함.',
'svartalfheim_cog_drone':'공격2 포구 복원, 공격4 재작화 포구 닫힘. 청록 추진 불꽃 유지; 재작화 질감 차이 남음.',
'svartalfheim_gear_beetle':'공격2·3 드릴 끝과 발 보존, 전방 파편 분리.',
'ember_imp':'보라·밝은 림 제거, 꼬리 불꽃 유지, 상단 여백4px. 공격2 재작화 선명도 차이 남음.',
'mossling':'청록·밝은 림 제거, 원래 잎·몸 보존. 피격 별 제거 후 잎 윤곽 유지.',
'alfheim_moon_moth':'발사 구슬 제거, 자체 코어·더듬이·날개 보존.',
'asgard_aegis_ram':'돌진 궤적 제거, 몸 룬·다리·뿔 보존.',
'yggdrasil_root_oracle':'재작화로 발사 구슬 제거, 분홍 얼굴 코어와 뿌리 유지. 원래 칸보다 선명함.',
'jotunheim_storm_wisp':'재작화로 큰 발사 호 제거, 돌5개·코어·왼쪽 작은 궤도 유지. 돌 세부 명암 차이 남음.'}
ledger=[]
for p in sorted(OUT.glob('*.json')):
    data=json.loads(p.read_text(encoding='utf-8'));id=data['id']
    ledger.append({'id':id,'candidate_sha256':sha(p.with_suffix('.png')),'board':f'reports/codex-art-87/{id}.png','review':'Codex direct visual inspection of every changed cell at 1x and nearest-neighbour 4x; static, not animation/runtime','frames':[{'row':f['row'],'frame':f['frame'],'viewed_1x':True,'viewed_4x':True} for f in data['frames']],'subjective_judgment':judgments[id]})
(REPORT/'inspection.json').write_text(json.dumps({'kind':'manual visual judgments; numeric checks are in measurements.json','entries':ledger},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

files=['design/tasks/CODEX-ART-87.md','design/tasks/CODEX-ART-87.prompt.md']
files += [str(p.relative_to(ROOT)).replace('\\','/') for p in sorted(OUT.glob('*')) if p.suffix in ['.png','.json']]
files += [str(p.relative_to(ROOT)).replace('\\','/') for p in sorted(REPORT.glob('*.png'))]
files += [str(p.relative_to(ROOT)).replace('\\','/') for p in sorted((REPORT/'effects').glob('*')) if p.suffix in ['.png','.md']]
files += ['reports/codex-art-87/'+n for n in ['README.md','prompts.txt','repair.py','verify.py','package.py','measurements.json','inspection.json','commit.ps1','commit-message.txt','files-to-stage.txt']]
assert len(files)==len(set(files))
(REPORT/'files-to-stage.txt').write_text('\n'.join(sorted(files))+'\n',encoding='utf-8')
print('Packaged',len(files),'explicit staging paths; no git mutation.')
