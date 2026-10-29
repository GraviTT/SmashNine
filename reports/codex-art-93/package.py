"""Publish ART-93 immutable candidates and evidence; never stages or commits."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, shutil, subprocess
from pathlib import Path
import numpy as np
from PIL import Image
from inspect_inputs import ROOT, OUT, CONFIG, fresh, dump, sha, frames, board
import rebuild as r

NAMES={'alfheim_moon_moth':'달나방','yggdrasil_root_oracle':'뿌리 예언자','asgard_aegis_ram':'방패 산양',
 'asgard_runic_raven':'룬 까마귀','niflheim_frost_owl':'서리 올빼미','ember_imp':'불씨 임프',
 'yggdrasil_root_guardian':'뿌리 수호자','jotunheim_storm_wisp':'폭풍 위습'}
OBS={
 'alfheim_moon_moth':'준비의 구형 머리와 날개가 커졌고 더듬이 끝이 보인다. 패배는 가로로 누운 F4가 여백 한계에 가까워 거의 그대로다. 기존 대기와 새 동작 사이의 질감 차이는 원래 존재하며 이번에 맞추지 않았다.',
 'yggdrasil_root_oracle':'준비 F3·F4의 아래 촉수가 짧고 납작해졌다. 머리·눈·봉오리와 위로 든 앞 촉수는 유지됐다. 대기·공격과 비교해 머리의 수직 위치는 비슷하지만 준비의 몸통 회전과 오른쪽 치우침은 기존 자세 그대로다. 패배는 확대가 눈에 보인다.',
 'asgard_aegis_ram':'준비와 패배의 크기 변화는 육안상 거의 없다. 금색 뿔, 어깨 룬과 발이 유지되며 낮게 숙인 준비 F2와 누운 패배 F4가 가로 여백을 거의 다 쓴다.',
 'asgard_runic_raven':'날개를 세운 준비 F2가 상단 안전선에 가깝다. 준비는 사실상 같은 크기이고 패배는 조금 커졌다. 금색 어깨 원판과 부리가 유지된다. 준비 F2 하단 y74는 기존 비행 자세의 값으로 남았다.',
 'niflheim_frost_owl':'준비의 몸·머리·깃이 커졌고 F4의 높이가 유지 대기에 가까워졌다. 패배는 누운 F4의 왼쪽 여백 때문에 거의 같은 크기다. 눈·부리와 가슴 무늬가 보인다.',
 'ember_imp':'준비와 패배 모두 커졌고 발선은 유지됐다. 꼬리와 뿔 끝이 셀 안에 남는다. 유지 대기와 신행의 형태·질감 차이는 크기 조절만으로 없어지지 않는다.',
 'yggdrasil_root_guardian':'준비는 소폭 커졌고 마지막에 머리 위로 든 주먹이 상단 안전선에 가깝다. 패배 F1의 높은 봉오리 때문에 패배 확대는 거의 없다. 주먹·뿌리 끝의 잘림은 보이지 않는다.',
 'jotunheim_storm_wisp':'준비와 패배 모두 커졌다. 준비의 돌이 핵 쪽으로 모이는 순서와 떠 있는 간격, 마지막 패배의 바닥에 쌓인 돌이 유지된다. 돌·룬·밝은 핵을 식별할 수 있다.'}

def main():
 rows=json.loads((r.RAWOUT/'rows.json').read_text('utf-8'))
 assert len(rows)==16
 checks=[]
 def ck(label,condition):
  checks.append(dict(check=label,pass_=bool(condition)))
  if not condition:raise AssertionError(label)
 # Preflight all new filenames before publishing anything.
 for x in rows:
  for p in [ROOT/x['new'],(ROOT/x['new']).with_suffix('.json')]:ck('new-only '+str(p.relative_to(ROOT)),not p.exists())
 output_paths=[]
 for x in rows:
  mid=x['monster'];row=x['row'];name=Path(x['new']).name;im=Image.open(ROOT/x['review']).convert('RGBA')
  fs=frames(ROOT/x['review']);old=frames(ROOT/x['old'])
  ck(name+' canvas',im.size==(576,96))
  ck(name+' blank cells',not im.crop((384,0,576,96)).getbbox())
  ck(name+' common factor >= 1',1<=x['used']<=x['k'])
  ck(name+' raw reconstruction visible+alpha',all(x['baseline_alpha_and_visible_exact']))
  for i,f in enumerate(fs):
   st=r.stats(f);a=np.array(f)
   ck(name+f' F{i+1} 4px margin',st['margin']>=4)
   ck(name+f' F{i+1} binary alpha',set(np.unique(a[:,:,3])).issubset({0,255}))
   ck(name+f' F{i+1} no clip',st['bbox']==x['placement'][i]['final_bbox'])
   ck(name+f' F{i+1} no width shrink',st['width']>=r.stats(old[i])['width'])
   if not(mid=='yggdrasil_root_oracle' and row=='windup'):
    ck(name+f' F{i+1} no height shrink',st['height']>=r.stats(old[i])['height'])
  sources=[]
  for src,box in zip(r.n.split_sheet(ROOT/x['raw'],(2,2))[0],x['source_boxes']):
   src=r.n.clean_background(src,'#00ff00')[0];b=box['bbox'];p=box['transparent_padding'];sources.append(src.crop((b[0]-p,b[1]-p,b[2]+p,b[3]+p)))
  oracle=mid=='yggdrasil_root_oracle' and row=='windup'
  if x['used']<x['k']:
   _,failed=r.build(sources,old,x['old_factor'],x['used']+1e-7,oracle)
   ck(name+' any +0.0000001 exceeds limit',any(p['violations'] for p in failed))
  if oracle:
   unclipped,_=r.build(sources,old,x['old_factor'],x['used'],False)
   for i,(a,b) in enumerate(zip(fs,unclipped)):
    ck(name+f' F{i+1} upper body unchanged by tentacle fix',np.array_equal(np.array(a)[:58],np.array(b)[:58]))
    ck(name+f' F{i+1} ground y72',a.getbbox()[3]-1==72)
  limit=x['last_rejected']['violations'] if x['last_rejected'] else []
  x['binding_limit']=limit
  note=f"ART-93: 고해상도 원본에서 행 공통 배율로 재정규화. 목표 ×{x['k']:.6f}, 적용 ×{x['used']:.9f}; 유지 대기 대비 행 평균 그림 높이 {x['height_ratio_before']:.6f}→{x['height_ratio_after']:.6f}. 제한: {','.join(limit) or '없음'}."
  if oracle:note+=' 머리·몸 위쪽 y<58 보존, 아래 촉수만 압축해 네 장 모두 최하단 y72.'
  meta={key:x['metadata'][key] for key in ['frames','fps','cell','feet','loop']}
  for key in ['windup_seconds','hold_last']:
   if key in x['metadata']:meta[key]=x['metadata'][key]
  meta.update(replaces=Path(x['old']).name,factor=x['new_factor'],size_k=x['k'],size_used=x['used'],
   from_raw=True,raw_path=x['raw'],note=note,limited_by=limit,
   height_ratio_before=x['height_ratio_before'],height_ratio_after=x['height_ratio_after'],
   lowest_drawn_rows=[z['bottom'] for z in x['after']],
   method='original chroma #00ff00 / LANCZOS / unsharp radius1 percent60 threshold2 / alpha128 / despill auto; pivot (48,72)',
   source_padding=[z['transparent_padding'] for z in x['source_boxes']])
  if oracle:meta['tentacle_fix']=[p['tentacle_squash'] for p in x['placement']]
  shutil.copyfile(ROOT/x['review'],fresh(ROOT/x['new']))
  dump((ROOT/x['new']).with_suffix('.json'),meta)
  output_paths.extend([x['new'],str(Path(x['new']).with_suffix('.json')).replace('\\','/')])
  x['output_sha256']=sha(ROOT/x['new'])
  x['changed_visible_pixels']=[int(np.count_nonzero(np.any(np.array(a)!=np.array(b),axis=2)&((np.array(a)[:,:,3]>0)|(np.array(b)[:,:,3]>0)))) for a,b in zip(fs,old)]
  del x['metadata']
 for mid,*_ in CONFIG:
  shutil.copyfile(r.RAWOUT/f'{mid}-review-4x.png',fresh(OUT/f'{mid}.png'))
  output_paths.append(f'reports/codex-art-93/{mid}.png')
 visual={mid:dict(board=f'{mid}.png',scale=4,method='NEAREST, 각 셀 384×384, 실제 PNG를 view_image original로 열어 F1–F4 확인',observation=OBS[mid],assessment='정지 PNG 육안 관찰; 애니메이션/게임 검증 아님') for mid,*_ in CONFIG}
 dump(OUT/'visual-review.json',visual)
 dump(OUT/'measurements.json',rows)
 protected=json.loads((OUT/'input-hashes.json').read_text('utf-8'))
 changed=[p for p,h in protected.items() if not(ROOT/p).is_file() or sha(ROOT/p)!=h]
 ck('all protected pre-existing inputs unchanged',not changed)
 branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()
 ck('branch codex/art-93',branch=='codex/art-93')
 ck('no staged files',not subprocess.check_output(['git','diff','--cached','--name-only'],cwd=ROOT,text=True).strip())
 dump(OUT/'verification.json',dict(checks=checks,passed=len(checks),failed=0,protected_files=len(protected),changed_protected=changed,
  game_run=False,godot_run=False,git_stage=False,git_commit=False,all_64_frames_from_raw=True))

 report=['# ART-93 — 몬스터 준비·패배 크기 및 예언자 촉수',
 '\n완료: 8종 16행(64프레임)을 원본에서 재정규화해 **새 버전만** 만들었다. 5행은 목표 배율에 도달했고 11행은 고정 발 기준점과 셀 여백 때문에 제한됐다. 기존 그림·제품 폴더를 보존했다. 게임 적용·Godot·웹 빌드·stage·commit은 하지 않았다.',
 '\n## 측정 기준과 방법',
 '- 그림 높이: 알파가 0보다 큰 픽셀 bbox의 세로 길이. 유지 idle은 실제 비어 있지 않은 4장, 후보 idle은 6장의 산술평균이다. k = 유지 idle 평균 / 후보 idle 평균. 카드의 반올림 값과 모두 일치했다.',
 '- 높이비는 **준비/패배 4장 평균 그림 높이 ÷ 유지 idle 평균 높이**다. 쓰러지는 포즈는 자연스럽게 낮아진다. 높이비 1.0을 목표로 따로 늘이거나, 해부학적 체격이 일치한다고 인증하지 않았다.',
 '- 16행 모두 raw 사용. 달나방 준비는 ART-83 원본, 달나방 패배·산양·까마귀·임프는 ART-71, 나머지는 ART-76이다. 경로·SHA-256·원본 bbox·배치·각 프레임 값은 [measurements.json](measurements.json)에 있다. 저해상도 행 확대 대체는 0행이다.',
 '- 원래와 같은 2×2 순서, 초록 키 #00ff00 제거, LANCZOS, unsharp 60(radius 1, threshold 2), alpha 128, despill auto, 팔레트 미사용. 수호자 패배 F1만 ART-90의 투명 원본 여백 4px를 그대로 사용했다.',
 '- 각 행의 모든 프레임에 동일한 `old factor × size_used`를 적용했다. 위치는 기존 bbox 중심과 최하단의 (48,72) 상대좌표를 같은 비율로 변환한 뒤 정수 반올림한다. 경계를 피하려고 별도로 좌우/상하 이동하지 않았다. x/y 4..91 안에 모든 불투명 픽셀이 들어간다.',
 '- 크기·배치의 반올림이 바뀌는 모든 배율 경계를 내림차순으로 검사했다. 최대 유효 배율을 사용했으며 경계 바로 아래가 필요할 때는 1e-9를 뺐다. 제한 행은 사용 배율 +1e-7에서 실제 여백 위반도 확인했다. 아래 표는 반올림 표기이므로 재구축에는 JSON의 전체 정밀도 값을 사용한다.',
 '- 원래 배율에서 64/64장의 **알파와 보이는 RGB가 동일**하게 재현됐다. RGBA 전체는 63/64장 동일: 수호자 패배 F1의 완전 투명 픽셀 395개는 숨은 RGB가 0으로 정리됐고 보이는 그림에는 차이가 없다. 추정한 원본을 맞는 원본이라고 단정한 것이 아니라 재현 비교로 확인했다.',
 '\n## 행별 결과',
 '| 몬스터 | 행 | 목표 k | 적용 size_used | raw 정규화 factor 전→후 | 한계 | 높이비 전→후 | 최하단 F1–F4 |',
 '|---|---|---:|---:|---|---|---|---|']
 for x in rows:
  limit='/'.join({'width':'폭','height':'높이'}[v] for v in x['binding_limit']) or '없음'
  report.append(f"| {NAMES[x['monster']]} | {'준비' if x['row']=='windup' else '패배'} | {x['k']:.6f} | {x['used']:.9f} | {x['old_factor']:.9f} → {x['new_factor']:.9f} | {limit} | {x['height_ratio_before']:.4f} → {x['height_ratio_after']:.4f} | {', '.join(str(a['bottom']) for a in x['after'])} |")
 report.extend(['\n폭/높이는 목표 배율에서 생기는 모든 문제의 목록이 아니라, 사용 배율보다 더 키울 때 먼저 막는 조건이다. 제한 때문에 산양 두 행·까마귀 준비·올빼미 패배·수호자 패배는 평균 그림 높이가 그대로다. 이를 유지 대기 크기에 완전히 맞췄다고 보고하지 않는다.',
 '\n## 예언자 아래 촉수',
 '유지 idle·attack과 준비를 [4배 기준 보드](oracle-reference-4x.png)에서 비교했다. 기존 준비 최하단은 실제 측정 **75 / 79 / 86 / 86**이다(카드의 76–87은 끝 경계를 포함하는 표기와 1px 차이). 원점이 0인 픽셀 행으로 보고한다.',
 '행 공통 배율은 1.0009239287813365이며 F2의 오른쪽 여백 때문에 확대가 제한된다. 전체 머리·몸을 옮기지 않았다. 정규화 후 **y<58 픽셀은 그대로** 보존하고 y58부터 아래 촉수만 F1–F4 각각 15/18, 15/22, 15/29, 15/29 높이로 압축했다. 최하단은 네 장 모두 **y72**, y73 아래 불투명 픽셀은 0이다. 이는 허용된 국소 촉수 압축이며 행의 전신 배율을 프레임마다 달리 적용한 것이 아니다.',
 '육안상 F3·F4의 아래 촉수는 이전보다 납작한 곡선이 됐다. 머리·눈·봉오리와 위로 든 앞 촉수는 유지된다. 이 결과를 새로 그린 촉수라고 표현하지 않는다.',
 '\n## 4배 보드 관찰',
 '각 보드는 위에서부터 기존 준비 / 새 준비 / 기존 패배 / 새 패배다. 매 줄 첫 칸은 유지 idle F1이며 이어서 동작 F1–F4가 온다. 각 셀은 정확히 384×384(NEAREST 4×), 파란 테두리는 4px 여백, 분홍선은 y72 픽셀 바로 아래 경계다. 8장을 모두 열어 확인했다. 아래 관찰은 정지 그림에 대한 육안 판단이며 정량 검사와 구분한다.'])
 for mid,*_ in CONFIG:report.append(f"\n- [{NAMES[mid]} 4배 보드]({mid}.png): {OBS[mid]}")
 report.extend(['\n![예언자 준비·패배 비교](yggdrasil_root_oracle.png)',
 '예언자 보드의 두 번째 줄에서 아래 촉수가 분홍 바닥선 안에 들어오며, 머리와 들어 올린 촉수는 유지된다.',
 '\n## 확인·인계',
 f"- [verification.json](verification.json): 정적 확인 {len(checks)}개 통과, 실패 0. 16개 576×96 스트립, 사용 64셀의 4px 여백·이진 알파·잘림 없음·빈 2셀·배율 비축소·제한 바로 위 위반·예언자 상부 보존과 최하단을 확인했다.",
 f'- 기존 입력/추적 파일 {len(protected):,}개 SHA-256 일치. `smash-nine-prototype/`와 원본·이전 후보를 수정하지 않았다. 신규 JSON의 frames/fps/cell/feet/loop 및 windup_seconds/hold_last는 교체 대상에서 복사했다. 기존 adopted 표시는 새 후보에 복사하지 않았다.',
 '- [commit.ps1](commit.ps1)은 인계용 stage 스크립트이며 실행하지 않았다. [commit-paths.txt](commit-paths.txt)의 명시 파일 및 ART-93 카드·프롬프트만 `git add --pathspec-from-file`에 전달한다. 강제 add·raw·다른 작업·중간 시도·캐시·run.log는 목록에 없다. 자동 commit 명령도 넣지 않았다.',
 '- [rebuild.py](rebuild.py)는 원본에서 재구축하고 [package.py](package.py)는 신규 결과와 보고서를 만든다. 재실행 시 기존 출력이 있으면 중단한다. 검증만 하려면 `python -B reports/codex-art-93/verify.py`를 사용한다.',
 '\n**현재 상태:** 후보 PNG/JSON과 보드 전달 완료. **남은 작업:** 리드의 게임 시트 재조립, Godot 테스트 및 8061 웹 확인. **다음 권장 단계:** 먼저 11개 제한 행의 기록을 확인한 뒤 채택본에 연결한다. 추가 확대에는 위치 변경 또는 그림 재설계에 대한 별도 결정이 필요하다.'])
 fresh(OUT/'README.md').write_text('\n'.join(report)+'\n',encoding='utf-8',newline='\n')
 output_paths += ['reports/codex-art-93/'+p for p in ['README.md','measurements.json','visual-review.json','verification.json','input-hashes.json','oracle-reference-4x.png','inspect_inputs.py','rebuild.py','package.py','verify.py','commit.ps1','commit-paths.txt']]
 output_paths += ['design/tasks/CODEX-ART-93.md','design/tasks/CODEX-ART-93.prompt.md']
 fresh(OUT/'commit-paths.txt').write_text('\n'.join(sorted(output_paths))+'\n',encoding='utf-8',newline='\n')
 print(json.dumps(dict(rows=len(rows),frames=64,checks=len(checks),protected_files=len(protected),files_to_stage=len(output_paths)),ensure_ascii=False))

if __name__=='__main__':main()
