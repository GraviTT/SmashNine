"""ART-71/74/76 representative-part size checks; not anatomy certification."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, math
from collections import deque
from PIL import Image, ImageDraw
import numpy as np
from repair import ROOT, OUT, BAKE, FONT, dump
def frame(path,i):return Image.open(path).convert('RGBA').crop(((i-1)*96,0,i*96,96))
def hood(im):
    a=np.asarray(im).astype(int);r,g,b,al=[a[:,:,i] for i in range(4)]
    mask=(al>0)&(r>70)&(r>1.35*g)&(r>1.8*b)&(np.arange(96)[:,None]<48)
    seen=np.zeros(mask.shape,bool);groups=[]
    for sy,sx in zip(*np.where(mask)):
        if seen[sy,sx]:continue
        q=deque([(sy,sx)]);seen[sy,sx]=True;pts=[]
        while q:
            y,x=q.popleft();pts.append((int(y),int(x)))
            for yy,xx in [(y-1,x),(y+1,x),(y,x-1),(y,x+1)]:
                if 0<=yy<96 and 0<=xx<96 and mask[yy,xx] and not seen[yy,xx]:seen[yy,xx]=True;q.append((yy,xx))
        groups.append(pts)
    pts=max(groups,key=len);ys,xs=zip(*pts)
    assert max(ys)<47,'imposed y=48 cut truncates selected hood'
    return dict(area=len(pts),size=math.sqrt(len(pts)),box=[min(xs),min(ys),max(xs)+1,max(ys)+1])
def main():
    data=json.loads((OUT/'repairs.json').read_text('utf-8'));results=[]
    old74=json.loads((ROOT/'reports/codex-art-74/fix-1/sizes.json').read_text('utf-8'))
    for cid in ['C01','C07','C14','C15']:
        c=next(x for x in data if x['id']==cid);mid=c['monster'];row=c['row'];idx=6 if cid=='C07' else 1
        bef=frame(OUT/'before'/PathName(c['source']),idx);aft=frame(OUT/'review-rows'/PathName(c['output']),idx)
        anchor=frame(BAKE/f'{mid}-idle-v1.png',1)
        if cid=='C15':
            a,b,z=hood(anchor),hood(bef),hood(aft)
            result=dict(id=cid,part='후드 주황 면의 sqrt(area), y<48; 최대 4연결 성분',sample_frame=1,idle=a,before=b,after=z,ratio=z['size']/a['size'],method='ART-74 fix-1 동일 색 마스크를 최종 픽셀에서 재계측; y48 절단 미접촉. 색 면적 지표이며 해부학 전체 크기 아님.')
            boxes=[a['box'],b['box'],z['box']];values=[a['size'],b['size'],z['size']]
        else:
            if cid=='C07':
                r=next(x for x in json.loads((ROOT/'reports/codex-art-83/measure-final/sizes-final.json').read_text('utf-8')) if x['monster']==mid and x['row']==row)
                oldbox=r['box'];idlebox=next(x for x in old74 if x['monster']==mid and x['row']=='idle')['after_box'];part=r['part'];idlepx=45
            else:
                r=next(x for x in old74 if x['monster']==mid and x['row']==row);oldbox=r['after_box'];idlebox=next(x for x in old74 if x['monster']==mid and x['row']=='idle')['after_box'];part=r['part'];idlepx=26
            ob=bef.getbbox();nb=aft.getbbox()
            sx=(nb[2]-nb[0])/(ob[2]-ob[0]);sy=(nb[3]-nb[1])/(ob[3]-ob[1])
            newbox=[round(nb[0]+(oldbox[0]-ob[0])*sx),round(nb[1]+(oldbox[1]-ob[1])*sy),round(nb[0]+(oldbox[2]-ob[0])*sx),round(nb[1]+(oldbox[3]-ob[1])*sy)]
            beforepx=oldbox[2]-oldbox[0];afterpx=newbox[2]-newbox[0]
            result=dict(id=cid,part=part,sample_frame=idx,idle=dict(size=idlepx,box=idlebox),before=dict(size=beforepx,box=oldbox),after=dict(size=afterpx,box=newbox),ratio=afterpx/idlepx,nominal_ratio_from_common_factor=beforepx*c['scale']/idlepx,method='이전 수동 경계를 같은 부위의 전체 프레임 축소/이동으로 추적하고 최종 픽셀 경계로 반올림. 4배 보드에서 위치 확인. 수동 경계 ±1px; 독립적인 해부학 크기 보장 아님.')
            boxes=[idlebox,oldbox,newbox];values=[idlepx,beforepx,afterpx]
        result['within_5_percent']=.95<=result['ratio']<=1.05
        result['factor_before']=next(x for x in json.loads((OUT/'baseline.json').read_text('utf-8'))['cases'] if x['id']==cid)['versions']['latest']['metadata']['factor']
        result['factor_after']=json.loads((OUT/'review-rows'/PathName(c['output'])).with_suffix('.json').read_text('utf-8'))['factor']
        result['output_sha256']=__import__('hashlib').sha256((OUT/'review-rows'/PathName(c['output'])).read_bytes()).hexdigest()
        board=Image.new('RGB',(1200,450),(24,29,40));d=ImageDraw.Draw(board)
        d.text((10,5),f'{cid} {mid} {row} | same part, 4x',font=FONT,fill='white')
        for j,(im,box,val) in enumerate(zip([anchor,bef,aft],boxes,values)):
            x=10+j*398;y=60;tile=Image.new('RGBA',(384,384),(39,44,56,255));tile.alpha_composite(im.resize((384,384),Image.Resampling.NEAREST));board.paste(tile.convert('RGB'),(x,y))
            d.rectangle((x+box[0]*4,y+box[1]*4,x+box[2]*4,y+box[3]*4),outline='#ffdb66',width=1)
            d.text((x,34),f'{["IDLE F1","BEFORE F"+str(idx),"AFTER F"+str(idx)][j]} size={val:.3f}',font=FONT,fill='white')
        board.save(OUT/f'{cid}-size-4x.png');results.append(result)
        print(cid,'ratio',result['ratio'],'pass',result['within_5_percent'],'after box',result['after']['box'])
    dump(OUT/'sizes.json',results)
def PathName(p):return p.split('/')[-1]
if __name__=='__main__':main()
