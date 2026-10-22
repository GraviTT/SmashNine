import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json
from PIL import Image,ImageDraw
import process as p
data=json.loads((p.REPORT/'manual_motion.json').read_text('utf-8'))
for mid,feet in data['feet'].items():
    path=p.REPORT/f'{mid}-walk-feet-4x.png';board=Image.open(path).convert('RGB');d=ImageDraw.Draw(board)
    for fi,points in enumerate(feet):
        x=400*fi+8;y=40
        for label,point,colour in zip(['N','F'],points,[(255,220,75),(255,145,95)]):
            xx=x+point[0]*4;yy=y+point[1]*4
            d.ellipse((xx-6,yy-6,xx+6,yy+6),outline=colour,width=2);d.text((xx-3,yy-25),label,font=p.n.font(15),fill=colour)
        d.text((x,23),f'N {points[0]} / F {points[1]} (manual)',font=p.n.font(13),fill='white')
    board.save(path)
    mp=p.REPORT/mid/'walk'/'metrics.json';m=json.loads(mp.read_text('utf-8'));m['manual_leg_positions']={'method':data['feet_method'],'frames':feet};mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8')
for mid,r in data['reach'].items():
    path=p.REPORT/f'{mid}-action-review-4x.png';board=Image.open(path).convert('RGB');d=ImageDraw.Draw(board)
    # windup last and attack F3 occupy cells 1 and 4 in the original board.
    for ii,point in [(1,r['before']),(4,r['after'])]:
        x=(ii%3)*432+40+4*point[0];y=(ii//3)*440+36+4*point[1]
        d.ellipse((x-8,y-8,x+8,y+8),outline=(255,220,75),width=2)
    dx=r['after'][0]-r['before'][0];dy=r['after'][1]-r['before'][1]
    d.text((8,422),f'Manual reach: dx {dx}px / dy {dy}px; uncertainty about 2px',font=p.n.font(16),fill=(255,220,75))
    board.save(path)
    mp=p.REPORT/mid/'attack'/'metrics.json';m=json.loads(mp.read_text('utf-8'));m['manual_reach']={'method':data['reach_method'],**r,'dx':dx,'dy':dy};mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8')
    # Main requested 1x + 4x comparison also includes the actual walking pose evidence.
    mainpath=p.REPORT/f'{mid}.png';main=Image.open(mainpath).convert('RGB');feet=Image.open(p.REPORT/f'{mid}-walk-feet-4x.png').convert('RGB')
    combined=Image.new('RGB',(main.width,main.height+feet.height+40),(24,29,40));combined.paste(main,(0,0));combined.paste(feet,(0,main.height+40));combined.save(mainpath)
print('walking toe positions and six reach comparisons annotated')
