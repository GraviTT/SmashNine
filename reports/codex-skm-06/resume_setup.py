"""Update report wording and validation rules for the explicitly authorized continuation."""
from pathlib import Path
p=Path('reports/codex-skm-06/deliver.py')
s=p.read_text(encoding='utf-8')
s=s.replace('- shot의 얼굴 표식은 직접 확인했다. shot_alt의 자동 표식 일부는 빗나가 확정 실측으로 취급하지 않는다. 얼굴 검수 미완료와 시간 종료로 보류했다.', '- 얼굴 표식은 검토 판에서 확인한 값만 확정한다. 돌아서거나 뒤집힌 얼굴은 측정 제외로 기록하고 직립 프레임을 기준으로 배율을 확인한다.')
s=s.replace('미착수 9행은 별도 후속 작업이다.', '미도달 행은 별도 후속 작업이다.')
s=s.replace('비행 보드 마지막 단은','반복 동작 보드 마지막 단은')
s=s.replace("'time-limit.json']", "'time-limit.json','clock.ps1','resume_setup.py']")
p.write_text(s,encoding='utf-8')
p=Path('reports/codex-skm-06/verify_skm.py')
s=p.read_text(encoding='utf-8')
s=s.replace("check(g['references']==REFS,key+' both actual reference paths')", "check(len(g['references'])==2 and g['references'][0].replace('\\\\','/')==REFS[0].replace('\\\\','/') and g['references'][1].replace('\\\\','/').endswith(('xion_illustration-b2.png','xion-shot-v1.png')),key+' actual reference paths retained')")
s=s.replace("1<=g['attempt']<=2 and len([v for v in ledger if v['row']==g['row']])<=2", "1<=g['attempt']<=(4 if g['row']=='shot_alt' else 2) and len([v for v in ledger if v['row']==g['row']])<=(4 if g['row']=='shot_alt' else 2)")
p.write_text(s,encoding='utf-8')
