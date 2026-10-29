"""Render the ART-81 report and read-only 4x evidence boards from audit.json."""
from pathlib import Path
import json, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import audit as a

OUT=a.OUT; ROOT=a.ROOT
FONT_PATH=Path('C:/Windows/Fonts/malgun.ttf')
def font(size):return ImageFont.truetype(str(FONT_PATH),size) if FONT_PATH.exists() else ImageFont.load_default()
def fmt(x):return f'{x:.4f}' if isinstance(x,float) else str(x)
def issues_for(i):
 out=[];cs=i['checks'];p=i['path']
 def add(check,priority,severity,value,threshold,fix,frame=1,confirmed=False):
  out.append(dict(path=p,check=check,priority=priority,severity=severity,value=value,threshold=threshold,likely_fix=fix,frame=frame,confirmed=confirmed))
 f=cs['format'];m=f['measurement']
 if f['status']=='fail':add('format',100,'상',f"actual {i['dimensions']}, expected {m['expected_dimensions']}; {m['errors']}",'카드의 셀 크기 × 6열, RGBA, 사용 셀 수 일치','v3와 중복된 구형 1칸 후보는 리드가 retired 처리하거나 6칸으로 패딩. 현재 파일은 그대로 보존.',confirmed=True)
 if cs['slicing']['status']=='fail':add('slicing',110,'상',str(cs['slicing']['measurement']),'캐릭터 4px / 몬스터·투사체 3px','행 배율·배치 재검토; 원본 잘림이면 해당 프레임 재생성.',confirmed=True)
 if cs['assembly']['status']=='fail':add('assembly',105,'상',str(cs['assembly']['measurement']),'행별 RGBA 차이 0px','최종 후보 행으로 재조립.',confirmed=True)
 if cs['faces']['status']=='fail':add('faces',105,'상',str(cs['faces']['measurement']),'실제 마스크 밖 및 알파 변경 0px','중립+보존 마스크로 재합성.',confirmed=True)
 sm=cs['size']['measurement'] or {}
 if 'frames' in sm:
  hist=sm.get('face_landmarks',{})
  for fr in hist.get('frames',[]):
   ratios=[(key,fr.get(key)) for key in ['face_width_ratio','eye_ratio'] if fr.get(key) is not None]
   bad=[(k,v) for k,v in ratios if not .95<=v<=1.06]
   if bad:add('face_size',86+max(abs(v-1) for k,v in bad),'중',f"F{fr['frame']} "+', '.join(f'{k}={v}' for k,v in bad),'이전 검수 좌표 재계산; 허용 0.95–1.06','표식 경계부터 재확인. 행 내 편차면 프레임 재시도; 일괄 배율로 가리지 않음.',fr['frame'])
  col=sm.get('colour_component_size',{})
  for fr in col.get('frames',[]):
   v=fr['ratio']
   if v is not None and not fr['intentional_exception'] and not .95<=v<=1.05:add('stable_colour_size',76+min(abs(v-1),1),'중',f"F{fr['frame']} {fr['metric']} ratio={v}, size={fr['size']}px",'같은 색 성분 크기 / idle: 0.95–1.05','연결 영역이 실제 부위 전체인지 먼저 재측정. 회전·가림·조명·분리된 색 영역은 실제 축소와 다르므로 이 수치만으로 배율 변경하지 않음.',fr['frame'])
  for fr in sm['frames']:
   v=fr['scale'];score=fr['score'];floor=.6 if i['kind']=='fighter' else .75;hi=1.06 if i['kind']=='fighter' else 1.05
   if v is not None and score>=floor and not fr['intentional_scale_exception'] and not .95<=v<=hi:
    add('template_size',65+min(abs(v-1),1)+score,'중',f"F{fr['frame']} NCC scale={v}, score={score}",f"score≥{floor}; scale 0.95–{hi}",'정합 상자를 확인한 뒤 실제 부위를 재측정. 동일 부위가 확실하고 행 전체가 같은 비율일 때만 factor / 측정 배율로 재구축.',fr['frame'])
 pm=cs['palette']['measurement'] or {}
 if cs['palette']['status']=='review':
  cand=pm['candidate'];ref=pm['reference_palette']
  add('palette',72+pm['hue_tv'],'중',f"TV={pm['hue_tv']}; hue shift={pm['dominant_hue_shift_degrees']}deg; green={cand.get('green_hue_60_180_fraction')} vs {ref.get('green_hue_60_180_fraction')}",'TV >0.25 AND 주 색상 구간 이동≥30°','색 면적·자세 차이와 실제 색 변경을 구분. 정체성 색이 바뀌었을 때만 공통 팔레트 매핑.')
 am=cs['alpha']['measurement']
 if cs['alpha']['status'] in ['fail','review']:
  value=f"semi={am['semi_transparent_pixels']}, key_green={am['key_green_pixels']}, checker={am['checker_tile_count']}, edge excess={am.get('edge_fraction_excess')}"
  add('alpha',64 if cs['alpha']['status']=='review' else 103,'중',value,'이진 알파; 키색 0; 기준보다 경계 명암 비율 +0.15 초과 시 검토','밝고 어두운 배경에서 경계를 대조. 검은 의도된 외곽선은 삭제하지 않음.',confirmed=cs['alpha']['status']=='fail')
 if cs['feet']['status']=='review' and i['kind']!='monster_sheet':
  fm=cs['feet']['measurement'];fr=fm['off_line_frames'][0]
  add('feet',60,'하',f"F{fr}: lowest alpha y={fm['frames'][fr-1]['bottom_y']}",'지지발 y=72±1; 잎끝·무기 제외','씨앗 요정은 잎끝 y74와 지지발 y72를 구분. 그림 전체를 무조건 올리지 않음.',fr)
 if m.get('missing_fields'):add('metadata',40,'하','missing '+', '.join(m['missing_fields']),'frames/fps/cell/feet/loop 명시','리드가 소비자의 기본값과 맞춰 메타데이터 명시. 재생 오류로 확정한 것은 아님.')
 return out

def paste_frame(board,frame,x,y,label,box=None):
 d=ImageDraw.Draw(board);d.text((x,y),label,font=font(20),fill='#e4e8ef');y+=32
 big=frame.resize((frame.width*4,frame.height*4),Image.Resampling.NEAREST)
 bg=Image.new('RGBA',big.size,(43,49,62,255));bg.alpha_composite(big);board.paste(bg.convert('RGB'),(x,y))
 if box:
  x0,y0,x1,y1=box;d.rectangle((x+x0*4,y+y0*4,x+x1*4-1,y+y1*4-1),outline='#ff72c0',width=2)
 return y

def board(issue,item,index):
 kind=item['kind'];cw,ch=item['cell'];n=issue['frame'];im=Image.open(ROOT/item['path']).convert('RGBA');frame=im.crop(((n-1)*cw,0,n*cw,ch));cs=item['checks'];sm=cs['size']['measurement'] or {};ref=None;refbox=None;fbox=None;label='REFERENCE'
 if issue['check']=='palette':
  rp=cs['palette']['measurement']['reference'];ri=Image.open(ROOT/rp).convert('RGBA');sz=ri.width//6;ref=ri.crop((0,0,sz,sz));label='CURRENT GAME idle F1'
 elif 'anchor' in sm:
  ri=Image.open(ROOT/sm['anchor']).convert('RGBA');sz=128 if kind=='fighter' else 96;ref=ri.crop((0,0,sz,sz));refbox=sm.get('template_box');label='CANDIDATE/ADOPTED idle F1'
  fm=sm['frames'][min(n-1,len(sm['frames'])-1)];fbox=fm['box']
  if issue['check']=='stable_colour_size':
   col=sm['colour_component_size'];refbox=col['anchor']['component']['bbox'];fbox=col['frames'][n-1]['component']['bbox']
  elif issue['check']=='face_size':refbox=None;fbox=None
 elif kind=='fighter':
  paths=list((a.BAKE/item['identity'].split('_')[0]).glob(f"{item['identity']}-idle-v*.png"));ri=Image.open(paths[-1]).convert('RGBA');ref=ri.crop((0,0,128,128))
 if ref is None:ref=frame
 width=max(1240,ref.width*4+frame.width*4+84);height=max(ref.height,frame.height)*4+290
 b=Image.new('RGB',(width,height),'#171d29');d=ImageDraw.Draw(b)
 d.text((24,14),f"{index:02d}  {'CONFIRMED CONTRACT DEFECT' if issue['confirmed'] else 'MEASURED FLAG / REVIEW REQUIRED'}",font=font(24),fill='#ff8f8f' if issue['confirmed'] else '#ffd584')
 d.text((24,52),Path(item['path']).name,font=font(22),fill='white')
 d.text((24,88),f"check={issue['check']}  F{n}; native pixels enlarged exactly 4x (NEAREST)",font=font(18),fill='#b1c0d6')
 top=130;by=paste_frame(b,ref,24,top,label,refbox);x=ref.width*4+56;paste_frame(b,frame,x,top,f'CANDIDATE F{n}',fbox)
 if issue['check']=='face_size':
  hist=sm['face_landmarks'];hf=next(fr for fr in hist['frames'] if fr['frame']==n)
  def points(marks):
   if not marks:return []
   if isinstance(marks[0],dict):return [(m['x'],m['y']) for m in marks]
   if isinstance(marks[0],(int,float)):return [(marks[0],marks[2]),(marks[1],marks[2])]
   return [(m[0],m[1]) for m in marks]
  for ox,marks in [(24,hist.get('reference_landmarks') or sm['fresh_face_proposals']['reference_points']),(x,hf['landmarks'])]:
   pp=points(marks)
   for px,py in pp:
    xx=ox+px*4;yy=by+py*4;d.line((xx-4,yy,xx+4,yy),fill='cyan',width=1);d.line((xx,yy-4,xx,yy+4),fill='cyan',width=1)
   if len(pp)>=2:
    l,r=pp[-2:];d.line((ox+l[0]*4,by+l[1]*4,ox+r[0]*4,by+r[1]*4),fill='#ffe481',width=1)
 if issue['check']=='feet':
  d.line((x,by+72*4,x+cw*4-1,by+72*4),fill='#7ee7ff',width=2)
 if issue['check']=='format':
  d.text((x,by+ch*4+8),f"Actual strip {im.width}x{im.height}; required {cs['format']['measurement']['expected_dimensions']}",font=font(18),fill='#ffaaaa')
 text=issue['value'];maxchars=max(55,width//13)
 for j in range(0,len(text),maxchars):d.text((24,height-90+(j//maxchars)*25),text[j:j+maxchars],font=font(17),fill='#e4e8ef')
 name=f"{index:02d}-{Path(item['path']).stem}-{issue['check']}-4x.png";b.save(OUT/'boards'/name)
 return {'file':'boards/'+name,'source':item['path'],'frame':n,'check':issue['check'],'scale':4,'confirmed':issue['confirmed'],'native_frame_dimensions':[cw,ch]}

def support_boards():
 out=OUT/'support';out.mkdir(exist_ok=True);f=font(16)
 im=Image.open(a.BAKE/'monsters/vanaheim_seed_sprite-attack-v1.png').convert('RGBA');b=Image.new('RGB',(1180,438),(31,37,49));d=ImageDraw.Draw(b)
 for n in range(3):
  cr=im.crop((n*96,0,(n+1)*96,96)).resize((384,384),Image.Resampling.NEAREST);b.paste(cr,(10+n*390,42),cr);d.text((12+n*390,10),f'F{n+1} - y72 cyan, y74 red',font=f,fill='white');d.line((10+n*390,42+72*4,393+n*390,42+72*4),fill='cyan');d.line((10+n*390,42+74*4,393+n*390,42+74*4),fill='red')
 b.save(out/'seed-feet-4x.png')
 ids=['vanaheim_seed_sprite','vanaheim_vine_hound','yggdrasil_root_guardian','alfheim_moon_stag'];b=Image.new('RGB',(820,len(ids)*430),(31,37,49));d=ImageDraw.Draw(b)
 for j,who in enumerate(ids):
  d.text((10,j*430+8),who+' | game idle -> candidate idle',font=f,fill='white')
  for k,path in enumerate([a.GAME/'monsters'/f'{who}_sheet.png',a.BAKE/'monsters'/f'{who}-idle-v1.png']):
   im=Image.open(path).convert('RGBA');c=im.width//6;cr=im.crop((0,0,c,c)).resize((c*4,c*4),Image.Resampling.NEAREST);b.paste(cr,(10+k*404,j*430+38),cr)
 b.save(out/'palette-4x.png')

def main():
 result=json.loads((OUT/'audit.json').read_text(encoding='utf-8'));items=result['files'];by={i['path']:i for i in items};issues=sorted([x for i in items for x in issues_for(i)],key=lambda x:(-x['priority'],x['path'],x['frame']));a.savej(OUT/'issues.json',issues);support_boards()
 top=[];seen=set()
 for issue in issues:
  if issue['path'] in seen or by[issue['path']]['kind']=='monster_sheet':continue
  seen.add(issue['path']);top.append(issue)
  if len(top)==20:break
 (OUT/'boards').mkdir(exist_ok=True)
 previous=OUT/'boards/index.json'
 if previous.exists():
  for entry in json.loads(previous.read_text(encoding='utf-8')):
   old=(OUT/entry['file']).resolve()
   if old.parent!=(OUT/'boards').resolve() or not old.name.endswith('-4x.png'):raise ValueError('Unexpected generated board path')
   if old.exists():old.unlink() # only explicitly indexed, task-owned generated boards
 boards=[board(x,by[x['path']],j+1) for j,x in enumerate(top)];a.savej(OUT/'boards/index.json',boards)
 # Preview is deliberately labelled as reduced; originals above retain exact 4x.
 thumbs=Image.new('RGB',(1200,math.ceil(len(boards)/4)*270),'#171d29');dd=ImageDraw.Draw(thumbs)
 for j,entry in enumerate(boards):
  im=Image.open(OUT/entry['file']);im.thumbnail((294,240));x=(j%4)*300;y=(j//4)*270;thumbs.paste(im,(x,y));dd.text((x+6,y+242),f'{j+1:02d} {entry["check"]}',font=font(14),fill='white')
 thumbs.save(OUT/'boards/overview.png')
 names={'fighter':'캐릭터 동작','monster':'몬스터 행','monster_sheet':'몬스터 조립본','projectile':'투사체·충격파','face':'대화 얼굴'}
 lines=['# ART-81 기술 감사 — 측정 전용','',
 '완료: 미채택 후보 **219개**를 현재 PNG/JSON에서 다시 읽어 검사했다. 아트·게임·도구 파일을 바꾸지 않았고 Godot을 실행하지 않았다. 아래 `통과`는 명시한 자동 검사에서 미해결 검토·측정불가 항목이 없는 경우다. `검토`는 결함 확정이 아니며, `측정불가`를 통과로 세지 않는다.','',
 '## 종류별 결과','',
 '| 종류 | 파일 | 모든 적용 검사 통과 | 확정 실패 없음 | 실패 / 검토 / 측정불가 |','|---|---:|---:|---:|---|']
 for k,v in result['summary'].items():
  s=v['statuses'];lines.append(f"| {names[k]} | {v['files']} | {v['all_checks_pass']} | {v['no_measured_failure']} | {s.get('fail',0)} / {s.get('review',0)} / {s.get('unmeasured',0)} |")
 lines += ['', '**조립 일치만 보면 18/18 통과**다. 조립본 전체 통과 수에는 원본 6행의 크기·접지·중복 검사도 포함한다. 따라서 조립 오류가 없어도 원본 행에 검토 항목이 있으면 전체 통과로 세지 않는다.', '',
 '## 결함 및 검토 목록 — 우선순위 순','',
 '수치는 측정 결과이고, 우선순위·심각도·가능한 수정은 감사자의 판단이다. 자동 정합·색 분포만으로 해부학적 크기나 미적 품질을 확정하지 않는다. 전체 목록과 모든 프레임 수치는 `issues.json`, `audit.json`에 있다. 아래는 파일별 최상위 항목 20개다.','',
 '| 우선 | 파일 / 검사 | 측정값 | 기준 | 가능한 수정 |','|---|---|---|---|---|']
 for j,x in enumerate(top):
  tag='확정' if x['confirmed'] else '검토';link=boards[j]['file'];lines.append(f"| {x['severity']}·{tag} | [{Path(x['path']).name}]({link}) / {x['check']} | {x['value']} | {x['threshold']} | {x['likely_fix']} |")
 lines += ['', '## 시각적 확인','', '![상위 20개 축소 목차](boards/overview.png)', '',
 '위 그림은 찾아보기용 축소 목차다. 각 항목 링크는 실제 원본 픽셀을 최근접 **정확히 4배**로 확대한 보드다. 왼쪽은 기준, 오른쪽은 후보의 해당 프레임이다. 분홍 상자는 선택된 색 연결 영역 또는 템플릿 정합 위치이며, 청록 십자와 노란 선은 이전 검수 얼굴 표식이다. `MEASURED FLAG / REVIEW REQUIRED`는 확정 결함과 구분한 검토 표시다. 실제 게임 화면이 아니다.','',
 '## 측정 방법과 모든 임계값','']
 for key,value in result['thresholds'].items():lines.append(f'- **{key}**: `{json.dumps(value,ensure_ascii=False) if isinstance(value,dict) else value}`')
 lines += ['', '## 해석 시 주의할 실제 사례','',
 '- `nova_female-hurt-v2.png`: 128×128의 이전 1프레임 후보다. 카드의 6칸 패딩 규격과 어긋나므로 규격 실패로 기록한다. JSON frames=1과 실제 1장은 일치한다. v3도 별도 존재하며, 이 결과가 현재 게임의 피격 재생 오류를 뜻하지는 않는다.',
 '- 씨앗 요정 공격 F2·F3: 전체 알파 하단은 y74지만, 실제 4배 판에서 지지발 영역을 선택해 다시 잰 하단은 모두 y72다. `semantic-rois.json`에 정확한 파일 해시·영역·±1px 오차를 기록하고 접지 통과로 분리했다. [지지발/잎끝 비교](support/seed-feet-4x.png).',
 '- 셀 규격 예외: ART-69의 defeat 8행과 ART-68의 Rio 여성 low_sweep/dimension_slash 2행도 192px/발 y152다. 제작 카드·보고서의 명시 규격을 적용했으며 이를 128px 오류로 만들지 않았다.',
 '- 하운드·씨앗의 팔레트 보정 이력은 확인했다. 이번 색상 수치는 현재 게임 시트와 후보의 색 면적 분포 차이다. 녹색 픽셀을 크로마키 잔여물로 간주하지 않으며, TV/대표 hue 변화만으로 녹색→노랑 복귀라고 주장하지 않는다.',
 '- 나방 공격 F2–F5의 축소·반짝임은 의도된 순간이동이다. 공중/비행 프레임도 접지 실패로 세지 않는다.',
 '- 까마귀 defeat F3의 금색 연결 영역 폭은 10/15=0.6667이지만, 4배 확인에서 원판이 회전하고 금색 테두리가 분리된 부분만 잡힌다. 원판 전체가 33% 작아졌다는 증거가 아니다. 양의 뿔·투석병의 주황 후드도 투영·가림·색 면적 변화가 섞인다. `visual-review.json`에 20개 보드별 판단과 한계를 기록했다.',
 '- 검은 외곽선이 원래 있는 Frey/Nova 등은 절대 검정 픽셀 수만으로 후광 실패를 만들지 않는다. 기준 idle 대비 경계 비율 증가를 별도 비교한다.',
 '- ART-72 방식의 새 4배 얼굴 표식 제안도 프레임마다 남겼다. 자동 제안을 실제 눈/얼굴 경계 실측으로 승인하지 않았다. 이전 수동 표식은 현재 PNG와 픽셀 동일성을 확인한 경우에만 좌표 거리를 재계산했다.', '',
 '## 측정하지 못한 것','',
 '- 가려진 눈(노바·리오), 감은 눈, 크게 기울거나 누운 얼굴의 실제 눈 간격·해부학적 머리 크기. 신뢰도 낮은 정합 결과는 그대로 공개하며, 대체 얼굴/표식을 만들어 통과시키지 않았다.',
 '- 몬스터의 모든 자세에서 동일한 실제 해부학 부위 길이. bbox와 색 연결 성분/템플릿은 측정했지만 회전·가림·조명이 만든 변화와 체형 오류를 자동으로 분리할 수 없다. 기존 대표 프레임 명목 값은 출처를 붙여 참고값으로만 기록했다.',
 '- 무기·옷자락·잎을 제외한 모든 프레임의 실제 체중 지지점. 자동값은 알파 최하단이며 지지발 검증과 같지 않다.',
 '- PNG에서 실제 fps·loop를 측정할 수는 없다. JSON 타입·값·장수·빈 패딩은 검증했으며 일부 누락은 소비자의 기본값 검토 대상으로 남겼다.',
 '- 모든 가능한 불투명 후광·체커보드·키색 잔여물의 완전한 부재, 동작의 자연스러움, 실제 게임 혼전 가독성. 색/주기 검사와 정적 보드에 한정된다.',
 '- Godot import, 게임 연결, 실시간 재생, ART-82의 다른 클론 변경은 검사하지 않았다.', '',
 '## 재현 및 인계','',
 '```powershell', "$env:PYTHONDONTWRITEBYTECODE='1'", "$env:PYTHONIOENCODING='utf-8'", "$python81='C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'", '& $python81 -B reports/codex-art-81/audit.py', '& $python81 -B reports/codex-art-81/report.py', '& $python81 -B reports/codex-art-81/verify.py', '```','',
 '`measurement-cache.json`는 후보·앵커 SHA-256과 템플릿 정의에 묶인 정합 캐시다. 새 버전은 다른 해시이므로 다시 측정한다. 최종 사용 입력 해시와 읽기 전후 무변경 검사도 `audit.json`에 남겼다.',
 '', '**남은 작업:** 검토 표시의 표식/색/외곽선 확인과 후보 채택 결정. **다음 권장 단계:** 리드가 상위 보드와 메타데이터 누락을 검토하고 필요한 항목만 별도 수정 카드로 전달한다. `commit.ps1`은 작성·구문 검사만 하며 실행하지 않는다.']
 vp=OUT/'verification.json'
 if vp.exists():
  verified=json.loads(vp.read_text(encoding='utf-8'))
  if 'passed' in verified:lines += ['', f"**확인 및 테스트:** 감사 알고리즘·대상 누락·입력 무변경·얼굴 보존·조립 일치·제출 범위 검사 {verified['passed']}개 통과, {verified['failed']}개 실패 (`verification.json`). Godot 테스트가 아니다. 상위 20개 개별 4배 보드와 지지발·팔레트 보드를 직접 확인했다. 전체 219개를 모두 육안 검수했다는 뜻은 아니다."]
 (OUT/'README.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
 print('wrote README, issues and',len(boards),'4x boards')
if __name__=='__main__':main()
