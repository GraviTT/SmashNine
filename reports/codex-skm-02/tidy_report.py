"""Format final measured ranges without masking near-threshold rejections."""
import json,re
from pathlib import Path
root=Path('reports/codex-art-72')
path=root/'README.md';text=path.read_text(encoding='utf-8')
rows=json.loads((root/'summary.json').read_text(encoding='utf-8'))
def span(v):
    return f'{v[0]:.3f}' if v[0]==v[1] else f'{v[0]:.3f}–{v[1]:.3f}'
for r in rows:
    frames='F1–'+str(r['frames']) if len(r['face_valid_frames'])==r['frames'] else 'F'+','.join(map(str,r['face_valid_frames']))
    pattern=r'\| '+r['row']+r' \| '+str(r['frames'])+r' · '+str(r['fps'])+r' \| '+str(r['factor'])+r' \| [^\n]+'
    row=f'| [{r["row"]}]({r["stem"]}-{r["row"]}.png) | {r["frames"]} · {r["fps"]} | {r["factor"]} | {span(r["face_eye_range"])} / {span(r["face_width_range"])} ({frames}) | {r["margin"]}px | {r["detail"][0]:.2f}–{r["detail"][1]:.2f} | {"완료" if r["accepted"] else "미전달"} |'
    text=re.sub(pattern,row,text,count=1)
text=text.replace('얼굴 눈/폭 (전 프레임)','얼굴 눈/폭 (측정 프레임)')
text=re.sub(r'- \*\*([^\n]+?차)\):',r'- **\1):**',text)
path.write_text(text,encoding='utf-8')
manifest=root/'files-to-stage.json';files=json.loads(manifest.read_text(encoding='utf-8'))
new='reports/codex-art-72/tidy_report.py'
if new not in files:
    files.append(new);files.sort();manifest.write_text(json.dumps(files,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    ps=root/'commit.ps1';script=ps.read_text(encoding='utf-8');script=script.replace("$files = @(\n","$files = @(\n    '"+new+"'\n",1);ps.write_text(script,encoding='utf-8',newline='\n')
    text=path.read_text(encoding='utf-8').replace('명시한 156개 파일','명시한 157개 파일');path.write_text(text,encoding='utf-8')
print('Final tables show three decimal face ratios and linked 4x boards.')
