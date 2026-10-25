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
if b.size!=a.size:b=b.resize(a.size,Image.Resampling.LANCZOS)
cols,rows=map(int,grid.split('x')); selected=list(map(int,indices.split(',')))
boxes=[]
for k in selected:
 x,y=(k-1)%cols,(k-1)//cols
 box=(round(x*a.width/cols),round(y*a.height/rows),round((x+1)*a.width/cols),round((y+1)*a.height/rows))
 a.paste(b.crop(box),box[:2]);boxes.append(box)
a.save(out)
record={'base':base,'generated':str(saved),'out':str(out),'original_size':original_size,'canvas_size':a.size,'replaced_frames':selected,'boxes':boxes,'method':'ART-78: entire cell replacement; other source cells pixel-identical. Whole canvas coordinate registration only.'}
out.with_suffix('.assembly.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps(record))
