"""Compile QA-23 measurements and explicit human observations, no verdict by pixels alone."""
import sys
sys.dont_write_bytecode=True
import collections,json,re
from pathlib import Path
from audit import ROOT,OUT,dump,STEMS
from findings import LIVE,SHEET_NOTES
from candidate_notes import note

def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(name,s):(OUT/name).write_text(s+'\n',encoding='utf-8')
def table(headers,rows):return '\n'.join(['| '+' | '.join(headers)+' |','|'+'|'.join(['---']*len(headers))+'|']+['| '+' | '.join(str(c).replace('|','/') for c in r)+' |' for r in rows])
def span(v):return '–'.join(map(str,v)) if v and v[0]!=v[-1] else str(v[0]) if v else '—'
def link_path(p):return f'[{Path(p).name}](../../{p})'
def measure_text(d,rows,mode,head=None):
    fs=[f for r in d['rows'] if r['name'] in rows.split('/') for f in r['frames']]
    if mode=='halo':return f"관찰색 외곽 {sum(f.get('observed_band_rim_px',0) for f in fs):,}px; 부분 알파 {sum(f['partial_alpha'] for f in fs):,}px (색 오염의 자동 증명 아님)"
    if mode=='margin':return '; '.join(f"{r['name']} "+','.join(f"F{f['frame']}={f['margin4_px']}px" for f in r['frames'] if f['margin4_px']) for r in d['rows'] if r['name'] in rows.split('/'))+'; 바깥 1px 접촉 0'
    if mode=='fragment':
        r=next(r for r in d['rows'] if r['name']==rows);f5,f6=r['frames'][4:6]
        return f"F5 bbox 우측 직선 {f5['bbox_edge_runs']['right']}px; F6 분리 성분 {f6['component_sizes'][1]}px; 셀 외곽 접촉 0"
    if mode=='feet':return '최하단 y='+','.join(str(f['bottom']) for f in fs)+f"; 기준 {d['feet']} (그림의 부츠도 확인)"
    if mode=='head':return f"머리 추정 중앙값 {head['median']:.2f}; 신뢰도≥0.6 {head['accepted']}/{head['total']}; 허용 0.96–1.04"
    if mode=='shape' or mode=='size':
        r=next(r for r in d['rows'] if r['name']==rows);s=r['summary']
        return f"H {span(s['height_range'])}px, A {span(s['area_range'])}px; F1 면적 idle 대비 {s['first_area_vs_idle_pct']:+.2f}%; 모양 결함 자체는 육안 판단"
    if mode=='fx':return f"{len(fs)}칸 행, A {min(f['area'] for f in fs)}–{max(f['area'] for f in fs)}px; 효과 포함은 육안 판단"
    # The bbox run is a measured boundary, not by itself proof of a cut.
    return '; '.join(f"{r['name']} "+','.join(f"F{f['frame']} L/R/B={f['bbox_edge_runs']['left']}/{f['bbox_edge_runs']['right']}/{f['bbox_edge_runs']['bottom']}" for f in r['frames']) for r in d['rows'] if r['name'] in rows.split('/'))+'px; 셀 외곽 0'

def priority(f):
    rows=f['row'].split('/')
    if 'idle' in rows:return 0
    if 'walk' in rows:return 1
    if f['sheet'].endswith('_sheet') and not f['sheet'].endswith('_moves_sheet') and f['sheet'].split('_sheet')[0] in STEMS and 'attack' in rows:return 8
    if any(r in ['attack','mana_combo','attack_chain','brave_combo','talisman_side','vector_side'] for r in rows):return 2
    if any(r in ['jump','fall'] for r in rows):return 5
    if 'hurt' in rows:return 6
    return 7

def main():
    index=read(OUT/'metrics/live_index.json');live={Path(x['path']).stem:read(OUT/'metrics'/f"{Path(x['path']).stem}.json") for x in index}
    heads={}
    for p in (OUT/'metrics/heads').glob('*.json'):
        for r in read(p).get('rows',[]):heads[(r['sheet'],r['row'])]=r
    # Star comet can fire standing or airborne; do not blanket-exempt its ground pose.
    for d in live.values():
        for r in d['rows']:
            if r['name']=='star_comet':r['feet_mode']='ground_or_air'
        dump(OUT/'metrics'/f"{Path(d['path']).stem}.json",d)
    findings=[]
    for row in LIVE:
        key,rs,frames,sev,kind,obs,repair,mode=row;d=live[key]
        findings.append(dict(sheet=key,path=d['path'],row=rs,frames=frames,severity=sev,kind=kind,observed=obs,repair=repair,number=measure_text(d,rs,mode,heads.get((key,rs))),scope='live'))
    findings.sort(key=lambda f:(priority(f),{'상':0,'중':1,'하':2}[f['severity']],f['path']))
    for i,f in enumerate(findings,1):f['id']=f'L{i:02d}'
    ci=read(OUT/'metrics/candidate_index.json');candidates={Path(x['path']).stem:read(OUT/'metrics/candidates'/f"{Path(x['path']).stem}.json") for x in ci}
    queue=read(OUT/'metrics/candidate_visual_queue.json');hq=read(OUT/'metrics/candidate_head_contacts.json');viewed={x['path'] for x in queue+hq}
    # One candidate finding per unique row pixels; atlas and component strip are aliases.
    signatures=collections.defaultdict(list)
    for d in candidates.values():
        for r in d['rows']:signatures[tuple(f['rgba_sha256'] for f in r['frames'])].append((d['path'],r['name']))
    cf=[];seen=set()
    for d in sorted(candidates.values(),key=lambda d:(d['storage']!='six_column_atlas',d['path'])):
        if d['path'] not in viewed or d['kind']!='monster':continue
        for r in d['rows']:
            sig=tuple(f['rgba_sha256'] for f in r['frames'])
            if sig in seen or not r['summary']['margin4_px']:continue
            seen.add(sig);bad=[f for f in r['frames'] if f['margin4_px']]
            cf.append(dict(scope='candidate',sheet=Path(d['path']).stem,path=d['path'],row=r['name'],frames=','.join(str(f['frame']) for f in bad),severity='하',kind='여백',observed='몸/장비가 4px 안전 여백에 들어온다. 외곽 1px은 비어 있어 즉시 잘림은 아니다.',repair='crop/pad',number=', '.join(f"F{f['frame']}={f['margin4_px']}px" for f in bad)+'; 셀 외곽 0',aliases=signatures[sig]))
    d=candidates['niflheim_glacier_wolf_sheet-v1'];r=next(r for r in d['rows'] if r['name']=='hurt');sig=tuple(f['rgba_sha256'] for f in r['frames'])
    cf.append(dict(scope='candidate',sheet=Path(d['path']).stem,path=d['path'],row='hurt',frames='1',severity='중',kind='잘림/잔여 조각',observed='올려든 머리 상단이 수평으로 끊겨 보인다. 6배 확대에서 귀/머리 위 윤곽 누락을 확인했으며 원본과 대조 후 다시 자른다.',repair='re-slice',number='상단 y=21; 최상단 연속 수평선 8px; 셀 외곽 0',aliases=signatures[sig]))
    cf.sort(key=lambda f:(priority(f),{'상':0,'중':1,'하':2}[f['severity']],f['path']))
    for i,f in enumerate(cf,1):f['id']=f'C{i:02d}'
    allfind=findings+cf;counts=collections.Counter(f['severity'] for f in findings);cc=collections.Counter(f['severity'] for f in cf)
    stats={'live_files':len(index),'live_frames':sum(x['frames'] for x in index),'live_rows':sum(x['rows'] for x in index),'candidate_files':len(ci),'candidate_frames':sum(x['frames'] for x in ci),'candidate_viewed_files':len(viewed),'live_findings':len(findings),'live_severity':dict(counts),'candidate_unique_findings':len(cf),'candidate_severity':dict(cc),'live_kind':dict(collections.Counter(f['kind'] for f in findings)),'candidate_kind':dict(collections.Counter(f['kind'] for f in cf))}
    dump(OUT/'metrics/summary.json',stats);dump(OUT/'metrics/findings.json',allfind)
    fix=['# 이미지 세션 수리 목록','',f"현재 게임 {len(findings)}건, 후보 고유 행 {len(cf)}건. 건수는 파일·문제 묶음 기준이다. 같은 문제의 여러 프레임은 한 건이며 서로 다른 문제는 같은 행에서도 따로 센다. 후보 합본과 개별 스트립은 픽셀 해시로 중복 제거했다.",'','순서: 현재 대기 → 걷기 → J/몬스터 공격 → 나머지 기술 → 공중/피격 → 예비 공격·투사체, 이후 후보. 상=신체/무기 큰 누락, 중=눈에 띄는 연속성·정렬·색/부분 절단, 하=작은 여백·기준 크기·효과 분리. `re-slice`는 원본이 온전할 때만 가능하며 원본도 잘렸다면 `redraw`로 전환한다. 머리만 잘라 붙이는 수리는 하지 않는다.','',table(['ID/등급','파일','행 · 프레임','문제(직접 관찰)','측정값','수리 종류'],[[f['id']+' '+f['severity'],link_path(f['path']),f['row']+' · '+f['frames'],f['observed'],f['number'],f['repair']] for f in findings]),'','## 후보 — 채택하지 않고 수리 정보만 전달','',table(['ID/등급','파일','행 · 프레임','문제','측정값','수리 종류'],[[f['id']+' '+f['severity'],link_path(f['path']),f['row']+' · '+f['frames'],f['observed'],f['number'],f['repair']] for f in cf]),'','## 후보 중복 파일 대응','']
    fix+=['- '+f['id']+': '+'; '.join('`'+p+'` / '+r for p,r in f['aliases']) for f in cf]
    fix+=['','현재 문제와 같은 채택 이력 후보: `nova_female-hurt-v1`(8px), `rio_female-attack-v1`(55px 조각/축소), `rio_female-mana_combo-v1`(80px 조각), `rio_male-attack-v1`(머리 0.72). 새 후보 결함 건수에는 다시 더하지 않았다.','', '머리 추정만 경계를 넘은 후보 Luna fall/victory, Brave fall/hurt와 Nova meteor_kick은 [후보 표](candidate-rows.md)에 수동 재확인 대상으로 남겼다. 얼굴 방향 차이를 배제하지 못했으므로 확정 수리 건수에서 제외했다.']
    write('fix-list.md','\n'.join(fix))
    kinds=sorted(set(f['kind'] for f in allfind))
    countrows=[[k]+[sum(f['kind']==k and f['severity']==s for f in findings) for s in ['상','중','하']]+[sum(f['kind']==k and f['severity']==s for f in cf) for s in ['상','중','하']] for k in kinds]
    common=['# QA-23 스프라이트 전수 검사','',table(['범위','이미지','사용 프레임','육안 확인'],[['현재 게임: 캐릭터 기본/기술',16,sum(x['frames'] for x in index if x['kind'].startswith('fighter')), '16개 전체'],['현재 게임: 몬스터 몸',18,270,'18개 전체'],['현재 게임: 투사체',9,9,'9개 전체(현재는 모두 단일 그림)'],['후보: 캐릭터/몬스터/초상화',len(ci),sum(x['frames'] for x in ci),f'계측 경고 {len(viewed)}개 전체']]),'',table(['문제 종류','현재 상','현재 중','현재 하','후보 상','후보 중','후보 하'],countrows), '',f"**완료:** 현재 {len(index)}개 이미지·{stats['live_frames']}프레임·{stats['live_rows']}논리 행을 계측하고 전부 보았다. 후보 {len(ci)}개 계측, 경고 {len(viewed)}개를 보았다. 현재 수리 {len(findings)}건(상 {counts['상']}, 중 {counts['중']}, 하 {counts['하']}), 후보 중복 제거 수리 {len(cf)}건(상 {cc['상']}, 중 {cc['중']}, 하 {cc['하']}). 이 수는 결함 프레임 수가 아니라 수리 항목 수다.",'','현재 시트 치수/프레임 수/빈 셀 검사는 모두 맞았다. 하지만 셀 안에서 이미 잘린 그림은 이 검사에 통과한다. Rio 여성 J의 검끝, 달 사슴 공격, 뿌리 수호자 공격, 세 몬스터 대기 하단이 대표 사례다. 게임·아트는 수정하지 않았고 Godot 및 git은 실행하지 않았다.','', '[수리 목록](fix-list.md) · [후보 전체 행 표](candidate-rows.md) · [생성 파일 목록](files.txt) · [JSON 집계](metrics/summary.json)','', '![우선 수리 예시](contact/priority_examples.png)','원본을 최근접 확대해 조합한 검사 이미지다. 실행 화면이 아니며 화살표/수치는 관찰 위치를 설명한다.','', '## 판정과 측정 방법','', '- `좋음`은 이번 계측/접촉 이미지에서 확정 수리 결함을 보지 못했다는 뜻이다. 애니메이션 재생 품질이나 모든 해부학적 정확성을 보장하지 않는다. `손질`은 이동·패딩·픽셀 정리·다시 자르기, `다시 그림`은 형태/크기·효과 분리가 필요한 행이다.', '- alpha≥128을 몸 윤곽으로 계측하고 alpha>0 외곽도 별도로 보존했다. bbox 오른쪽/아래는 포함하지 않는 좌표다. H/W=전체 그림 높이/너비, A=보이는 픽셀 면적이며 무기·머리카락도 포함한다. 인접 변화에는 마지막→처음 연결을 제외했고 루프 동일 여부는 별도로 기록했다.', '- 바깥 1px 접촉과 안쪽 4px 여백 침범은 별도다. bbox의 긴 직선만으로 잘림을 확정하지 않고 확대 그림과 함께 판단했다. L/R/B는 bbox 왼쪽/오른쪽/아래의 최장 연속 픽셀 수다.', '- 기본은 128셀·발 y120, 기술은 192셀·발 y152. 몬스터 현재 96셀의 일반 행은 마지막 불투명 y71(경계 y72), 구 골렘은 y79(경계 y80)이다. 기존 코드가 사용하는 경계 좌표 때문에 생기는 1px 차이는 결함으로 세지 않았다. 후보 6행은 주로 마지막 y72다. 최하단은 검/머리카락일 수도 있어 발 위치 확정에는 부츠/발도 보았다.', '- 공중/혼합/비행 행은 아래 표에 표시하고 고정 접지선 판정을 생략했다. star_comet은 지상/공중 겸용이며 지상 그림은 기준선을 확인했다. 지상 공격의 도약 역시 자동 feet 경고만으로 수리하지 않는다.', '- D35 이후 고정 팔레트 검사는 하지 않았다. RGB 분포 거리, 초록/자홍/백색 외곽, 부분 알파의 위치, 8방향 연결 성분을 저장했다. 식물의 녹색·눈/마법의 발광색·LANCZOS의 부분 알파는 그 자체로 오류가 아니다. 작은 분리 성분도 실제 그림에서 잔여물로 확인된 것만 지적했다.', '- 머리 메타데이터는 발견되지 않아 `tools/sprite_pipeline/head_scale.py`의 피부 성분/30px 템플릿 비교를 읽기 전용으로 사용했다. 같은 스케일/17×17 이동 탐색을 FFT로 계산했고 원 함수와 대조했다. 신뢰도 0.6 미만은 제외했다. 표의 추정치는 얼굴 각도/가림에 민감하다. Yuki·회전·변신·비인간형 몬스터의 머리 크기는 신뢰할 자동 수치를 확보하지 못한 경우 명시했다. 머리만 붙이는 수정은 금지다.', '- 후보 349개는 지정한 6개 폴더 최상위 PNG 기준이다. 32개 초상화, 18개 6행 합본과 개별 스트립을 포함한다. 130개는 sidecar `adopted`가 있고 나머지는 채택 표시가 없다는 뜻이며 실제 대기 상태라고 단정하지 않는다. 합본/스트립 프레임 중복은 전체 계측 프레임 수에 포함된다. retired 등 하위 보관 폴더는 이번 최상위 범위에서 제외했다.', '', '## 기존 검사보다 더 확인한 것','', '`test_sprite_frames.gd`, `test_moves_sheet.gd`, `test_monster_motion.gd`, `test_fighter_motion.gd`의 행/개수/크기/기준선 계약을 읽었다. 재실행하지 않았다. 이번 검사는 실제 픽셀의 1px/4px 경계, 셀 내부 절단, bbox/면적/중심 변화, 해시 중복, 색/부분 알파 위치, 머리 추정과 접촉 이미지의 직접 관찰까지 더했다. 예를 들어 Rio mana_combo F6의 80px 분리 조각은 외곽 접촉 0이고 면적 변화도 작아 크기 검사만으로 찾기 어렵다.','', '## 현재 게임 — 이미지별 행 판정','']
    for key,d in live.items():
        common+=['### '+key,'',link_path(d['path'])+f" — {d['size'][0]}×{d['size'][1]}, 셀 {d['cell'][0]}×{d['cell'][1]}, 치수 일치 {d['dimensions_match']}; 추가 그림 셀 {len(d['extra_drawn_cells'])}개.",'',SHEET_NOTES[key],'',f"[2배 접촉 이미지](contact/{key}_2x.png) · [프레임별 원자료](metrics/{key}.json)",'']
        rows=[]
        for r in d['rows']:
            s=r['summary'];ff=[f for f in findings if f['sheet']==key and r['name'] in f['row'].split('/')]
            verdict='다시 그림' if any(f['repair']=='redraw' for f in ff) else '손질' if ff else '좋음'
            reason='; '.join(f['id']+' F'+f['frames']+' '+f['kind'] for f in ff) or '확정 결함 없음'
            hr=heads.get((key,r['name']));ht=(f"{hr['median']:.2f} ({hr['accepted']}/{hr['total']})" if hr and hr['median'] is not None else f"검출 보류 ({hr['accepted']}/{hr['total']})" if hr else '비인간/투사체: 미적용')
            bottom=[f['bottom'] for f in r['frames'] if f['bottom'] is not None]
            rows.append([r['name']+f" / R{r['start_row']+1} / {r['count']}칸",verdict,reason,f"{span(s['width_range'])} / {span(s['height_range'])} / {span(s['area_range'])}",f"A {s['max_area_step_pct']}%; 중심 {s['max_centre_step']}px; H {s['max_height_step']}px",f"H {s['first_height_vs_idle_pct']:+.2f}%; A {s['first_area_vs_idle_pct']:+.2f}%",f"y {min(bottom)}–{max(bottom)} / {r['feet_mode']}",f"{s['edge_px']} / {s['margin4_px']}",ht])
        common+=[table(['행/물리 시작행','판정','프레임·이유','W/H/A 범위','인접 최대 변화','F1 대 idle','최하단/접지 판정','1px/4px','머리 추정(유효/전체)'],rows),'']
        common+=[table(['행','부분 알파(외곽/안쪽)','초록 외곽/자홍/백색 외곽','RGB 거리 범위','빈 칸/인접 동일/루프 동일','작은 분리 픽셀(≤3px 성분)'],[[r['name'],f"{r['summary']['partial_alpha']} ({sum(f['partial_rim'] for f in r['frames'])}/{sum(f['partial_interior'] for f in r['frames'])})",f"{r['summary']['green_rim_px']}/{r['summary']['magenta_px']}/{r['summary']['white_rim_px']}",span([min(f.get('colour_distance_idle',0) for f in r['frames']),max(f.get('colour_distance_idle',0) for f in r['frames'])]),f"{len(r['summary']['missing'])}/{len(r['summary']['identical_adjacent'])}/{r['summary']['identical_loop']}",sum(len(f['tiny_component_pixels']) for f in r['frames'])] for r in d['rows']]),'']
    common+=['## 측정과 추정의 경계 / 남은 작업','', '- 43개 이미지의 정지 접촉 검사는 완료했다. 실제 게임 재생·히트박스·공격 시점·광원·중복 투사체는 확인하지 않았다(카드가 Godot 실행을 금지).', '- 피부/머리카락을 의미별로 분리한 정확한 색상 수치는 없다. RGB 거리와 직접 관찰만 사용했다. 머리 추정에서 낮은 신뢰도로 제외된 프레임은 수동 앵커 대조가 남는다. Nova 남성 meteor_kick 중앙값 1.05는 경계 경고이며 확정 결함으로 세지 않았다.', '- 원본 생성 그림까지 역추적해 잘림 원인을 증명하지 않았다. 다시 자르기 가능 여부는 이미지 세션이 원본에서 확인해야 한다. 그림에 없는 부위를 패딩/이동으로 복원할 수는 없다.', '- 후보 279개는 수치 경고가 없어 육안 검사를 하지 않았다. 그림 스타일의 우열·후보 채택 여부는 판단하지 않았다. 비인간형 몬스터의 머리 비율은 사람이 형태를 보았지만 D34 템플릿 수치로 검증하지 못했다.', '- 투사체의 4px 여백 부족은 모든 원자료에 남겼지만 작은 효과 그림에 대한 별도 몸 비율 규칙을 적용하지 않아 확정 수리 건수에서 제외했다. 필요하면 독립 발사체 디자인/패딩을 이미지 세션에서 검토한다.', '- 다음 권장 단계: [수리 목록](fix-list.md)의 현재 대기/걷기/J 및 큰 절단부터 복원 → 같은 스크립트로 재계측 → Godot 담당 유닛이 실제 재생과 발/효과 겹침 확인. 자동 후속 실행은 예약하지 않았다.']
    write('README.md','\n'.join(common))
    cr=['# 후보 전체 계측 / 경고 육안 확인','',f"{len(ci)}개 계측, {len(viewed)}개 접촉 이미지를 직접 보았다. 64개 기본 경고 + 6개 머리 비교 추가 경고. 표의 좋음(계측)은 육안 확인을 뜻하지 않는다. 4px 여백은 몸 후보에 한해 수리 목록으로 보냈다. 픽셀값이 같은 합본/개별 스트립을 골라 채택하지 않았다.",'']
    for key,d in candidates.items():
        vp=d['path'] in viewed;headp=OUT/'metrics/candidate_heads'/f'{key}.json';hd=read(headp) if headp.exists() else None
        cr+=['### '+key,'',link_path(d['path'])+f" — {d['size']}, 셀 {d['cell']}, {d['storage']}, sidecar {'있음' if d['has_sidecar'] else '없음'}, 채택 표시 {'있음' if d['candidate_status']=='adopted_archive' else '없음(대기 여부 미확정)'}.",'',f"[계측 JSON](metrics/candidates/{key}.json)"+(f" · [접촉 이미지](contact/candidate_{key}_2x.png)" if vp else ''),'', ('육안: '+note(d)) if vp else '육안 미검사: 자동 경고 없음. 계측만 완료.','']
        rr=[]
        for r in d['rows']:
            s=r['summary'];sig=tuple(f['rgba_sha256'] for f in r['frames']);ff=[f for f in cf if (d['path'],r['name']) in f.get('aliases',[])]
            h=next((h for h in hd['rows'] if h['row']==r['name']),None) if hd else None
            hr=(f"{h['median']:.2f} ({h['accepted']}/{h['total']})" if h and h['median'] is not None else '검출 보류' if h else '미적용')
            verdict='손질' if ff else '좋음' if vp else '좋음(계측)'
            if key in ['nova_female-hurt-v1','rio_female-attack-v1','rio_female-mana_combo-v1']:verdict='손질(현재 문제 중복)'
            if key=='rio_male-attack-v1':verdict='다시 그림(현재 문제 중복)'
            rr.append([r['name']+f" / R{r['start_row']+1} / {r['count']}칸",verdict,','.join(f['id'] for f in ff) or '추가 확정 수리 없음',f"{span(s['width_range'])}/{span(s['height_range'])}/{span(s['area_range'])}",f"{s['max_area_step_pct']}%/{s['max_centre_step']}px",f"{s['edge_px']}/{s['margin4_px']}",span(s['bottom_boundary_range'])+'/'+r['feet_mode'],f"{s['partial_alpha']}/{s['green_rim_px']}",hr])
        cr+=[table(['행','판정','수리 번호','W/H/A','인접 A/중심','1px/4px','하단 경계/모드','부분알파/초록외곽','머리(유효/전체)'],rr),'']
    write('candidate-rows.md','\n'.join(cr))
    print(json.dumps(stats,ensure_ascii=False,indent=2))

if __name__=='__main__':main()
