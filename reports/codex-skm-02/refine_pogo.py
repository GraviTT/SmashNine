"""Explicit correction after grid-F6 review: proposal touched the ear."""
import json
from pathlib import Path
base=Path('reports/codex-skm-02/rio_male/pogo_bounce/attempt-2')
d=json.loads((base/'face-proposed.json').read_text(encoding='utf-8'))
points=[]
for f in d['frames']:
 l,r=f['landmarks'][2:4];points.append([l['x'],r['x'],r['y']])
points[-1]=[112.5,128,45]
Path('reports/codex-skm-02/rio_male-pogo_bounce-face-points.json').write_text(json.dumps({'anchor':[68,83,51],'frames':points,'correction':'F6 자동 왼쪽 111.5는 귀 끝을 포함. 좌표 격자 검수 후 볼 시작 112.5로 수정.'},ensure_ascii=False),encoding='utf-8')
