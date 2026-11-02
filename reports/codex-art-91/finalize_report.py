"""Final ART-91 static audit and Korean handoff; exclusive new report outputs."""
from pathlib import Path
import sys,json,hashlib,shutil,importlib.util
from datetime import datetime
import numpy as np
from PIL import Image,ImageDraw,ImageFont
sys.dont_write_bytecode=True
s=importlib.util.spec_from_file_location('p91',Path(__file__).with_name('row_pipeline.py'));p=importlib.util.module_from_spec(s);s.loader.exec_module(p)
R=p.REPORT;root=p.ROOT
ids=['alfheim_moon_moth','asgard_runic_raven','ember_imp','jotunheim_rune_golem','jotunheim_storm_wisp','niflheim_frost_owl','svartalfheim_cog_drone','svartalfheim_gear_beetle']
failures=[];results=[]
for mid in ids:
 png=p.BAKE/f'{mid}-appear-v1.png';meta=json.loads(png.with_suffix('.json').read_text(encoding='utf-8'));m=json.loads((R/f'{mid}-appear-checks.json').read_text(encoding='utf-8'));im=Image.open(png).convert('RGBA')
 assert im.size==(576,96);assert all(meta.get(k)==v for k,v in dict(frames=6,fps=10,cell=96,feet=72,loop=False,new_row=True).items())
 checks=[];hashes=[]
 for i in range(6):
  frame=im.crop((96*i,0,96*(i+1),96));bb=frame.getbbox();margin=min(bb[0],bb[1],96-bb[2],96-bb[3]);a=np.asarray(frame);spill=p.n.spill_pixel_count(frame);digest=hashlib.sha256(frame.tobytes()).hexdigest();hashes.append(digest)
  check=dict(frame=i+1,margin=margin,bottom=bb[3]-1,spill=spill,binary_alpha=set(np.unique(a[:,:,3]).tolist())<={0,255},size_ratio=m['frames'][i]['landmark_ratio'],stored_hash_matches=digest==m['frames'][i]['sha256'])
  if margin<4 or spill or not check['binary_alpha'] or not .95<=check['size_ratio']<=1.05 or not check['stored_hash_matches']:failures.append(dict(id=mid,check=check))
  if m['config'].get('grounded',True) and check['bottom']!=72:failures.append(dict(id=mid,error='ground contact'))
  checks.append(check)
 if len(set(hashes))!=6:failures.append(dict(id=mid,error='duplicate frame'))
 assert Image.open(R/f'{mid}-appear.png').size==(2688,430)
 results.append(dict(id=mid,png=png.relative_to(root).as_posix(),frames=6,checks=checks,scale=m['factor'],size_method=m['config'].get('measure_override',m['config'].get('measure')),note=meta['note'],idle=m['config']['idle'],delivered_at=m['delivered_at']))
inv=json.loads((R/'inventory.json').read_text(encoding='utf-8'));records=[]
for e in inv['entities']:records+=e['candidates']
records+=inv['other_versioned_candidates']+inv['other_pngs'];unique={x['png']:x for x in records}
changed=[]
for rel,record in unique.items():
 if hashlib.sha256((root/rel).read_bytes()).hexdigest()!=record['sha256']:changed.append(rel)
assert len(unique)==554
if changed:failures.append(dict(preexisting_png_changes=changed))
assert not failures,failures
audit=dict(checked_at=datetime.now().astimezone().isoformat(),status='PASS',rows=8,frames=48,results=results,preexisting_pngs_verified=len(unique),preexisting_png_changes=changed,failures=failures,limitations='정적 파일과 수동 대표 부위 명목 측정; Godot·게임 재생 검증 없음. 자동 검사만으로 해부 전체 크기·모션 품질을 보장하지 않음.')
p.new_json(R/'verification.json',audit)
board=Image.new('RGB',(1344,8*222),(26,30,40));d=ImageDraw.Draw(board);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',17)
for row,result in enumerate(results):
 y=row*222;d.text((8,y+3),result['id']+' | idle + appear 1-6 | 2x',font=font,fill='white');idle=Image.open(root/result['idle']).convert('RGBA').crop((0,0,96,96));strip=Image.open(root/result['png']).convert('RGBA')
 for i,im in enumerate([idle]+[strip.crop((96*j,0,96*(j+1),96)) for j in range(6)]):
  big=im.resize((192,192),Image.Resampling.NEAREST);board.paste(big,(192*i,y+27),big)
p.save(board,R/'overview.png')
failed=['alfheim_moon_stag','asgard_aegis_ram'];all_monsters=[e['id'] for e in inv['entities'] if e['kind']=='monster'];unstarted=[m for m in all_monsters if m not in ids+failed]
lines=['# ART-91 작업 결과',f"\n작성: {audit['checked_at']} · `codex/art-91`",'\n**완료:** Part 1 목록은 14:46 KST에 저장(15:05 이전). Part 2는 `appear` **8행·48프레임**을 행별로 전달했다. 최종 실패/보류는 **2행**, 미착수 appear는 **8종**이다. 모든 appear를 끝내지 못했으므로 `rage`·`sleep`·`flee`는 시작하지 않았다.', '\n**현재 상태:** 전부 나중에 선택할 후보이며 게임 연결·Godot 실행·뷰어 게시·설치·다운로드·스테이징·커밋은 하지 않았다. 마지막 새 행은 딱정벌레로 15:40:53 시각 확인 후 시작했고, 15:45 이후 새 행 생성은 없었다.', '\n## 목록과 담당 경계','[한국어 모션 목록](inventory.md) · [기계 판독 목록](inventory.json) · [행별 진행 기록](progress.md)', '- 전투원 8형태·몬스터 18종, 기존 bakeoff PNG 554개 전수 조사. 후보 버전·adopted 표시·현재 게임 행을 분리했다.', '- 몬스터 현행 게임은 모두 4행(idle/walk/attack/hurt); 6행 후보 존재와 실제 게임 반영을 구별했다.', '- 일반 모션 제안: 몬스터 appear 우선 1, rage 우선 2; 전투원 run_stop·air_recovery 등. ART-92의 dodge_roll/taunt/stun/crouch/run_start와 기술 세션 소유 행은 제작에서 제외했다.', '\n## 시각적 확인','![idle과 등장 6프레임 비교](overview.png)','각 줄의 첫 칸은 기존 idle, 이어지는 6칸이 새 appear다. 위 그림은 2배 정지 비교판이며 각 행 링크는 원본 픽셀을 nearest로 4배 확대한 비교판이다. 게임 실행 화면은 아니다.', '\n## 전달 행', '|몬스터|행·파일|프레임|최소 여백|idle 대비 크기 지표|확인|','|---|---|---:|---:|---|---|']
for r in results:
 checks=r['checks'];ratios=[a['size_ratio'] for a in checks];margin=min(a['margin'] for a in checks)
 lines.append(f"|{r['id']}|[appear PNG](../../{r['png']}) · [4배 비교]({r['id']}-appear.png)|6|{margin}px|{min(ratios):.3f}~{max(ratios):.3f}|PASS · spill 0|")
lines+=['\n## 측정 사실과 육안 판단','- 실제 PNG 검사: 576×96, 고정 96px 분할, 6개 서로 다른 프레임, 셀 여백 ≥4px, 이진 알파, spill=0. 지상형 발 하단 y72; 부유형은 몸 표식을 기준 높이에 맞췄다.', '- **크기 열은 대표 부위의 명목 지표**다. 나방은 밝은 머리 연결 영역, 까마귀는 문양 전체 고리의 반경 중앙값; 나머지는 얼굴·두개부·돌 장축·외피의 수동 표식이다. 수동 원본 끝점 약 ±3px, idle 끝점 약 ±1px의 불확실성이 있고 전체 해부 구조의 정밀 계측은 아니다. 각 `*-checks.json`에 원본 좌표·방법·공통 배율·판정 한계를 남겼다.', '- 같은 외형·색조, 등장 동작의 읽힘, 별도 효과가 없는지는 비교판 육안 판단이다. 자동 수치가 미술 품질을 증명하지 않는다.', '- 모든 행에 행 공통 배율 하나를 사용했다. LANCZOS + unsharp 60, palette none. 필요한 행은 표준 despill auto를 적용했고, 부유 정렬은 프레임 전체 평행 이동만 사용했다.', '- 나방·위습의 후반 정착 변화는 작다. 드론은 마지막 집게가 idle보다 조금 열려 있고, 까마귀/드론은 여백을 위해 가로 정렬이 기준보다 약 2~2.5px 오른쪽이다. 실제 재생 연결감은 아직 확인하지 않았다.', '\n## 실패·수정 이력','|대상|최종 상태|이유|','|---|---|---|','|alfheim_moon_stag / appear|실패·미전달 (2회 생성)|뿔이 가는 열린 초승달형에서 두꺼운 왕관형으로 변함. 정체성 기준 탈락(육안).|','|asgard_aegis_ram / appear|보류·미전달 (1회 생성)|축소 후 뿔 색 영역이 끊겨 전 프레임 크기 ±5%를 신뢰성 있게 확인하지 못함. 실제 해부 크기 불량으로 확정한 것은 아님.|','|ember_imp / appear|수정 후 최종 전달|초기 검사에서 순수 키색만 세어 번짐 판정 8픽셀을 놓쳤다. 첫 전달을 회수·raw 보존한 뒤 표준 despill auto와 전체 교차 검사로 spill0 확인 후 새 최종 파일을 제공했다.|','|jotunheim_rune_golem / appear|2안 최종 전달|첫 원본 F5가 고정 셀 오른쪽 경계에 접촉. 재생성으로 해결.|','|jotunheim_storm_wisp / appear|2안 최종 전달|첫 안은 idle과 차이가 작았다. 두 번째 안은 룬판을 접었다 펴 핵이 드러나는 동작으로 변경.|','\n[전체 실패 이력](failed-rows.md). 실패 종의 후보 파일은 bakeoff에 없고 원본은 `art/raw/monsters-91/`에만 있다. 이번 작업 중 만든 임프 중간 전달본은 회수 보관했으며, 작업 시작 전에 존재하던 파일을 교체하지 않았다.', '\n## 최종 검증','[정적 검사 결과](verification.json): **8행·48프레임 PASS**, 기존 목록에 있던 **554개 PNG 해시 동일**. `git diff --name-only`와 `git diff --cached --name-only`는 빈 출력이었다. Godot 테스트나 실제 게임 재생을 했다는 뜻은 아니다.', '- 내장 ImageGen 13회(행당 최대 2회). [전체 프롬프트](prompts.json). 원본·버린 시도·눈금판은 raw에 보존하고 커밋에서 제외했다.', '\n## 남은 작업·다음 권장 단계', '- 미착수 appear 8종: '+', '.join(unstarted)+'.','- rage 18종, sleep/flee 전부 미착수. 다음 작업은 남은 appear와 두 보류 행을 마친 뒤 rage 순서다.', '- 리드/사용자가 8개 후보를 모션 뷰어에서 재생해 전환과 약한 후반 동작을 검토하고 채택 여부를 결정한다.', '\n## 인계','[commit-paths.txt](commit-paths.txt)에는 최종 행·비교판·검사 근거·보고서만 있다. [commit.ps1](commit.ps1)은 이 목록 + inventory.md/json + ART-91 카드/prompt를 `git add --pathspec-from-file`로 스테이징하도록 준비했다. **실행하지 않았으며 커밋 명령도 넣지 않았다.** raw, 시도 덤프, run.log, __pycache__, 다른 작업 파일은 제외한다.']
with (R/'README.md').open('x',encoding='utf-8',newline='\n') as f:f.write('\n'.join(lines)+'\n')
extra=['prepare_gold.py','raven_final.py','align_manual.py','despill_trial.py','finalize_report.py','prompts.json','verification.json','overview.png']
with (R/'commit-paths.txt').open('a',encoding='utf-8') as f:
 for name in extra:f.write('reports/codex-art-91/'+name+'\n')
# Keep the rejected wisp generation too; the final generation already has its source copied.
src=Path('C:/Users/TH/.codex/generated_images/01a18105-8977-7e21-8b97-3be33acd4e7e/exec-34422579-8ad9-4718-8d3a-566b92aaa111.png');dst=p.RAW/'wisp-rejected-idle-like.png';assert not dst.exists();shutil.copyfile(src,dst)
manifest=(R/'commit-paths.txt').read_text(encoding='utf-8').splitlines();assert len(manifest)==len(set(manifest));assert all((root/x).is_file() for x in manifest);assert not any('/raw/' in x or 'run.log' in x or '__pycache__' in x for x in manifest)
print(json.dumps(dict(report_written=datetime.now().astimezone().isoformat(),rows=8,frames=48,verification='PASS',old_pngs_unchanged=len(unique),manifest_paths=len(manifest)),ensure_ascii=False))
