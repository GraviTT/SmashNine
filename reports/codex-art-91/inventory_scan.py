"""Read-only source scan; writes new ART-91 inventory files exclusively."""
from pathlib import Path
import ast, re, json, hashlib
from datetime import datetime
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'reports/codex-art-91'
def rel(p): return p.relative_to(ROOT).as_posix()
def read(p): return p.read_text(encoding='utf-8-sig')
def new(p, text):
    with p.open('x', encoding='utf-8', newline='\n') as f: f.write(text)
def tables(p):
    s=read(p); result={}
    for m in re.finditer(r'^const (\w+)\s*:?=\s*\[',s,re.M):
        if 'ROWS' not in m.group(1): continue
        start=m.end()-1; level=0
        for i in range(start,len(s)):
            if s[i]=='[':level+=1
            elif s[i]==']':level-=1
            if level==0:break
        raw=re.sub(r'#.*','',s[start:i+1]).replace('true','True').replace('false','False')
        result[m.group(1)]=dict(source=rel(p),line=s[:m.start()].count('\n')+1,rows=ast.literal_eval(raw))
    return result

base=tables(ROOT/'smash-nine-prototype/characters/common/PlayerBase.gd')
monster_tables=tables(ROOT/'smash-nine-prototype/scripts/RealmMonster.gd')
forms=['frey','luna','luna_brave','nova_male','nova_female','rio_male','rio_female','yuki']
monster_paths=sorted((ROOT/'smash-nine-prototype/assets/art/monsters').glob('*_sheet.png'))
monsters=[p.stem.removesuffix('_sheet') for p in monster_paths]
owners=sorted(forms+monsters,key=len,reverse=True)
records=[]; other=[]; errors=[]
pngs=sorted((ROOT/'art/bakeoff').rglob('*.png'))
for p in pngs:
    m=re.fullmatch(r'(.+)-v(\d+)',p.stem)
    entry={'png':rel(p),'dimensions':list(Image.open(p).size),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
    jp=p.with_suffix('.json')
    if jp.exists():
        try: entry['metadata']=json.loads(read(jp)); entry['json']=rel(jp)
        except Exception as exc: errors.append({'path':rel(jp),'error':str(exc)})
    if not m: other.append(entry);continue
    prefix=m.group(1); owner=next((o for o in owners if prefix.startswith(o+'-')),None)
    entry.update(version=int(m.group(2)),owner=owner,row=prefix[len(owner)+1:] if owner else prefix)
    entry['adopted']=entry.get('metadata',{}).get('adopted',False)
    entry['adoption_status']='채택 표시 있음' if entry['adopted'] else '채택 표시 없음'
    records.append(entry)

speed_text=read(ROOT/'smash-nine-prototype/characters/common/MotionSpeeds.gd')
speeds={k:float(v) for k,v in re.findall(r'"([^"\n]+)"\s*:\s*([0-9.]+)',speed_text)}
entities=[]; readmes=[]
def row_specs(rows,source,cell,feet,form=None):
    result=[]
    for row,count,fps,loop in rows:
        prefix=form;body='default'
        if form and form.endswith(('_male','_female')):prefix,body=form.rsplit('_',1)
        result.append(dict(row=row,frames=count,table_fps=fps,fps=speeds.get(f'{prefix}/{body}/{row}',fps),loop=loop,cell=cell,feet=feet,source=source))
    return result
for form in forms:
    char=form.split('_')[0]; p=ROOT/f'smash-nine-prototype/characters/{char}/{char.title()}.gd'; t=tables(p)
    sheet=ROOT/f'smash-nine-prototype/assets/art/{char}/{form}_sheet.png'
    move=sheet.with_name(f'{form}_moves_sheet.png')
    rows=row_specs(t['SHEET_ROWS']['rows'],rel(sheet),128,120,form)
    move_key='BRAVE_MOVE_SHEET_ROWS' if form=='luna_brave' else 'MOVE_SHEET_ROWS'
    if move.exists():rows+=row_specs(t[move_key]['rows'],rel(move),192,152,form)
    optional=[]
    for spec in base['OPTIONAL_MOTION_ROWS']['rows']:
        op=sheet.with_name(f'{form}_{spec[0]}.png');cell=192 if spec[0]=='victory' else 128
        valid=op.exists() and Image.open(op).size==(cell*spec[1],cell)
        optional.append(dict(row=spec[0],path=rel(op),exists=op.exists(),loader_shape_valid=valid))
        if valid:
            rows=[r for r in rows if r['row']!=spec[0]]+row_specs([spec],rel(op),cell,152 if cell==192 else 120,form)
    candidates=[x for x in records if x['owner']==form]
    entities.append(dict(id=form,kind='fighter',game_sheet=rel(sheet),game_dimensions=list(Image.open(sheet).size),code_tables=t,in_game_rows=rows,optional_files=optional,candidates=candidates))
    rp=sheet.with_name(f'{form}_moves_README.md')
    readmes.append(dict(path=rel(rp),table_lines=[l for l in read(rp).splitlines() if l.startswith('|')]))
for mid,p in zip(monsters,monster_paths):
    w,h=Image.open(p).size;cell=w//6;key='ART_ROWS_SIX' if h==6*cell else 'ART_ROWS'
    entities.append(dict(id=mid,kind='monster',game_sheet=rel(p),game_dimensions=[w,h],table=key,in_game_rows=row_specs(monster_tables[key]['rows'],rel(p),cell,int(cell*.75)),candidates=[x for x in records if x['owner']==mid]))

# Priorities are proposals, not implementation or production completion claims.
proposals=[]
def propose(kind,row,priority,reason,ref,cell=128,feet=120,fps=10,loop=False,owner='후속 후보'):
    relevant=[e for e in entities if e['kind']==kind]
    absent=[e['id'] for e in relevant if row not in {r['row'] for r in e['in_game_rows']} and row not in {c['row'] for c in e['candidates']}]
    proposals.append(dict(kind=kind,row=row,priority=priority,reason=reason,missing_for=absent,frames=6,fps=fps,loop=loop,cell=cell,feet=feet,reference_row=ref,owner=owner,classification='제안'))
for row,pri,reason,ref,cell,feet,fps,loop in [
 ('dodge_roll',1,'회피의 시작·끝과 자세를 읽기 쉽게 구분','tumble',192,152,12,False),
 ('stun',1,'피격 반동과 지속 기절 상태를 구분','hurt',128,120,8,True),
 ('run_start',1,'대기에서 이동으로 체중 이동을 연결','walk',128,120,12,False),
 ('run_stop',1,'이동 정지의 감속과 자세 회복','walk',128,120,12,False),
 ('air_recovery',1,'날아감에서 자세 회복을 구분; 기술 복귀기와 별개','tumble',192,152,12,False),
 ('guard_break',2,'방어가 무너지는 반응; 규칙 도입 여부는 별도','shield',192,152,10,False),
 ('portal_enter',2,'렐름 이동 직전의 몸 동작','idle',128,120,10,False),
 ('portal_exit',2,'렐름 이동 직후 자세 회복','land',128,120,10,False),
 ('crouch',2,'낮은 대기 자세; 앉기 규칙은 별도','idle',128,120,8,True),
 ('taunt',2,'캐릭터 성격과 도발 표현','victory',192,152,8,False),
 ('grab',3,'잡기 시스템 결정이 먼저 필요','shield',192,152,10,False),
 ('throw',3,'잡기/던지기 규칙·방향 확정 필요','attack',192,152,12,False),
 ('wall_cling',3,'벽 상호작용 규칙 확정 필요','fall',192,152,8,True),
 ('wall_jump',3,'벽 점프 규칙 확정 필요','jump',192,152,12,False),
 ('ledge_grab',3,'매달리기 규칙 확정 필요','fall',192,152,8,True),
 ('ledge_climb',3,'턱 오르기 규칙 확정 필요','land',192,152,10,False),
 ('surprise',3,'스토리 몸 연기 확장','idle',128,120,8,False),
 ('laugh',3,'스토리 몸 연기 확장','victory',192,152,8,True)]:
    propose('fighter',row,pri,reason,ref,cell,feet,fps,loop,'ART-92 진행 중(카드 지정; 다른 클론 결과 미확인)' if row in ['dodge_roll','taunt','stun','crouch','run_start'] else '후속 후보')
for row,pri,reason,ref,fps,loop in [('appear',1,'스폰 순간부터 준비 자세까지 몸 동작으로 식별','windup',10,False),('rage',2,'공격과 구분되는 분노 예고; 분노 규칙은 미확정','windup',10,False),('sleep',3,'비전투 생태 표현; 수면 규칙은 미확정','defeat',6,True),('flee',3,'퇴각 상태 표현; 도주 규칙은 미확정','walk',10,True)]:
    propose('monster',row,pri,reason,ref,96,72,fps,loop,'ART-91: appear 전 종 → rage 전 종 → 여유 시 sleep/flee')
for e in entities:
    e['missing_general_motions']=[p['row'] for p in proposals if e['id'] in p['missing_for']]
    e['references']={}
    for row in ['idle','windup','defeat','walk','hurt','shield','tumble','victory','land','jump','fall']:
        choices=[c for c in e['candidates'] if c['row']==row]
        if choices:e['references'][row]=max(choices,key=lambda c:c['version'])['png']

doc_scan=[]
doc_paths=list((ROOT/'design').glob('*.md'))+[ROOT/'reports/skill-design-2026-10-15/README.md']
for p in doc_paths:
    if not p.exists():continue
    hits=[{'line':i+1,'text':l} for i,l in enumerate(read(p).splitlines()) if any(x in l for x in ['미제작','미구현','차원 연결','연결선','그리지','새 기술','미완'])]
    if hits:doc_scan.append(dict(path=rel(p),matches=hits))
data=dict(scanned_at=datetime.now().astimezone().isoformat(),branch='codex/art-91',scope='이 클론 정적 파일; Godot 실행 없음',counts=dict(fighter_forms=len(forms),monsters=len(monsters),candidate_pngs=len(pngs),versioned_pngs=len(records),other_pngs=len(other)),base_tables=base,monster_tables=monster_tables,entities=entities,priorities=proposals,other_versioned_candidates=[r for r in records if not r['owner']],other_pngs=other,move_readmes=readmes,design_mentions=doc_scan,errors=errors)
new(OUT/'inventory.json',json.dumps(data,ensure_ascii=False,indent=2)+'\n')
lines=['# ART-91 모션 목록과 누락 우선순위',f"\n작성: {data['scanned_at']} · 브랜치 codex/art-91 · 정적 조사",'\n## 확인한 사실',f"- 전투원 8형태·몬스터 18종. bakeoff PNG {len(pngs)}개 전수 확인: 버전 파일 {len(records)}개, 기타 {len(other)}개. JSON에는 모든 경로·크기·채택 값·PNG 해시를 보존했다.",'- `채택`은 JSON adopted 값이 있는 기록이다. 최신 버전이라는 이유만으로 채택되었다고 판단하지 않는다. 게임 행은 실제 게임 시트 크기와 로더 테이블로 별도 확인했다.', '- 현재 몬스터 18종 게임 시트는 모두 576×384로 idle/walk/attack/hurt 4행이다. 6행 후보와 ART_ROWS_SIX 지원 코드가 존재해도 현재 게임 시트와 같지는 않다.', '- 전투원 OPTIONAL_MOTION_ROWS는 jump/fall/hurt/land/victory를 지원하지만 이 클론의 해당 전용 PNG 유무와 로더 규격 검사를 아래에 따로 기록한다.', '- 행 FPS는 MotionSpeeds 값이 있으면 반영했다. 기술의 실제 타격 타이밍은 pose clock으로 제어되므로 단순 fps만으로 재생 시간을 단정하지 않는다.', '- 별도 표시 없는 우선순위·fps·동작 필요성은 제작 제안이며 기존 게임 규칙이나 플레이 검증 결과가 아니다.']
lines+=['\n## 누락 일반 동작 우선순위(제안)','전투원은 8형태 전체, 몬스터는 18종 전체를 각각 대조했다. 크기·발선은 셀 규격이며 몸 크기는 해당 형태 idle에 맞춘다. 공중/벽 동작의 feet는 정렬 기준이지 모든 프레임 접지를 뜻하지 않는다.','\n|대상|동작|우선|누락 수|셀/발|프레임/fps/반복|참조|담당·이유|','|---|---|---:|---:|---|---|---|---|']
for p in proposals:lines.append(f"|{p['kind']}|{p['row']}|{p['priority']}|{len(p['missing_for'])}|{p['cell']}/{p['feet']}|6/{p['fps']}/{p['loop']}|idle + {p['reference_row']}|{p['owner']} · {p['reason']}|")
lines+=['\n## 중복 제작 제외·기술 세션 경계','- ART-92: dodge_roll, taunt, stun, crouch, run_start. 이 클론에는 아직 후보가 없으며 다른 클론의 진행 결과는 확인하지 않았다.', '- 기술 세션: 아래 각 형태의 MOVE_SHEET_ROWS 중 tumble을 제외한 모든 공격/J·K·L·I 행과 해당 *_moves_README.md의 행. 몬스터 special_attack도 일반 모션 제작에서 제외하며 행동·판정 확정 후 별도 기술 작업으로 넘긴다.', '- `tumble`은 기술 시트에 저장되어도 피격 일반 동작이다. 이미 있으므로 새 회피와 혼동하지 않는다.', '- Frey attack_chain은 frey-attack 후보, Luna star_side는 luna-attack 후보를 쓰는 별칭이다. 별칭 후보 파일명이 없다는 이유로 미제작으로 세지 않았다.', '- 후보가 이미 있는 land/victory/defeat와 다프레임 jump/fall/hurt는 새 그림 누락이 아니라 채택·통합 검토 대상이다.', '- 문서의 Nova 핵 재입력/발사, Rio 반격, 공중 방향 파생 등은 기존 동작 재사용 또는 독립 행 부재가 있을 수 있다. 이를 새 일반 동작으로 만들지 않는다. 스킬 재설계안의 Rio 차원 연결·Yuki 연결선도 기술 세션 소유이며, 제안 문서를 구현 확정으로 읽지 않는다.', '- design/SKILLS.md에 없는 Rio 추가 점프 전용 이펙트는 몸 모션 누락과 별개다. 문서 검색 근거는 inventory.json의 design_mentions에 보존했다.']
for e in entities:
    lines += [f"\n## {e['id']} ({e['kind']})",f"게임 시트: `{e['game_sheet']}` · {e['game_dimensions']}",'\n|게임 행|프레임|FPS|반복|셀/발|','|---|---:|---:|---|---|']
    for r in e['in_game_rows']:lines.append(f"|{r['row']}|{r['frames']}|{r['fps']}|{r['loop']}|{r['cell']}/{r['feet']}|")
    if e.get('optional_files'):lines.append('\n선택 행 파일: '+', '.join(f"{o['row']}={'있음·규격 적합' if o['loader_shape_valid'] else '없음 또는 규격 부적합'}" for o in e['optional_files']))
    lines+=['\n|후보 행|버전·채택 상태|','|---|---|']
    for row in sorted({c['row'] for c in e['candidates']}):
        cs=sorted([c for c in e['candidates'] if c['row']==row],key=lambda c:c['version'])
        lines.append('|'+row+'|'+'; '.join(f"[v{c['version']}](../../{c['png']}) {'채택 '+str(c['adopted']) if c['adopted'] else '미채택 표시'}" for c in cs)+'|')
    lines+=['\n누락 일반 동작: '+', '.join(e['missing_general_motions']), '\n기준 idle: `'+e['references'].get('idle','없음')+'`']
lines+=['\n## 부가 후보와 조사 범위','초상화 표정·이펙트·투사체·조립 시트는 몸 모션과 분리했다. 전수 경로는 inventory.json의 other_versioned_candidates / other_pngs에 있다. 파일만 조사했으며 실제 게임 재생, 채택 UI의 원격 DB, 다른 클론의 진행은 확인하지 않았다.',f'\nJSON 읽기 오류: {errors}', '\n재실행은 기존 결과를 덮어쓰지 않도록 실패한다. 소스: inventory_scan.py.']
new(OUT/'inventory.md','\n'.join(lines)+'\n')
print(json.dumps(data['counts']));print('errors',errors);print('written',data['scanned_at'])
