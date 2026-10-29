"""ART-78 full source-cell replacement; no feature drawing or local scaling."""
import sys,json,shutil,hashlib
from pathlib import Path
from PIL import Image
base,generated,out,grid,indices=sys.argv[1:]
out=Path(out); saved=out.with_stem(out.stem+'-generated')
assert not out.exists() and not saved.exists()
shutil.copy2(generated,saved)
a=Image.open(base).convert('RGB'); b=Image.open(saved).convert('RGB')
original_size=b.size
# A single full source canvas is registered to one cell, not a body part.
cols,rows=map(int,grid.split('x')); selected=list(map(int,indices.split(',')))
boxes=[]
for k in selected:
 x,y=(k-1)%cols,(k-1)//cols
 box=(round(x*a.width/cols),round(y*a.height/rows),round((x+1)*a.width/cols),round((y+1)*a.height/rows))
 a.paste(b.resize((box[2]-box[0],box[3]-box[1]),Image.Resampling.LANCZOS),box[:2]);boxes.append(box)
a.save(out)
record={'base':base,'generated':str(saved),'out':str(out),'original_size':original_size,'canvas_size':a.size,'replaced_frames':selected,'boxes':boxes,'method':'ART-72/77 single-frame retry: entire square canvas registered to source-cell coordinate system; other cells pixel-identical. Final row uses one normalization factor.'}
out.with_suffix('.assembly.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps(record))
