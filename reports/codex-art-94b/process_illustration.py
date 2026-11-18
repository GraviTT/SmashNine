from pathlib import Path
from PIL import Image
import numpy as np
r=Path('reports/codex-art-94b')
raw=Path('art/raw/xion-94b')
out=Path('art/bakeoff/xion/b')
def clean_rgba(im):
    arr=np.array(im.convert('RGBA'))
    rgb=arr[:,:,:3].astype(np.int16)
    spill=(arr[:,:,3]>0)&(rgb[:,:,1]>np.maximum(rgb[:,:,0],rgb[:,:,2])+20)
    arr[:,:,1][spill]=np.maximum(arr[:,:,0],arr[:,:,2])[spill]
    arr[arr[:,:,3]==0]=0
    print('green-dominant RGB corrected',int(spill.sum()))
    return Image.fromarray(arr)
im=Image.open(raw/'illustration-v1.png').convert('RGBA')
a=np.array(im)
a[a[:,:,3]<=4]=0
im=Image.fromarray(a)
b=im.getbbox()
cr=im.crop(b)
f=1352/cr.height
cr=cr.resize((round(cr.width*f),1352),Image.Resampling.LANCZOS)
a=np.array(cr); a[a[:,:,3]<=1]=0; cr=Image.fromarray(a)
can=Image.new('RGBA',(1024,1536)); can.alpha_composite(cr,((1024-cr.width)//2,92))
can=clean_rgba(can)
can.save(out/'xion_illustration-b.png')
face=clean_rgba(can.crop((278,14,790,526)).resize((256,256),Image.Resampling.LANCZOS))
face.save(out/'xion_face-b.png')
faceboard=Image.new('RGBA',(512,512),'#2a2d34')
faceboard.alpha_composite(face.resize((512,512),Image.Resampling.NEAREST))
faceboard.convert('RGB').save(r/'face-2x.png')
for bg,name in [('#c8c4b8','light'),('#2a2d34','dark')]:
    board=Image.new('RGBA',can.size,bg); board.alpha_composite(can); board.convert('RGB').save(r/f'illustration-{name}.png')
# Rio is proportions/pixel detail reference only, not identity.
rio=Image.open('smash-nine-prototype/assets/art/rio/rio_female_sheet.png').convert('RGBA').crop((0,0,128,128))
rio.resize((512,512),Image.Resampling.NEAREST).save(raw/'rio-female-idle-f1-4x.png')
# Faces: installed framing reference, shown on a background for inspection only.
board=Image.new('RGBA',(1024,512),'#2a2d34')
for x,p in [(0,'frey/frey_face.png'),(512,'rio/rio_female_face.png')]:
    face=Image.open('smash-nine-prototype/assets/art/'+p).convert('RGBA')
    board.alpha_composite(face.resize((512,512),Image.Resampling.NEAREST),(x,0))
board.convert('RGB').save(r/'reference-faces-2x.png')
print('source_bbox',b,'factor',f,'output_bbox',can.getbbox())
