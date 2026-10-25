"""Create the explicit commit list once. No Git writes, staging or commit."""
from build_hurt import *

if __name__=='__main__':
    records=json.loads((REPORT/'measurements.json').read_text(encoding='utf-8'))
    paths=['design/tasks/CODEX-ART-84.md','design/tasks/CODEX-ART-84.prompt.md']
    for r in records:
        stem,e=r['stem'],r['expression']; folder=old.FORMS[stem]['folder']
        paths.extend(f'art/bakeoff/{folder}/{stem}_face-{e}-v2.{ext}' for ext in ['png','json'])
    # This directory contained only run.log at task start. Include authored
    # deliverables and scripts, never any ignored input or draft directory.
    for p in REPORT.iterdir():
        if p.is_file() and p.name!='run.log': paths.append(p.relative_to(ROOT).as_posix())
    paths.extend(['reports/codex-art-84/commit-files.txt','reports/codex-art-84/commit-validation.json'])
    paths=sorted(set(paths))
    assert not any('art/raw/' in p or '__pycache__' in p or 'run.log' in p or 'attempt' in p for p in paths)
    with (REPORT/'commit-files.txt').open('x',encoding='utf-8',newline='\n') as f: f.write('\n'.join(paths)+'\n')
    print('Explicit commit list:',len(paths),'files. Not staged.')
