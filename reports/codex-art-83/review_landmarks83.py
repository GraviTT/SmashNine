"""Correct the mossling landmark after the 14x coordinate review; preserve earlier evidence."""
import json
import measure83 as m
import repair as r
data=json.loads((r.REPORT/'measure-final/movement-final.json').read_text('utf-8'))
old=[(58,36),(56,31)];new=[(45,35),(61,34)]
frames=[m.ims('mossling','attack')[i] for i in [0,2]]+[m.ims('mossling','attack','a')[i] for i in [0,2]]
for f,p in zip(frames,old+new):assert f.getpixel(p)[3]>0
data[0].update(before_points=old,after_points=new,before_forward_px=-2,after_forward_px=16,review='14배 좌표 확대에서 갈색 줄기와 등 몸통이 만나는 부착부 중심을 재지정. 기존 movement-final.json의 임시 표식보다 우선함.')
m.board('mossling','attack',frames,['V1 F1 root','V1 F3 root','V2 F1 root','V2 F3 root'],[dict(points=[p]) for p in old+new],'mossling-forward-reviewed.png')
r.jsave(r.REPORT/'measure-final/movement-reviewed.json',data)
