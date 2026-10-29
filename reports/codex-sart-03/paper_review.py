"""Full paper ROIs at 3x plus approximate silhouette measurements, no edits."""
import json
import argparse
import numpy as np
from PIL import Image, ImageDraw
from audit import ROOT, OUT, SRC, font, jpg
from prepare_root import ROIS, component

def hull(points):
    pts=sorted(set(map(tuple,points)))
    if len(pts)<=2:return pts
    def cross(o,a,b):return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
    lower=[]
    for p in pts:
        while len(lower)>=2 and cross(lower[-2],lower[-1],p)<=0:lower.pop()
        lower.append(p)
    upper=[]
    for p in reversed(pts):
        while len(upper)>=2 and cross(upper[-2],upper[-1],p)<=0:upper.pop()
        upper.append(p)
    return lower[:-1]+upper[:-1]

def rotated_box(mask):
    ys,xs=np.where(np.asarray(mask)>0)
    points=np.array(hull(zip(xs,ys)),dtype=float)
    if len(points)<3:return None
    best=None
    for i in range(len(points)):
        edge=points[(i+1)%len(points)]-points[i];angle=np.arctan2(edge[1],edge[0]);c,s=np.cos(angle),np.sin(angle)
        proj=points@np.array([[c,-s],[s,c]])
        sides=np.ptp(proj,axis=0)+1;area=np.prod(sides)
        if best is None or area<best[0]:best=(area,sides)
    sides=sorted(best[1]);return {'short_px':round(float(sides[0]),3),'long_px':round(float(sides[1]),3),'long_over_short':round(float(sides[1]/sides[0]),3)}

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--version',type=int,default=4);args=ap.parse_args();v=args.version
    im=Image.open(ROOT/f'art/bakeoff/story/cg_root-v{v}.png').convert('RGB')
    original=Image.open(SRC/'cg_root.png').convert('RGB');measure=[]
    for page in range(2):
        sh=Image.new('RGB',(2200,1824),'#101827');d=ImageDraw.Draw(sh)
        for j,roi in enumerate(ROIS[page*20:(page+1)*20]):
            i=page*20+j;x=j%5*440;y=j//5*456
            cr=im.crop(roi).resize(((roi[2]-roi[0])*3,(roi[3]-roi[1])*3),Image.Resampling.NEAREST)
            sh.paste(cr,(x+8,y+54))
            d.text((x+12,y+12),f'ROI {i+1:02d} / 3×',fill='#f3cd7c',font=font(24))
            before,_=component(original,roi);after,_=component(im,roi)
            measure.append({'roi_id':i+1,'roi_xyxy':list(roi),'before':rotated_box(before),'after':rotated_box(after)})
        jpg(f'cg-root-all-papers-3x-{page+1}-v{v}.jpg',sh)
    representative=[measure[i-1] for i in [1,23,35]]
    result={'method':'Minimum-area rotated bounding rectangle of filled warm-neutral paper silhouette; 1px closing from component extraction; perspective/curl and dark brush marks affect projected ratio. This is not an intrinsic-plane measurement.',
            'representative_ROIs':representative,'all_rois':measure,
            'note':'ROI 39/40 also inspect tiny distant colored flecks. ROI count is not a proven count of discrete talismans.'}
    path=OUT/f'paper-shape-measurements-cg-v{v}.json';assert not path.exists()
    path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(representative,indent=2))

if __name__=='__main__':main()
