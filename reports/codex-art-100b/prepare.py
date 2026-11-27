"""ART-100B: references only. Grey ART-57 mannequin, Jupi 2.5-head proportions."""
from pathlib import Path
import importlib.util, json, shutil, subprocess
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-art-100b'
RAW=ROOT/'art/raw/jupi-100b'
RAW.mkdir(parents=True,exist_ok=True)
anchor=ROOT/'art/bakeoff/newchar-2026-11-26/jupi/2/jupi-idle-2.png'
shutil.copy2(anchor,RAW/'anchor.png')
im=Image.open(anchor).convert('RGBA')
im.resize((512,512),Image.Resampling.NEAREST).save(RAW/'anchor-4x.png')
source=ROOT/'reports/codex-art-57/frey/make_walk_reference.py'
shutil.copy2(source,REPORT/'make_walk_reference_source.py')
spec=importlib.util.spec_from_file_location('mannequin',source)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
m.TORSO=(136,136,136,255);m.TORSO_RIM=(80,80,80,255)

def panel(i):
    im=Image.new('RGBA',(512,512),(248,248,248,255));d=ImageDraw.Draw(im)
    ground,hip,shoulder,head_r=476,344,260,70
    p=m.pose_data(i,hip,ground,132,48)
    # ART-58 passing: planted vertical under hips, swing next to ankle.
    if i in (2,6):
        standing=[(256,hip),(256,410),(256,ground-8),(276,ground)]
        swinging=[(252,hip+4),(280,402),(260,ground-54),(278,ground-42)]
        p['near'],p['far']=(standing,swinging) if i==2 else (swinging,standing)
    d.line((56,480,456,480),fill=m.GROUND,width=3)
    far_arm=[(252,shoulder+14),(287,shoulder+63),(312+(-14,-7,0,7,14,7,0,-7)[i],shoulder+99)]
    near_arm=[(250,shoulder+12),(214,shoulder+45),(170,shoulder+38)]
    m.limb(d,p['far'],m.FAR,m.FAR_RIM,27)
    m.limb(d,far_arm,m.FAR,m.FAR_RIM,25)
    d.rounded_rectangle((216,shoulder,296,hip+18),radius=20,fill=m.TORSO,outline=m.TORSO_RIM,width=6)
    d.ellipse((194,120,334,260),fill=m.TORSO,outline=m.TORSO_RIM,width=6)
    d.polygon([(330,179),(347,190),(330,198)],fill=m.TORSO,outline=m.TORSO_RIM)
    d.ellipse((304,178,314,188),fill=(255,255,255),outline=m.TORSO_RIM,width=2)
    m.limb(d,p['near'],m.NEAR,m.NEAR_RIM,27)
    d.line((164,122,164,473),fill=(70,70,70),width=9)
    d.ellipse((128,128,200,224),outline=(100,100,100),width=8)
    for x,y in [(164,128),(132,154),(196,154),(142,204),(186,204)]:
        d.ellipse((x-13,y-13,x+13,y+13),fill=(208,208,208),outline=(70,70,70),width=4)
    m.limb(d,near_arm,m.NEAR,m.NEAR_RIM,25)
    return im.convert('RGB')

board=Image.new('RGB',(2048,1024),'white')
for i in range(8):
    p=panel(i);p.save(RAW/f'pose-{i+1}.png');board.paste(p,((i%4)*512,(i//4)*512))
board.save(REPORT/'walk-reference.png')
old=Image.open(ROOT/'art/bakeoff/luna/luna-walk-v5.png').convert('RGBA')
old.crop((256,0,384,128)).resize((512,512),Image.Resampling.NEAREST).save(RAW/'passing-pose-only.png')
disk=shutil.disk_usage(ROOT)
(REPORT/'start.json').write_text(json.dumps({'start_utc':'2026-11-27 11:09:41','deadline_utc':'2026-11-27 13:19:41','branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'free_bytes':disk.free,'estimated_new_bytes':100*1024**2},indent=2)+'\n',encoding='utf-8')
status=subprocess.check_output(['git','status','--porcelain','-uall'],cwd=ROOT,text=True,encoding='utf-8')
(REPORT/'initial-status.txt').write_text(status,encoding='utf-8')
print(json.dumps({'free_gib':round(disk.free/1024**3,2),'reference':'ready'}))
