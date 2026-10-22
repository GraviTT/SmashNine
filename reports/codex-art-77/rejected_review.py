"""4x review of normalized rejected generations; never candidate publication."""
import json
from pathlib import Path
from PIL import Image,ImageDraw
root=Path('reports/codex-art-77');notes=[]
for stem,row,attempt,count,reason in [('rio_female','hurt',1,3,'F1 purple hair tips; at final face factor sword margin insufficient before common x shift'),('rio_female','hurt',2,3,'F1 purple hair tips remain after whole-strip image edit'),('rio_female','victory',1,6,'Sword changes near/far hands between F3/F4/F5; not published')]:
 base=root/stem/row/f'attempt-{attempt}';im=Image.open(base/f'{stem}-{row}.png').convert('RGBA');cell=im.height;outdir=root/'rejected'/f'{stem}-{row}-{attempt}';outdir.mkdir(parents=True,exist_ok=True)
 for start in range(0,count,2):
  k=min(2,count-start);board=Image.new('RGB',(cell*4*k,cell*4+40),(31,38,55));d=ImageDraw.Draw(board)
  for j in range(k):
   f=im.crop(((start+j)*cell,0,(start+j+1)*cell,cell)).resize((cell*4,cell*4),Image.Resampling.NEAREST);board.paste(f,(j*cell*4,40),f);d.text((j*cell*4+8,8),f'REJECTED {stem} {row} attempt{attempt} F{start+j+1}',fill='white')
  board.save(outdir/f'page-{start//2+1}.png')
 notes.append({'stem':stem,'row':row,'attempt':attempt,'frames_reviewed_at_4x':list(range(1,count+1)),'reason':reason,'candidate_published':False})
(root/'rejected'/'summary.json').write_text(json.dumps(notes,indent=2),encoding='utf-8')
