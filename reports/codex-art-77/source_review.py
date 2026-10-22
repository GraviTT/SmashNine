"""Review failed source-grid drawings; never publish these as candidates."""
import json,sys
from pathlib import Path
from PIL import Image,ImageDraw
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n
root=Path('reports/codex-art-77/source-check');root.mkdir(exist_ok=True)
results=[]
for key,grid,factor in [('rio_male-jump-1',(3,1),.17),('rio_male-victory-1',(3,2),.23),('rio_female-victory-2',(3,2),.255)]:
 frames,labels=n.split_sheet(Path(f'art/raw/motions-77/{key}.png'),grid);items=[]
 for i,(im,label) in enumerate(zip(frames,labels)):
  cleaned,background=n.clean_background(im,'#00ff00');b=n.alpha_bbox(cleaned)
  edges=[name for ok,name in [(b[0]==0,'left'),(b[1]==0,'top'),(b[2]==im.width,'right'),(b[3]==im.height,'bottom')] if ok]
  # Scaled whole-source cell, then exact nearest 4x: the failed cut stays visible.
  preview=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.LANCZOS);preview=preview.resize((preview.width*4,preview.height*4),Image.Resampling.NEAREST)
  out=Image.new('RGB',(preview.width+16,preview.height+50),(31,38,55));out.paste(preview,(8,42));d=ImageDraw.Draw(out);d.text((8,6),f'{key} F{i+1}: {",".join(edges) or "no edge"}',fill='white');d.rectangle((8,42,8+preview.width-1,42+preview.height-1),outline='red',width=2);out.save(root/f'{key}-F{i+1}.png')
  items.append({'frame':i+1,'source_bbox':b,'cell_size':im.size,'touched':edges,'review_scale_factor':factor,'qa_only':True})
 results.append({'raw':key,'frames':items})
(root/'source-failures.json').write_text(json.dumps(results,indent=2),encoding='utf-8');print(json.dumps(results))
