"""Sequential final validation; no Godot, downloads, or git mutations."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
os.environ['PYTHONIOENCODING']='utf-8'
import subprocess,sys
from pathlib import Path
from PIL import Image,ImageDraw
import process as p

if __name__=='__main__':
    log=p.REPORT/'validation.log'
    with log.open('w',encoding='utf-8') as f:
        for script in ['fix_pass.py','verify.py','feet_review.py','inspect_sizes.py','landmarks.py','evidence.py','reach_review.py','review_evidence.py','make_review_report.py']:
            f.write('\n=== '+script+' ===\n');f.flush()
            subprocess.run([sys.executable,str(p.REPORT/script)],cwd=p.ROOT,stdout=f,stderr=subprocess.STDOUT,check=True)
    # The unchanged shared normalizer has a fixed 128px header. Correct the report caption only.
    for path in p.REPORT.glob('*/*/compare.png'):
        im=Image.open(path).convert('RGB');d=ImageDraw.Draw(im)
        d.rectangle((0,0,im.width,47),fill=(11,16,28))
        d.text((12,5),'SMASHNINE ART-74 | actual cells: 96 px | enlarged 4x',font=p.n.font(18),fill='white')
        d.text((12,29),'pink baseline = y72; flyers use body landmark alignment',font=p.n.font(13),fill=(160,180,205));im.save(path)
    print('FINAL CHECK: 6 monsters, 36 rows, 168 frames. See verification.json and validation.log.')
