"""Preserve first-pass reports and add corrected versions without overwriting."""
import json
from pathlib import Path
root=Path('reports/codex-art-82')
specs=[
 ('verify_results.py','verify_results_v2.py',[
  ('8-column strip and empty padding','normalizer column count and empty padding'),
  ('im.size==(8*cell,cell)',"im.size==(s['output_columns']*cell,cell)"),
  ('audit.json','audit-v2.json'),('commit-files.json','commit-files-v2.json'),('commit.ps1','commit-v2.ps1')]),
 ('commit.ps1','commit-v2.ps1',[('commit-files.json','commit-files-v2.json')]),
 ('README.md','README-v2.md',[('audit.json','audit-v2.json'),('commit.ps1','commit-v2.ps1')])]
for source,dest,replacements in specs:
    p=root/dest;assert not p.exists(),p
    text=(root/source).read_text(encoding='utf-8')
    for a,b in replacements:
        assert a in text,(source,a);text=text.replace(a,b)
    if dest=='README-v2.md':
        text=text.replace('# CODEX-ART-82 결과','# CODEX-ART-82 결과 — 최종 검증 v2',1)
        text+='\n## 검증 정정 기록\n\n첫 audit.json의 7개 실패는 검증기가 스트립을 8열로 가정한 오류다. 실제 ART-72 정규화 도구는 6열이며 기존 후보도 같은 규격이다. 후보 이미지는 수정하지 않았다. verify_results_v2.py가 정규화 메타데이터의 output_columns로 검사한다. 덮어쓰기 금지에 따라 최초 검사·스크립트·README를 보존하고 v2를 추가했다. 최종 전달 커밋 스크립트는 commit-v2.ps1이며 commit.ps1과 함께 실행하지 않았다.\n'
    p.write_text(text,encoding='utf-8')
rows=json.loads((root/'results.json').read_text(encoding='utf-8'))
files=[p.as_posix() for p in root.rglob('*') if p.is_file() and p.name!='run.log' and '__pycache__' not in p.parts]
files+=['design/tasks/CODEX-ART-82.md','design/tasks/CODEX-ART-82.prompt.md','reports/codex-art-82/commit-files-v2.json','reports/codex-art-82/audit-v2.json']
files+=[Path(r['candidate']).with_suffix(s).as_posix() for r in rows if r['deliver'] for s in ['.png','.json']]
p=root/'commit-files-v2.json';assert not p.exists()
p.write_text(json.dumps(sorted(set(files)),indent=2)+'\n',encoding='utf-8')
print('Final manifest paths:',len(set(files)))
