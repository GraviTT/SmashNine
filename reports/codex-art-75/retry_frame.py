"""Extract a padded reference / replace one generated frame. No feature drawing or per-frame fitting.

Replacement image resolution alone is mapped back to the original padded canvas;
the normaliser subsequently applies one shared row factor to every whole figure.
"""
import sys,json
from pathlib import Path
from PIL import Image
stem,row,base,index=sys.argv[1:5];base=int(base);index=int(index)-1
r=Path('art/raw/motions-75');src=r/f'{stem}-{row}-{base}.png';im=Image.open(src).convert('RGB')
cols=3 if row=='victory' else {'jump':3,'fall':2,'hurt':3,'land':2}[row]
rows=2 if row=='victory' else 1
w,h=im.width//cols,im.height//rows;s=max(w,h);ox,oy=(s-w)//2,(s-h)//2
box=(index%cols*w,index//cols*h,(index%cols+1)*w,(index//cols+1)*h)
if len(sys.argv)==5:
 f=im.crop(box);b=Image.new('RGB',(s,s),(0,255,0));b.paste(f,(ox,oy));out=r/f'{stem}-{row}-{base}-f{index+1}-padded.png';b.save(out);print(out)
else:
 nxt=int(sys.argv[5]);raw=r/f'{stem}-{row}-{nxt}-f{index+1}.png';f=Image.open(raw).convert('RGB')
 if f.width!=f.height:raise ValueError('Single replacement must preserve padded square canvas')
 ratio=s/f.width;f=f.resize((s,s),Image.Resampling.LANCZOS).crop((ox,oy,ox+w,oy+h));im.paste(f,box[:2]);out=r/f'{stem}-{row}-{nxt}.png';im.save(out)
 report={'source':str(src),'generated_frame':str(raw),'replaced_frame':index+1,'canvas_resolution_ratio':ratio,'padded_cell':s,'crop_back':[ox,oy,ox+w,oy+h],'unmodified_frames_preserved':True,'note':'Canvas resolution conversion only. No body/head-size fitting.'}
 Path(f'reports/codex-art-75/{stem}-{row}-{nxt}-composition.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(out)
