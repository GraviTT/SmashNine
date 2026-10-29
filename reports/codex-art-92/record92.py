import sys,json,datetime
from pathlib import Path
R=Path('reports/codex-art-92')
stem,row,reason,best=sys.argv[1:5]
now=datetime.datetime.now().astimezone().isoformat(timespec='seconds')
data={'time':now,'stem':stem,'row':row,'status':'fail','reason':reason,'best':best,'frames':6}
with (R/f'{stem}-{row}-result.json').open('x',encoding='utf-8') as f:json.dump(data,f,ensure_ascii=False,indent=2)
with (R/'progress.md').open('a',encoding='utf-8') as f:f.write(f'{now} | {stem} | {row} | 미납품 | 6 | FAIL | {reason}\n')
with (R/'commit-paths.txt').open('a',encoding='utf-8') as f:f.write(f'reports/codex-art-92/{stem}-{row}-result.json\n')
print(json.dumps(data,ensure_ascii=False))
