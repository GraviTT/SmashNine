"""Write the reviewed report, static evidence and explicit commit handoff."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,math,subprocess
from pathlib import Path
from PIL import Image,ImageDraw
import work as w
P=w.REPORT;R=w.ROOT;B=w.BAKE
def main():
 # Manually read at 4x, checked against the enlarged pixel coordinate grid.
 luna_marks=[[[82.25,67.5],[89.75,66.25],[77,67],[91,67]],[[73.25,50.5],[80.75,49.5],[68,50],[82,50]],[[73.25,50.5],[80.75,49.25],[68,50],[82,50]]]
 fs=w.frames(B/'luna/luna-idle-v3.png',1)+w.frames(B/'luna/luna-fall-v3.png',2);panels=[];measure=[]
 for i,(f,mm) in enumerate(zip(fs,luna_marks)):
  eye=math.dist(mm[0],mm[1]);width=mm[3][0]-mm[2][0]
  if i==0:ref=eye;refw=width
  rec=dict(frame='anchor' if i==0 else i,landmarks=mm,eye_distance=eye,face_width=width,eye_ratio=eye/ref,face_width_ratio=width/refw);measure.append(rec)
  x0=round(mm[0][0])-20;y0=round(mm[0][1])-20;z=f.crop((x0,y0,x0+48,y0+44)).resize((192,176),Image.Resampling.NEAREST);bg=Image.new('RGB',(220,218),(29,33,43));bg.paste(z,(12,28),z);d=ImageDraw.Draw(bg)
  d.text((4,4),'ANCHOR' if i==0 else f'F{i} E{eye/ref:.3f} W{width/refw:.3f}',fill='white')
  for j,(x,y) in enumerate(mm):
   xx=12+(x-x0+.5)*4;yy=28+(y-y0+.5)*4;c='cyan' if j<2 else 'yellow';d.line((xx-3,yy,xx+3,yy),fill=c);d.line((xx,yy-3,xx,yy+3),fill=c)
  panels.append(bg)
 im=Image.new('RGB',(660,218))
 for i,p in enumerate(panels):im.paste(p,(i*220,0))
 im.save(P/'luna-manual-landmarks-4x.png')
 nova=json.loads((P/'nova-manual-first.json').read_text('utf-8'))
 heads=dict(method='4x nearest crops manually compared; pixel-coordinate grids used to record eye centres and exposed face-width endpoints, hair excluded. Whole-head template is supporting evidence only.',uncertainty='눈/피부 끝점 각각 최소 ±0.5px. 가려진 반대쪽 눈은 약 ±1px. 약 8px 눈 간격에 4%는 0.32px뿐이므로 반 픽셀 단위 명목값만으로 확정하지 않음. 소수는 표식 좌표 계산값이며 정확도 보증 아님.',luna=dict(status='수정 불필요',frames=measure,automatic_median=.94,decision='눈 간격 0.995–1.000, 얼굴 폭 1.000. 자동 머리는 위로 뜬 머리카락의 영향을 받음. v3 보존.'),nova=nova,nova_decision='재검사 완료, 수리 판정 미확정. 양쪽 형태의 가려진 눈/얼굴 경계에 0.5~1px 수준 차이가 있으며 일부 명목 비율은 0.96~1.04 밖이다. 그 차이가 실제 머리 배율인지 얼굴 각도·앞머리 가림·표식 오차인지 확정하지 못했다. 범위 통과로 인증하지 않으며, 확정 이탈 때만 재작화하라는 카드에 따라 채택 v1 보존·새 후보 없음.')
 w.js(P/'head-rechecks.json',heads)
 # Reuse the previous manually identified near-fist landmark, track source sampling scale.
 previous=json.loads((R/'reports/codex-art-76/fix-1/sizes.json').read_text('utf-8'))
 if isinstance(previous,dict):previous=previous.get('measurements',previous.get('sizes',previous))
 size=[]
 # Prior verified projections: idle 20.16, attack 19.95, defeat 20.357142857.
 for row,grid,fac,oldwidth in [('attack',(3,2),.1785,19.95),('defeat',(2,2),.1425,20.357142857142854)]:
  src=w.n.split_sheet(w.copy(f'art/raw/monsters-76/yggdrasil_root_guardian-{row}.png'),grid)[0][0];clean,_=w.n.clean_background(src,'#00ff00');b=clean.getbbox();sw=b[2]-b[0]+8;effective=round(sw*fac)/sw;after=oldwidth*effective/fac
  size.append(dict(row=row,part='가까운 주먹의 가로 투영 폭: ART-76 fix-1 수동 표식을 실제 재슬라이싱 x 배율로 추적',source_manual_measurement='reports/codex-art-76/fix-1/sizes.json',reference_idle=20.16,before_px=oldwidth,after_px=after,ratio=after/20.16,nominal_factor=fac,effective_x_sampling_factor=effective,source_padding=4,source_region=[b[0]-4,b[1]-4,b[2]+4,b[3]+4],uncertainty_px=1))
 w.js(P/'guardian-size.json',size)
 # A compact actual-frame comparison; 4x, no illustration or simulated game UI.
 groups=[]
 for row,ver in [('attack','v1'),('defeat','v2')]:
  groups.append((f'Guardian {row} F1: BEFORE / AFTER',[w.frames(w.copy(f'art/bakeoff/monsters/yggdrasil_root_guardian-{row}-{ver}.png'),1)[0],w.frames(B/f'monsters/yggdrasil_root_guardian-{row}-v2.png',1)[0]]))
 groups.append(('Hound idle F1: BEFORE / AFTER',[w.frames(w.copy('art/bakeoff/monsters/vanaheim_vine_hound-idle-v2.png'),1)[0],w.frames(B/'monsters/vanaheim_vine_hound-idle-v2.png',1)[0]]))
 old=w.load(w.copy('art/bakeoff/monsters/legacy/alfheim_moon_stag_sheet-fix1.png'));new=w.load(B/'monsters/legacy/alfheim_moon_stag_sheet-fix1.png')
 groups.append(('Stag attack F4: BEFORE / AFTER',[old.crop((288,192,384,288)),new.crop((288,192,384,288))]))
 w.board(P/'overview.png',groups,'ART-90 reviewed candidates | exact 4x',4)
 data=json.loads((P/'measurements.json').read_text('utf-8'));rows=[];totals=[0,0,0]
 for row in data['hound']:
  st=row['speckle'];before=sum(x['before']['outliers_gt35'] for x in st);after=sum(x['after']['outliers_gt35'] for x in st);changed=sum(x['changed_rgb_pixels'] for x in st);totals=[totals[0]+before,totals[1]+after,totals[2]+changed]
  detail=[x['after']['detail'] for x in row['frames']];rows.append(f"| {row['row']} | {len(st)} | {before} → {after} | {changed} | {min(detail):.2f}–{max(detail):.2f} |")
 print('hound totals:',totals,'guardian ratios:',[round(x['ratio'],4) for x in size])
 w.js(P/'visual-review.json',dict(method='모델이 파일을 열어 실제 최종 PNG의 1x 및 nearest 4x를 직접 검수. 자동 미술 판정 아님.',changed_frames=34,guardian='공격 F1 양 주먹·뿌리 발 온전, 패배 F1 가지 끝·얼굴 온전. 원본 자세 유지. 최상단 1px 차이는 재샘플링 결과이며 팔을 새로 낮춰 그린 것이 아님.',hound='최종 눈 보호 수정 후 28프레임 전부 재검수. 큰 잎의 겹침·줄기·턱·발·눈 유지. 고립된 점 대비 감소, 자연스러운 미세 잎 질감은 남음. idle은 원래 부드러운 질감이며 수치 detail 85 미달이 해결됐다고 주장하지 않음.',stag='1x/4x 4프레임 모두 확인. F1 준비→F2 길게 도약→F3 뒷다리를 모은 도약→F4 회복의 서로 다른 실루엣. 원본의 꼬리·뿔·발 절단 없음. 재작화 F3/F4의 질감은 이웃과 조금 다르며 실제 재생의 연결감 미검증.',heads='Luna 2장, Nova 여성/남성 각6장과 기준 얼굴을 수동 표식으로 대조. Nova는 통과 판정 보류.',boards=[p.name for p in P.glob('*4x*.png')]+['hound-all-1x.png','guardian-attack-1x.png','guardian-defeat-1x.png','stag-attack-1x-1.png','stag-attack-1x-2.png']))
 text=f'''# ART-90 — 마지막 몬스터 수리 후보와 머리 재검사

완료: 수호자 2프레임, 사냥개 28프레임, 구형 사슴 4프레임을 수정했다. 수호자·사냥개 6행 합본도 재조립했다. 모두 **후보**이며 게임 적용·Godot 실행·git stage/commit은 하지 않았다.

| 항목 | 판정 | 실제 결과 |
|---|---|---|
| 수호자 attack F1 / defeat F1 | 완료 | 원본 재슬라이싱으로 상단 **3→4px**, 높이 **70→69px**, 발 **y72**. 주먹 크기/idle **{size[0]['ratio']:.3f} / {size[1]['ratio']:.3f}**(기존 수동 표식 환산, ±1px). attack-v2 신규, defeat-v2 갱신. 다른 프레임 동일. |
| 덩굴 사냥개 6행 | 완료 | **28프레임**, 잎 내부 대비 이상점 **{totals[0]}→{totals[1]}**, RGB **{totals[2]}px**만 보정. 알파·눈 보호 영역·위치·배율 동일. |
| 구형 달 사슴 attack | 완료 | F1/F2 원본 배율 **0.25→0.294**, F3/F4 전신 재작화. **4장 모두 고유**, 폭 **82/87/84/74px**, 최소 여백 **4px**. 공격 외 **20셀** 동일. |
| Luna fall-v3 머리 | 수정 불필요 | 수동 눈 간격 비율 **0.995–1.000**, 얼굴 폭 **1.000**. 자동 머리 중앙값 0.94와 구분. v3 그대로. |
| Nova 여성/남성 meteor_kick 머리 | 재검사 완료 · 수리 여부 미확정 | 여성 눈 **0.940–1.002**, 폭 **1.000–1.067**; 남성 눈 **0.998–1.125**, 폭 **1.031–1.062**. 가려진 눈/경계의 0.5–1px 표식 오차와 각도 차이를 분리하지 못했다. **허용 범위 통과로 인증하지 않음.** 확정 이탈 때만 수정하라는 카드에 따라 채택본 보존, 새 후보 없음. |

## 시각적 확인

![실제 프레임 수정 전후](overview.png)

왼쪽은 작업 전, 오른쪽은 최종 후보의 정확한 4배 확대다. 위부터 수호자 공격·패배 F1, 사냥개 대기 F1, 사슴 공격 F4다. 게임 화면이 아닌 실제 PNG 비교다.

수호자: [공격 1x](guardian-attack-1x.png) / [4x](guardian-attack-4x.png), [패배 1x](guardian-defeat-1x.png) / [4x](guardian-defeat-4x.png). 사냥개: [28장 전체 1x](hound-all-1x.png), `hound-<행>-4x-<부분>.png` 전 11장. 사슴: [F1–2 4x](stag-attack-4x-1.png), [F3–4 4x](stag-attack-4x-2.png), 같은 이름의 1x 판. **변경한 34프레임 전부 1x/4x 직접 확인**했다.

## 측정과 육안 판단

수호자는 원본이 온전했다. tight bbox 대신 투명 주변 4 원본px를 포함해 동일 배율 attack=0.1785 / defeat=0.1425로 다시 줄였다. 반올림·샘플링 위치 차이로 1px를 확보했으며, 상단을 지우거나 팔을 붙이거나 전신을 따로 줄이지 않았다. [주먹 크기 근거](guardian-size.json)는 ART-76 fix-1의 수동 주먹 표식을 실제 x 샘플링 비율로 환산한 값이다. 같은 부위의 투영 지표이며 전신 해부 비율 정밀 인증은 아니다.

사냥개는 기존 v2를 입력으로 잎 RGB 영역(G>1.08R, G>1.08B) 중 주변 8개에서 잎이 6개 이상인 픽셀만 검사했다. 주변 RGB 중앙값과 평균 밝기가 25 넘게 다르면 80%만 중앙값 쪽으로 보정한다. 밝은 눈 코어(R>150,G>180,B>100)와 주변 3px는 제외한다. 공간 전체 블러·팔레트 변경·알파 변경은 없다. 아래 이상점은 **수정 전 고정 마스크**에서 주변 밝기 중앙값과 차이>35인 픽셀 수로, ART-83의 원본 hue 마스크와 다르므로 그 숫자와 직접 이어 비교하지 않는다. 결함 개수나 미술 품질 점수도 아니다.

| 행 | 프레임 | 대비 이상점 전→후 | RGB 변경 | detail 후 |
|---|---:|---:|---:|---:|
{chr(10).join(rows)}

잎 겹침·몸통·눈은 육안상 유지되고 잔점 대비가 줄었다. 미세 자연 질감은 남는다. ART-76의 detail≥85 목표는 일부 행에서 여전히 미달이다. 저대비화는 이번 점 정리의 부수 효과이며 이를 디테일 증가로 보고하지 않는다.

사슴 원본에는 3개 공격 자세만 있다. F1/F2는 JSON에 적은 원본 영역을 다시 잘랐다. F3는 0.294배에서 폭 약104px가 되어 88px 가용 폭을 넘으므로 뒷다리를 모은 전신을 재작화했다. F4는 F1 복제 대신 착지 후 회복을 그렸다. 이미지 도구 **2회**, 각 대상과 같은 행의 이웃 프레임을 참조했다. 고해상도 단일 출력은 F3=0.065, F4=0.075로 전신 축소했다. 이는 생성 원본 해상도가 다른 단일 포즈의 배율이다. 머리·다리 붙이기 없음. F1/F2의 원본 배율 일치와 F3/F4의 체격·윤곽은 4배에서 확인했지만, 재작화 질감 차이와 실제 재생 연결감은 남은 검토 대상이다. 기존 구형 시트의 발 경계 y72(마지막 불투명 픽셀 y71)를 유지했다.

## 얼굴 재검사 — 자동 점수와 구분

[수동 측정 JSON](head-rechecks.json), [Luna 표식](luna-manual-landmarks-4x.png), [Nova 여성 표식](nova_female-manual-landmarks-4x.png), [Nova 남성 표식](nova_male-manual-landmarks-4x.png). 청록=눈 중심, 노랑=머리카락 제외 얼굴 폭 끝점. 두 Nova 채택 스트립이 현재 게임 기술 시트 5행과 RGBA 동일함도 확인했다.

4배에서 수동으로 표식을 잡고 픽셀 좌표 확대에서 기록했다. 눈/경계 끝점은 최소 ±0.5px, 가려진 반대쪽 눈은 약 ±1px 불확실성이 있다. 약8px 눈 간격에서 허용 4%는 0.32px여서 표식의 작은 변화가 판정을 바꾼다. **Nova의 일부 명목값이 범위 밖인 사실을 숨기지 않으며, 그 행을 통과·수정 불필요로 확정하지 않는다.** 머리 전체 정합을 얼굴보다 우선해 억지로 맞추지도 않았다. 추가 local-patch 정합도 머리카락/가려진 눈으로 이동하여 판정 근거에서 제외했다.

`head_scale.py` 실제 실행 결과: Luna 0.94, Nova 여성 1.02, 남성 1.04(중앙값). 개별 프레임은 JSON에 있다. 이 값만으로 Nova 수동 표식의 불확실성을 해소할 수 없다. **남은 작업은 Nova 얼굴의 대응 표식을 리드와 재확정하는 것**이다. 확정 전에는 채택된 v1을 건드리지 않았다.

## 정적 검사와 인계

[verification.json](verification.json): 정적 검사 **173/173 통과**, 변경 고유 프레임 **34**, 비대상 파일 **2,230개 SHA-256 동일**. 이는 PNG/메타데이터/변경 범위 검사 결과이며 Nova 얼굴이나 실제 재생의 합격 판정이 아니다.

- 수호자 F1 외 사용 8프레임 동일, 빈 셀 동일. 최소 여백4·발y72·이진알파·spill0.
- 사냥개 28프레임 알파·밝은 눈+3px 동일, 변경 RGB가 명시된 함수와 일치. 정상 잎 녹색을 spill로 오판하지 않으며 순수 #00ff00은 0.
- 6행 합본 2장 모든 행이 최종 스트립과 동일. 구형 사슴 4개 공격 셀 외 20셀 동일, PNG 576×384 유지.
- checkpoint v1·채택 캐릭터·제품 코드·tools·qa23 보존. ART-89 행 미변경. 패키지 설치/다운로드 없음. Godot·게임·모션 뷰어 실행 없음.

[commit.ps1](commit.ps1)은 **작성/구문 검사만 하며 실행하지 않는다**. [files-to-stage.txt](files-to-stage.txt)의 명시 목록만 `git add --pathspec-from-file`로 stage한다. 카드·프롬프트를 포함하고 raw/qa23/다른 유닛/시도별 덤프/run.log/캐시를 제외한다. `git add -f` 없음, 커밋 끝은 지정 공동 작성자 줄이다.

재검증: 지정 Python + `PYTHONDONTWRITEBYTECODE=1`로 `reports/codex-art-90/verify.py`. 로컬 입력 사본과 baseline이 필요하다. 배포 후 동일 상태 재현은 base commit과 [출처 해시](source-manifest.json), 최종 후보 및 [measurements.json](measurements.json)을 기준으로 한다. 사용 입력·생성 원본은 모두 `art/raw/art-90/`에 복사했고 git 대상에서는 제외했다.

다음 권장 단계: 리드가 수호자·사냥개·구형 사슴 후보를 모션 뷰어에서 검토하고, Nova 눈/얼굴 대응점의 가림 문제를 먼저 확정한다. 게임 채택/연결은 이 작업에 포함되지 않았다.
'''
 (P/'README.md').write_text(text,encoding='utf-8',newline='\n')
 # Explicit final evidence only. No baseline or full-frame exploratory head boards in the commit.
 names=['README.md','work.py','deliver.py','verify.py','package.py','prompts.txt','measurements.json','outputs.json','verification.json','source-manifest.json','hound-statistics.json','head-rechecks.json','guardian-size.json','visual-review.json','overview.png','hound-all-1x.png','commit.ps1','commit-message.txt','files-to-stage.txt']
 names += [p.name for p in P.glob('guardian-*-?x.png')]+[p.name for p in P.glob('hound-*-4x-*.png')]+[p.name for p in P.glob('stag-attack-?x-*.png')]
 names += ['luna-manual-landmarks-4x.png','nova_female-manual-landmarks-4x.png','nova_male-manual-landmarks-4x.png']
 names += [p.name for p in P.glob('*-automatic.json')]+[p.name for p in P.glob('*-faces-4x.png')]
 out=json.loads((P/'outputs.json').read_text('utf-8'))+['design/tasks/CODEX-ART-90.md','design/tasks/CODEX-ART-90.prompt.md']+['reports/codex-art-90/'+n for n in names]
 (P/'files-to-stage.txt').write_text('\n'.join(sorted(set(out)))+'\n',encoding='utf-8',newline='\n')
 (P/'commit-message.txt').write_text('ART-90: repair final monster candidates and recheck fighter faces\n\nRe-slice guardian margins, clean hound foliage speckles, restore four distinct legacy stag attacks. Preserve adopted fighter rows; document uncertain Nova face measurements.\n\nCo-Authored-By: Codex <noreply@openai.com>\n',encoding='utf-8',newline='\n')
 print('Packaged',len(set(out)),'explicit paths')
if __name__=='__main__':main()
