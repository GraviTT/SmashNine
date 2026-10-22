"""Crop/assemble an image-tool frame retry. Never paint character pixels."""
import sys,json
from pathlib import Path
from PIL import Image
raw=Path('art/raw/motions-77')
if sys.argv[1]=='crop':
 im=Image.open(raw/'rio_female-hurt-1.png');w=im.width//3;im.crop((0,0,w,im.height)).save(raw/'rio_female-hurt-F1-target.png')
else:
 im=Image.open(raw/'rio_female-hurt-1.png').convert('RGB');w=im.width//3;replacement=Image.open(raw/'rio_female-hurt-F1-retry-generated.png').convert('RGB')
 source_size=replacement.size
 # Match the whole square source canvas, not a cropped body or a head.
 if replacement.size!=(w,im.height):replacement=replacement.resize((w,im.height),Image.Resampling.LANCZOS)
 im.paste(replacement,(0,0));im.save(raw/'rio_female-hurt-3.png')
 Path('reports/codex-art-77/frame-retry.json').write_text(json.dumps({'original':'rio_female-hurt-1.png','replacement':'rio_female-hurt-F1-retry-generated.png','output':'rio_female-hurt-3.png','replaced_frame':1,'generated_canvas':source_size,'source_cell_canvas':[w,im.height],'canvas_resample':'lanczos if dimensions differ; no body/head fitting','unchanged_frames':[2,3]},indent=2),encoding='utf-8')
