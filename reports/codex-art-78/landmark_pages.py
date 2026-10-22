"""ART-72 process.py landmark-grid layout, centred on reviewed eye proposals."""
import sys,json
from pathlib import Path
from PIL import Image,ImageDraw
stem,row,attempt=sys.argv[1:4]
p=Path(f'reports/codex-art-78/{stem}/{row}/attempt-{attempt}')
j=json.loads((p/'face-proposed.json').read_text())
sheet=Image.open(p/f'{stem}-{row}.png').convert('RGBA');cell=sheet.height
folder='frey' if stem=='frey' else 'luna';v={'frey':2,'luna':3,'luna_brave':4}[stem]
a=Image.open(f'art/bakeoff/{folder}/{stem}-idle-v{v}.png').convert('RGBA').crop((0,0,128,128))
out=p/'landmark-pages';out.mkdir(exist_ok=True)
for k,(f,marks) in enumerate([(a,j['anchor_landmarks'])]+[(sheet.crop((i*cell,0,(i+1)*cell,cell)),r['landmarks']) for i,r in enumerate(j['frames'])]):
 cx=(marks[0]['x']+marks[1]['x'])/2;cy=(marks[0]['y']+marks[1]['y'])/2
 ox=round(cx)-18;oy=round(cy)-13;size=32;scale=20
 canvas=Image.new('RGB',(720,730),(31,38,55));d=ImageDraw.Draw(canvas)
 cr=f.crop((ox,oy,ox+size,oy+size)).resize((size*scale,size*scale),Image.Resampling.NEAREST)
 canvas.paste(cr,(55,55),cr)
 for x in range(size+1):
  if x%2==0:d.text((55+x*scale,25),str(ox+x),fill='white')
  d.line((55+x*scale,55,55+x*scale,695),fill=(80,80,80))
 for y in range(size+1):
  if y%2==0:d.text((20,55+y*scale),str(oy+y),fill='white')
  d.line((55,55+y*scale,695,55+y*scale),fill=(80,80,80))
 d.text((10,5),'ANCHOR' if k==0 else f'F{k}',fill='white')
 canvas.save(out/f'{k:02d}.png')
print(json.dumps({'anchor':j['anchor_landmarks'],'frames':[{k:r[k] for k in ['frame','landmarks','eye_ratio','face_width_ratio']} for r in j['frames']]},indent=2))
