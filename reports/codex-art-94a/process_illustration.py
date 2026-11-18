from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/bakeoff/xion/a'
REPORT=ROOT/'reports/codex-art-94a'
RAW=ROOT/'art/raw/xion-94a'
def resize(im,size):
    return im.convert('RGBa').resize(size,Image.Resampling.LANCZOS).convert('RGBA')
def clean(im):
    a=np.array(im.convert('RGBA')).copy()
    a[a[:,:,3]<8]=0
    a[a[:,:,3]>=250,3]=255
    # Bound the generated soft matte to two pixels around the solid silhouette.
    # This removes low-alpha extraction residue; it does not repaint the subject.
    from PIL import ImageFilter
    core=Image.fromarray((a[:,:,3]>=128).astype('uint8')*255)
    near=np.array(core.filter(ImageFilter.MaxFilter(5)))>0
    a[~near]=0
    a[a[:,:,3]==0,:3]=0
    return Image.fromarray(a)
def measure(im):
    a=np.array(im); alpha=a[:,:,3]; box=im.getchannel('A').getbbox()
    rgb=a[:,:,:3].astype(int)
    green=(alpha>0)&(rgb[:,:,1]>rgb[:,:,0]+32)&(rgb[:,:,1]>rgb[:,:,2]+32)&(rgb[:,:,1]>80)
    core=Image.fromarray((alpha>=128).astype('uint8')*255)
    from PIL import ImageFilter
    near=np.array(core.filter(ImageFilter.MaxFilter(5)))>0
    return dict(size=list(im.size),mode=im.mode,alpha_bbox=box,subject_height_px=box[3]-box[1],height_percent=round((box[3]-box[1])/im.height*100,2),margins_ltrb=[box[0],box[1],im.width-box[2],im.height-box[3]],alpha_range=[int(alpha.min()),int(alpha.max())],border_pixels=int((alpha[0]>0).sum()+(alpha[-1]>0).sum()+(alpha[:,0]>0).sum()+(alpha[:,-1]>0).sum()),transparent_rgb_residual=int(np.any(a[:,:,:3]!=0,axis=2)[alpha==0].sum()),green_spill_pixels=int(green.sum()),alpha_outside_2px_core=int(((alpha>0)&~near).sum()))
source=Image.open(RAW/'illustration-01.png').convert('RGBA')
im=clean(source); box=im.getchannel('A').getbbox(); subject=im.crop(box)
factor=1352/subject.height; size=(round(subject.width*factor),1352)
assert size[0]<=1024,size
scaled=resize(subject,size); canvas=Image.new('RGBA',(1024,1536))
offset=((1024-size[0])//2,92); canvas.alpha_composite(scaled,offset); canvas=clean(canvas)
canvas.save(OUT/'xion_illustration-a.png')
# Manually inspected source landmarks: centre between eyes (555,242), crown y=130, chin y=316.
eye=(round((555-box[0])*factor+offset[0]),round((242-box[1])*factor+offset[1]))
crop_size=512; left=eye[0]-crop_size//2; top=round(eye[1]-.4*crop_size)
face=clean(resize(canvas.crop((left,top,left+crop_size,top+crop_size)),(256,256)))
face.save(OUT/'xion_face-a.png')
for name,img,bg in [('illustration-light',canvas,'#c8c4b8'),('illustration-dark',canvas,'#2a2d34'),('face-2x',face.resize((512,512),Image.Resampling.NEAREST),'#c8c4b8')]:
    Image.alpha_composite(Image.new('RGBA',img.size,bg),img).convert('RGB').save(REPORT/(name+'.png'))
metrics={'illustration':measure(canvas),'face':measure(face),'processing':{'source':str((RAW/'illustration-01.png').relative_to(ROOT)),'source_bbox':box,'scale':factor,'alpha_cleanup':'alpha<8 cleared; alpha>=250 set opaque; soft matte bounded to 2px around alpha>=128; premultiplied LANCZOS; no chroma key'},'manual_landmarks':{'source_eyes': [555,242],'final_eyes':eye,'face_crop_ltrb':[left,top,left+512,top+512],'eye_height_percent':round((eye[1]-top)/512*100,3),'crown_chin_source_y':[130,316],'head_height_source_px':186,'subject_heads_approx':round(subject.height/186,3),'method':'manual landmarks from full-size visual inspection, not automatic anatomy detection'}}
(REPORT/'illustration-metrics.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(metrics,ensure_ascii=False,indent=2))

