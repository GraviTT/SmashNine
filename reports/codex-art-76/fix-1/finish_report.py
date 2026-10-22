"""Create Korean handoff, measured reach evidence and an explicit delivery list."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, math
from pathlib import Path
from PIL import Image, ImageDraw
import rebuild as r

NAMES=dict(zip(r.IDS,['마그마 멧돼지','빙하 늑대','서리 올빼미','폭풍 위습','뿌리 수호자','뿌리 예언자']))
NOTES={
 r.IDS[0]:dict(idle='6장 모두 확인. 갑각과 용암 선은 남지만, 8.16% 축소로 더 촘촘해 보임.',
 walk='6장 모두 확인. 발 교대와 y72는 유지. 보폭과 다리 분리가 약함.',
 windup='4장 모두 확인. 머리 낮춤·뒤로 당김은 보이나 땅 긁기가 약함.',
 attack='6장 모두 확인. F3 전체 그림을 앞으로 옮겼음. 엄니 리치는 늘었으나 돌진 보폭 자체는 그대로임.',
 hurt='2장 모두 확인. 위로 젖힘과 복귀가 보이고 접지 유지.',
 defeat='4장 모두 확인. 몸을 낮추는 순서는 유지. 마지막 넓적다리 투영 폭은 첫 그림보다 큼.'),
 r.IDS[1]:dict(walk='6장 모두 확인. 다리 교대와 접지 유지.',
 attack='6장 모두 확인. F3 전진이 커짐. F4가 가장 높고 다음 F5에서 급히 착지하는 기존 호는 남음.'),
 r.IDS[2]:dict(walk='6장 모두 확인. 처음/끝 두개부 폭의 차이를 줄이는 절충 배율. 발 고정 날갯짓은 그대로.',
 attack='6장 모두 확인. 머리가 idle에 가까워짐. 내려치기보다 앞으로 손짓하는 동작에 가까움.',
 hurt='2장 모두 확인. 반동과 복귀가 보임. 첫/둘째 그림의 두개부 투영 차이는 남음.'),
 r.IDS[3]:dict(attack='6장 모두 확인. 돌의 명목 크기는 개선. F3 핵 발광 영역이 커지는 변화는 그대로.'),
 r.IDS[4]:dict(idle='6장 모두 확인. 긴 자세를 y72 안에 넣으려고 기준을 4% 축소. 가지와 주먹 두 개 유지.',
 walk='6장 모두 확인. 주먹과 몸 크기가 기준에 가까워짐. 먼 다리 가림은 남음.',
 windup='4장 모두 확인. 두 주먹만 있음. 머리 위로 든 주먹의 투영 폭 감소는 배율로 해결 안 됨.',
 attack='6장 모두 확인. F1 상단 3px와 발 y72 모두 확보. 두 주먹 내리침은 유지.',
 hurt='2장 모두 확인. 반동과 접지는 유지. 가지/봉오리 수·배치의 변화는 남음.',
 defeat='4장 모두 확인. F1 상단 여백과 y72 유지. 마지막 주먹이 작아지는 가림/회전은 남음.'),
 r.IDS[5]:dict(windup='4장 모두 확인. 눈 기준으로 전체 이동. 머리는 커졌고 발광 눈 정렬 유지. 촉수 끝이 꽃봉오리처럼 보임.')
}

def point3():
    original=r.load_json(r.REPORT/'manual_motion.json')['reach']
    data={
      r.IDS[0]:dict(part='앞 엄니의 가장 오른쪽 불투명 외곽',before=[[85,64],[87,59]],after=[[84,64],[92,59]]),
      r.IDS[1]:dict(part='앞으로 뻗는 앞발의 끝 불투명 외곽',before=[[68,72],[88,50]],after=[[68,72],[92,50]])}
    for mid,item in data.items():
        item['reported_before_dx']=original[mid]['after'][0]-original[mid]['before'][0]
        item['remeasured_before_dx']=item['before'][1][0]-item['before'][0][0]
        item['measured_after_dx']=item['after'][1][0]-item['after'][0][0]
        item['uncertainty_px']=2
        item['method']='4배 격자에서 windup F4와 attack F3의 같은 공격 부위 외곽을 재지정. 가로 차이. 두 지점 모두 불투명 픽셀인지 검증. 실제 게임 이동량/판정 사거리 아님.'
        item['reported_start_alpha']=r.frames(r.FIX/'before'/f'{mid}-windup-v1.png','windup')[3].getpixel(tuple(original[mid]['before']))[3]
        for phase,folder in [('before',r.FIX/'before'),('after',r.BAKE)]:
            for (row,idx),point in zip([('windup',3),('attack',2)],item[phase]):
                assert r.frames(folder/f'{mid}-{row}-v1.png',row)[idx].getpixel(tuple(point))[3]==255
        panel=Image.new('RGB',(860,962),(22,27,39));d=ImageDraw.Draw(panel)
        d.text((10,3),f'{mid} | opaque contour landmarks | exact 4x',font=r.n.font(17),fill='white')
        for pi,(phase,folder) in enumerate([('before',r.FIX/'before'),('after',r.BAKE)]):
            dx=item['remeasured_before_dx' if pi==0 else 'measured_after_dx']
            for col,(row,idx) in enumerate([('windup',3),('attack',2)]):
                im=r.frames(folder/f'{mid}-{row}-v1.png',row)[idx]
                tile=r.cell_tile(im);td=ImageDraw.Draw(tile)
                pt=item[phase][col];x,y=pt[0]*4,pt[1]*4
                td.line((x,0,x,384),fill=(255,220,70),width=1)
                td.ellipse((x-6,y-6,x+6,y+6),outline='white',width=2)
                panel.paste(tile,(40+col*420,70+pi*442))
                d.text((40+col*420,38+pi*442),f'{phase} {row} F{idx+1} {tuple(pt)} | dx {dx}px',font=r.n.font(16),fill='white')
                if mid==r.IDS[1] and pi==0 and col==0:
                    ox,oy=original[mid]['before'];xx=40+ox*4;yy=70+oy*4
                    d.line((xx-7,yy-7,xx+7,yy+7),fill=(255,80,100),width=3)
                    d.line((xx-7,yy+7,xx+7,yy-7),fill=(255,80,100),width=3)
                    d.text((40,460),'Red X: old (82,71) is transparent; 5px was not a valid paw measure.',font=r.n.font(13),fill=(255,150,155))
        panel.save(r.FIX/f'{mid}-reach-before-after-4x.png')
    r.dump(r.FIX/'point-3.json',data)
    return data

def remaining_samples(config):
    out=[]
    for mid in r.IDS:
        b_idle=sum(r.ruler_length(p) for p in r.LANDMARKS[mid]['idle'])/2
        idle_scale=config['factors'][mid][0]/r.load_json(r.FIX/'before'/f'{mid}-idle-v1.json')['factor']
        for row in r.ROWS:
            oldf=r.load_json(r.FIX/'before'/f'{mid}-{row}-v1.json')['factor']
            scale=config['factors'][mid][r.ROWS.index(row)]/oldf
            for k,points in enumerate(r.LANDMARKS[mid][row]):
                length=r.ruler_length(points);ratio=length*scale/(b_idle*idle_scale)
                if not .95<=ratio<=1.05:
                    out.append(dict(monster=mid,row=row,frame=1 if k==0 else r.COUNTS[row],
                                    before_ratio=length/b_idle,after_ratio=ratio,
                                    meaning='기존 첫/끝 눈금을 공통 배율로 추적. 자세·원근·가림과 실제 크기 흔들림을 분리할 수 없음.'))
    r.dump(r.FIX/'nonrepresentative-samples.json',out)
    return out

def main():
    sizes=r.load_json(r.FIX/'sizes.json');v=r.load_json(r.FIX/'verification.json');config=r.load_json(r.FIX/'config.json')
    assert not v['failures']
    p3=point3();outside=remaining_samples(config)
    visual=[]
    for item in v['changed_rows']:
        mid,row=item['monster'],item['row']
        visual.append(dict(monster=mid,row=row,frames=list(range(1,r.COUNTS[row]+1)),scale=4,
            image=f'{mid}-{row}-all-frames-4x.png',candidate_sha256=r.sha(r.BAKE/f'{mid}-{row}-v1.png'),
            judgement=NOTES[mid][row],review='직접 이미지 열람 완료; 정적 그림 검수이며 반복 재생 평가는 아님'))
    r.dump(r.FIX/'visual-review.json',visual)
    # Source-trace coordinates are estimates from existing manual output rulers,
    # not newly claimed native-resolution anatomical measurements.
    for item in sizes:
        mid,row=item['monster'],item['row'];idx=item['frame']-1
        sb=r.source(mid,row)[idx].getbbox();ob=r.frames(r.FIX/'before'/f'{mid}-{row}-v1.png',row)[idx].getbbox()
        item['source_points_estimated']=[[sb[j]+(pt[j]-ob[j])/item['factor_before'] for j in [0,1]] for pt in item['before_points']]
        item['after_measurement_method']='기존 수동 눈금을 raw 공통 배율 및 전체 평행이동으로 추적한 명목 투영 길이. 독립적인 해부학적 재측정값 아님. 최종 4배 그림에서 같은 부위인지 확인. 끝점 약 ±1px, 길이 약 ±2px.'
    r.dump(r.FIX/'sizes.json',sizes)
    changed={(d['monster'],d['row']) for d in v['changed_rows']}
    body=['# CODEX-ART-76 fix-1 — batch 3 행별 크기 재정리','',
      '## 작업 결과','',
      '**완료:** 6종 중 19행(92프레임)의 PNG/JSON과 조립 시트 6장을 갱신했다. raw에서 행 공통 factor 하나로 재구축했으며, ART-74와 같은 대표 부위 기준으로 36행 모두 idle 대비 명목 ±5% 안이다. 미착수 행·누락 raw는 없다. 후보 단계이며 게임 적용은 하지 않았다.','',
      '**현재 상태:** 168프레임 규격 검사 실패 0, 디테일 85 미만 0. 변경한 19행의 모든 그림을 정확한 최근접 4배로 직접 열어 확인했다. 프레임별 배율·몸 조각 교체·색 보정은 하지 않았다.','',
      '**남은 작업:** 대표 부위의 행별 명목 크기를 맞춘 결과다. 회전·가림·프레임 안의 그림 변형까지 전부 ±5%가 된 것은 아니다. 아래 별도 표에 남은 첫/끝 투영 편차를 공개한다.','',
      '## 측정 방법과 배율 선택','',
      '- 비교 부위는 ART-76의 수동 4배 눈금을 재사용했다. 보통 F1, 피격은 반동이 덜한 F2, 늑대 공격은 공중 자세 대신 착지 F6을 대표로 삼았다(ART-74와 같은 비교 조건 선택). idle 기준은 이전 보고와 동일한 첫/마지막 그림 길이 평균이다.','- **전 크기**는 기존 수동 눈금의 투영 길이, **후 크기**는 그 동일 눈금을 raw 공통 배율과 프레임 전체 이동으로 추적한 명목 길이다. 독립적인 해부학적 재측정값으로 주장하지 않는다. 최종 4배 그림에서 부위·외곽·접지를 대조했다. 끝점 오차 약 ±1px, 길이 약 ±2px이므로 소수점 표시는 재현용 계산 정밀도다.','- 멧돼지 idle .19→.1745(−8.16%), 수호자 idle .15→.144(−4%)로 기준을 줄였다. 큰 준비/내리침을 96px 칸, 3px 여백, 발 y72와 함께 유지하려는 선택이다. 올빼미 이동·피격은 첫/끝 두개부 편차를 덜 키우도록 중간 배율로 절충했다.','- 수정된 행은 원본을 LANCZOS, 선명화60, despill auto, palette none으로 재축소했다. 256px 작업 캔버스에서 만든 모든 불투명 픽셀을 보존하고 전체 그림만 96px 칸으로 평행 이동했다. 결과 PNG가 같은 raw 재구축과 픽셀 단위로 일치함을 검증했다.','',
      '## 크기 표 — 측정/추적값','']
    for mid in r.IDS:
        subset=[d for d in sizes if d['monster']==mid]
        body += [f'### {NAMES[mid]} — `{mid}`','',f"비교 부위: {r.LANDMARKS[mid]['part']}. idle 평균 {subset[0]['idle_reference_before_px']:.2f} → {subset[0]['idle_reference_after_px']:.2f}px.",'',
          '| 행(대표 F) | 변경 | 전 크기 px | 후 추적 px | 전/idle → 후/idle | factor 전 → 후 |',
          '|---|---|---:|---:|---|---|']
        for d in subset:
            row=d['row'];mark='수정' if (mid,row) in changed else '유지'
            body.append(f"| {row}({d['frame']}) | {mark} | {d['before_px']:.2f} | {d['after_px']:.2f} | {d['ratio_before']:.3f} → {d['ratio_after']:.3f} | {d['factor_before']:g} → {d['factor_after']:g} |")
        body += ['',f'![{NAMES[mid]} 행별 크기 전후 4배]({mid}-size-before-after-4x.png)','',
          '각 3칸 묶음에서 위는 수정 전, 아래는 수정 후다. 노란 선은 동일 부위 추적 눈금, 분홍 선은 y72다.','']
    body += ['## 카드 3번 — 디테일과 공격 전진','',
      '| 항목 | 기존 보고 | 동일 부위 재측정/수정 후 | 해석 |','|---|---|---|---|',
      '| 멧돼지 idle 디테일 | F2 84.03 / F5 84.74 / F6 84.40 | **6장 모두 85.07 이상** | raw 공통 factor .1745로 개선. 별도 선명화 변경 없음 |',
      '| 멧돼지 엄니 전진 | 3px | 기존 불투명 외곽 **2px → 8px** | 준비 전체 그림을 뒤로, F3을 앞으로 이동. 오차 약 ±2px인 경계값 |',
      '| 늑대 앞발 전진 | 5px | 기존 **20px → 24px** | 기존 준비점 (82,71)은 알파0: 앞발 지점이 아니었음. 원래부터 목표8px 충족 |','',
      '새 전진 측정은 실제 불투명 외곽을 다시 지정했다. 멧돼지: 준비/공격 (85,64)→(87,59)가 수정 후 (84,64)→(92,59). 늑대: (68,72)→(88,50)가 수정 후 (68,72)→(92,50). 지정점 8개 모두 알파255인지 검사했다. 그림의 가로 차이이며 게임 이동량·공격 판정 사거리가 아니다.','',
      '![멧돼지 엄니 전진 전후](muspelheim_magma_boar-reach-before-after-4x.png)','',
      '위는 원래 후보의 2px, 아래는 재구축 후보의 8px이다. 흰 원은 실제 불투명 엄니 외곽이고 노란 세로선은 각 x 좌표다.','',
      '![늑대 앞발 재측정과 전후](niflheim_glacier_wolf-reach-before-after-4x.png)','',
      '빨간 X는 기존 보고의 잘못된 투명 좌표다. 흰 원으로 같은 앞발 끝을 비교하면 원래20px, 수정 후24px이다. 5→24px 개선으로 보고하지 않는다.','',
      '## 시각 판단 — 숫자와 별개','',
      '- 멧돼지: y72와 디테일은 유지했지만 보폭·다리 분리·땅 긁기가 약하다. 8px은 위치 이동으로 만든 전진이며 새 공격 자세를 그린 결과가 아니다.','- 늑대: 72/67/62/53/72/72 도약 하단을 보존했다. F4의 늦은 정점과 F5의 빠른 착지가 남는다.','- 올빼미: 발이 고정된 날갯짓, 손짓에 가까운 공격은 그대로다. 두개부 원근 차이가 남는다.','- 위습: 핵 색 영역은 크기 기준으로 쓰지 않았다. 공격 F3의 과한 발광 면적과 대기/이동/피격 구분이 약한 점은 남는다.','- 수호자: 두 주먹은 유지되지만 준비와 쓰러짐의 회전/가림 때문에 주먹 투영 폭이 크게 줄어든다. 가지·봉오리 배치 흔들림도 남는다.','- 예언자: 촉수 개수·굵기 변화, 꽃봉오리처럼 보이는 시전 끝이 남는다. 눈 기준 정렬이며 뿌리 하단을 지지발로 보지 않았다.','',
      '### 대표 프레임 이외에 남은 투영 편차','',
      '다음 값은 기존 첫/끝 눈금을 동일 factor로 추적했을 때 ±5% 밖이다. 자세가 다르면 투영 길이가 달라진다는 한계와 실제 그림 흔들림이 섞여 있다. 이 목록을 숨기고 전 프레임 크기 일치라고 주장하지 않는다. 행 공통 factor만 바꿔서는 모두 동시에 맞출 수 없는 경우가 있다.','',
      '| 몬스터 | 행/프레임 | 전/idle → 후/idle |','|---|---|---|']
    for d in outside:body.append(f"| {NAMES[d['monster']]} | {d['row']} F{d['frame']} | {d['before_ratio']:.3f} → {d['after_ratio']:.3f} |")
    body += ['', '## 4배 전 프레임 검수 기록','',
      '| 몬스터 | 변경 행 | 직접 본 그림 | 판단 |','|---|---|---|---|']
    for d in visual:
        body.append(f"| {NAMES[d['monster']]} | {d['row']} | [F1–F{len(d['frames'])}, 4배]({d['image']}) | {d['judgement']} |")
    body += ['', '## 확인 및 테스트','',
      '- `verify.py`: 6종·36행·168프레임, 실패0. 최소 여백3px, 알파0/255, 초록 번짐0, 빈 칸 투명, 동일 행 중복 프레임0, 조립 시트와 행 PNG 픽셀 일치.','- 수정한 19행·92프레임: raw 공통 factor 재구축과 최종 PNG 픽셀 일치. 전체 그림 이동 전후 불투명 픽셀 수 보존. 지상형 y72와 늑대 도약 하단 보존.','- 디테일: 168프레임 모두85 이상. 내부 명암 라플라시안 지표이며 시각 완성도 인증은 아니다.','- 제품/도구 추적 파일 1,787개와 raw56장의 SHA-256, git index 해시가 작업 전과 같다. 추가 생성·설치·다운로드·Godot·뷰어 빌드·외부 게시는 실행하지 않았다.','- `commit.ps1`은 작성만 했고 실행·스테이징·커밋하지 않았다. 기존 `run.log` 등 미추적 파일은 보존하고 납품 목록에서는 제외했다.','',
      '## 재현과 다음 권장 단계','',
      '지정 Python에 `-B`를 붙여 이 폴더의 `rebuild.py` → `verify.py` → `finish_report.py` 순서로 실행한다. 첫 후보는 `before/`에 보존되며 재실행해도 덮어쓰지 않는다. `config.json`은 행별 단일 배율과 전체 이동량이다.','',
      '**다음 권장 단계:** 리드/QA-22가 새 후보를 재생해 전환 크기와 전진감을 확인한다. 모든 자세의 부위 폭까지 엄격히 같아야 한다면, 표에 남긴 수호자 주먹 등의 원본 재작화가 필요하다. 이 카드에서는 공통 배율과 위치 조정까지만 수행했다.','',
      '근거: [크기 원자료](sizes.json), [재구축 이동량](rebuild-metrics.json), [카드3번 측정](point-3.json), [검증 결과](verification.json), [4배 육안 기록](visual-review.json), [납품 목록](delivery-files.txt), [실행하지 않은 커밋 스크립트](commit.ps1).','']
    (r.FIX/'README.md').write_text('\n'.join(body),'utf-8')
    # Only exact candidate changes and artifacts created here; never run.log,
    # ignored raws, caches or unrelated existing untracked report folders.
    files=[]
    for mid in r.IDS:
        for row in r.ROWS:
            if (mid,row) in changed:
                files += [f'art/bakeoff/monsters/{mid}-{row}-v1.{ext}' for ext in ['png','json']]
        files.append(f'art/bakeoff/monsters/{mid}_sheet-v1.png')
    for p in r.FIX.rglob('*'):
        if p.is_file() and p.name not in ['run.log','delivery-files.txt','delivery-hashes.json'] and '__pycache__' not in p.parts:
            files.append(p.relative_to(r.ROOT).as_posix())
    files+=['reports/codex-art-76/fix-1/delivery-files.txt','reports/codex-art-76/fix-1/delivery-hashes.json']
    files=sorted(set(files))
    (r.FIX/'delivery-files.txt').write_text('\n'.join(files)+'\n','utf-8')
    r.dump(r.FIX/'delivery-hashes.json',{p:r.sha(r.ROOT/p) for p in files if not p.endswith('delivery-hashes.json')})
    print('REPORT',len(changed),'changed rows;',len(visual),'rows /',sum(len(d['frames']) for d in visual),'frames viewed at 4x;',len(files),'delivery files')

if __name__=='__main__':main()
