import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, math, statistics
from PIL import Image, ImageDraw
import process as p
manual=json.loads((p.REPORT/'manual_landmarks.json').read_text('utf-8'))
out=[]
for mid,marks in manual.items():
    if mid=='method':continue
    board=Image.open(p.REPORT/f'{mid}-rulers.png').convert('RGB');d=ImageDraw.Draw(board)
    baseline=statistics.mean(math.dist(*points) for points in marks['idle'])
    for ri,row in enumerate(p.ROWS):
        values=[math.dist(*points) for points in marks[row]]
        for j,points in enumerate(marks[row]):
            col=(ri%2)*2+j;line=ri//2;x=col*432+40;y=32+line*440+36
            a,b=[(x+q[0]*4,y+q[1]*4) for q in points]
            d.line((*a,*b),fill=(255,220,75),width=2)
            for q in [a,b]:d.ellipse((q[0]-3,q[1]-3,q[0]+3,q[1]+3),outline='white',width=1)
            d.text((x,y+388),f'{values[j]:.1f}px / anchor {values[j]/baseline:.2f}x',font=p.n.font(14),fill=(255,220,75))
        record=dict(monster=mid,row=row,part=marks['part'],frames=[0,p.COUNTS[row]-1],lengths_px=[round(v,2) for v in values],anchor_mean_px=round(baseline,2),ratios=[round(v/baseline,3) for v in values],method=manual['method'])
        out.append(record)
        mp=p.REPORT/mid/row/'metrics.json';m=json.loads(mp.read_text('utf-8'));m['manual_size_ruler']=record;mp.write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8')
    board.save(p.REPORT/f'{mid}-size-4x.png')
    # Separate six-frame walking grid with automatic contact runs, no anatomy inference.
    ims=p.frames(p.BAKE/f'{mid}-walk-v1.png',6)
    board=Image.new('RGB',(6*400,456),(24,29,40));d=ImageDraw.Draw(board);contacts=[]
    for fi,im in enumerate(ims):
        x=400*fi+8;y=40;tile=p.n.checker((96,96)).convert('RGB');tile.paste(im,(0,0),im);board.paste(tile.resize((384,384),Image.Resampling.NEAREST),(x,y))
        a=p.n.np.asarray(im)[:,:,3]>0;xs=p.n.np.where(a[72])[0].tolist();runs=[]
        for xx in xs:
            if runs and xx==runs[-1][1]+1:runs[-1][1]=xx
            else:runs.append([xx,xx])
        contacts.append(dict(frame=fi+1,alpha_runs_y72=runs))
        d.text((x,5),f'F{fi+1} | x: 0  16  32  48  64  80',font=p.n.font(14),fill='white')
        for xx in range(0,97,8):d.line((x+4*xx,y,x+4*xx,y+384),fill=(70,73,89),width=1)
        d.line((x,y+73*4,x+384,y+73*4),fill=(235,90,110),width=1)
        for lo,hi in runs:d.line((x+4*lo,y+73*4+3,x+4*(hi+1)-1,y+73*4+3),fill=(90,240,200),width=3)
        d.text((x,428),'y72: '+str(runs),font=p.n.font(13),fill=(90,240,200))
    board.save(p.REPORT/f'{mid}-walk-feet-4x.png')
    (p.REPORT/mid/'walk'/'contacts.json').write_text(json.dumps({'method':'Opaque runs at y=72 only; does not identify feet or near/far legs. Floating monsters are not contact-tested.','frames':contacts},indent=2),'utf-8')
    # Six inspectable action frames, with grid, for reach/contact manual review.
    picks=[('windup',0),('windup',3),('attack',0),('attack',1),('attack',2),('attack',3)]
    board=Image.new('RGB',(3*432,2*440),(24,29,40));d=ImageDraw.Draw(board)
    for ii,(row,fi) in enumerate(picks):
        im=p.frames(p.BAKE/f'{mid}-{row}-v1.png',p.COUNTS[row])[fi];x=(ii%3)*432+40;y=(ii//3)*440+36
        tile=p.n.checker((96,96)).convert('RGB');tile.paste(im,(0,0),im);board.paste(tile.resize((384,384),Image.Resampling.NEAREST),(x,y));d.text((x,y-32),f'{row} F{fi+1}',font=p.n.font(16),fill='white')
        for k in range(0,97,8):
            d.line((x+4*k,y,x+4*k,y+384),fill=(70,73,89),width=1);d.line((x,y+4*k,x+384,y+4*k),fill=(70,73,89),width=1)
            if k<96:d.text((x+4*k,y-14),str(k),font=p.n.font(10),fill='white');d.text((x-26,y+4*k),str(k),font=p.n.font(10),fill='white')
    board.save(p.REPORT/f'{mid}-action-review-4x.png')
(p.REPORT/'size_measurements.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),'utf-8')
print('manual size measurements',len(out))
