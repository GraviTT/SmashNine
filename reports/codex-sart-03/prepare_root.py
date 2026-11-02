"""Keep only image_gen's local paper edits; restore original pixels everywhere else."""
from pathlib import Path
from collections import deque
import argparse
import json
import hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from audit import ROOT, OUT, SRC, font, jpg

# Local source-image coordinates. Boxes bound a paper, not general background.
ROIS=[
 (195,381,306,507),(244,348,282,390),(284,372,333,431),
 (320,280,363,328),(351,333,401,393),(405,371,447,431),
 (433,380,482,468),(443,291,469,341),(496,283,529,328),
 (498,324,544,397),(540,293,569,330),(577,344,616,400),
 (563,410,627,515),(628,297,667,344),(680,280,715,326),
 (720,265,746,305),(767,258,803,301),(838,231,868,269),
 (350,462,395,511),(447,510,511,575),(835,485,895,553),
 (925,491,985,581),(1038,507,1108,616),(1068,437,1114,499),
 (947,439,991,494),(1169,423,1209,478),(1202,451,1249,503),
 (1244,414,1291,468),(1197,502,1254,580),(1239,494,1290,566),
 (1325,486,1376,537),(1332,547,1374,595),(1280,468,1322,509),
 (1418,439,1466,493),(1402,538,1526,650),(1182,558,1311,667),
 (1097,628,1157,674),(1125,406,1158,444),(865,252,889,279),
 (638,268,656,292),
]

def component(im, roi):
    a=np.asarray(im.crop(roi)).astype(np.int16);r,g,b=a[:,:,0],a[:,:,1],a[:,:,2]
    neutral=(r>85)&(g>80)&(b>70)&((b-r)<58)&((g-r)<37)&((r-g)<50)
    h,w=neutral.shape;seen=np.zeros((h,w),bool);comps=[]
    for y,x in np.argwhere(neutral):
        if seen[y,x]:continue
        seen[y,x]=True;q=deque([(int(x),int(y))]);pts=[]
        while q:
            xx,yy=q.popleft();pts.append((xx,yy))
            for nx,ny in [(xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)]:
                if 0<=nx<w and 0<=ny<h and neutral[ny,nx] and not seen[ny,nx]:
                    seen[ny,nx]=True;q.append((nx,ny))
        if len(pts)>=3:comps.append(pts)
    if not comps:return Image.new('L',(w,h)),{'pixels':0,'bbox':None}
    # Largest connected warm-neutral patch within each tightly bounded ROI.
    pts=max(comps,key=len)
    mask=Image.new('L',(w,h));d=ImageDraw.Draw(mask)
    for pt in pts:d.point(pt,fill=255)
    # Seal tiny surface cracks; fill enclosed red/black brush-mark holes.
    mask=mask.filter(ImageFilter.MaxFilter(3))
    padded=Image.new('L',(w+2,h+2));padded.paste(mask,(1,1))
    ImageDraw.floodfill(padded,(0,0),128)
    arr=np.asarray(padded)[1:-1,1:-1]
    mask=Image.fromarray(np.uint8(np.where(arr==128,0,255)))
    return mask,{'pixels':len(pts),'bbox':list(mask.getbbox()) if mask.getbbox() else None}

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--version',type=int,required=True);ap.add_argument('--raw-version',type=int);args=ap.parse_args();v=args.version
    raw_version=args.raw_version or v
    rawpath=ROOT/f'art/raw/story/cg_root-v{raw_version}_raw.png'
    dst=ROOT/f'art/bakeoff/story/cg_root-v{v}.png'
    assert not dst.exists(),dst
    original=Image.open(SRC/'cg_root.png').convert('RGB')
    raw=Image.open(rawpath).convert('RGB')
    edited=raw.resize(original.size,Image.Resampling.LANCZOS)
    seed=Image.new('L',original.size);records=[]
    active_rois=ROIS[:37] if v>=5 else ROIS
    for i,roi in enumerate(active_rois):
        base_mask,bm=component(original,roi);new_mask,nm=component(edited,roi)
        union=Image.fromarray(np.maximum(np.asarray(base_mask),np.asarray(new_mask)))
        seed.paste(union,(roi[0],roi[1]),union)
        records.append({'id':i+1,'roi_xyxy':list(roi),'original':bm,'generated':nm})
    # Original plus replacement silhouettes, with a 5px reconstruction margin and
    # a small feather. No entire rectangular patch is pasted into the scene.
    core=seed.filter(ImageFilter.MaxFilter(11))
    alpha=core.filter(ImageFilter.GaussianBlur(1.2))
    a=np.asarray(alpha).copy();a[a<2]=0;a[675:,:]=0
    alpha=Image.fromarray(a)
    out=Image.composite(edited,original,alpha)
    out.save(dst)
    mask=np.asarray(alpha)>0
    diff=np.abs(np.asarray(out,dtype=float)-np.asarray(original,dtype=float))
    rawdiff=np.abs(np.asarray(edited,dtype=float)-np.asarray(original,dtype=float))
    metrics={'size':list(out.size),'mode':out.mode,'opaque':True,
      'raw_size':list(raw.size),'processing':'full image LANCZOS resize to 1600x900, no crop; local paper-only composite onto original',
      'mask_pixels':int(mask.sum()),'mask_percent':round(float(mask.mean()*100),6),
      'outside_mask_pixels':int((~mask).sum()),'raw_outside_mask_rgb_MAE_0_255':round(float(rawdiff[~mask].mean()),6),
      'final_outside_mask_rgb_MAE_0_255':float(diff[~mask].mean()),'final_outside_mask_max_channel_difference':int(diff[~mask].max()),
      'final_inside_mask_rgb_MAE_0_255':round(float(diff[mask].mean()),6),'changed_pixel_percent':round(float((diff.max(axis=2)>0).mean()*100),6),
      'bottom_quarter_rgb_MAE_0_255':float(diff[675:].mean()),'paper_roi_count':len(active_rois)}
    assert metrics['final_outside_mask_rgb_MAE_0_255']==0
    assert metrics['bottom_quarter_rgb_MAE_0_255']==0
    alpha.save(OUT/f'cg-root-edit-alpha-v{v}.png')
    Image.fromarray(np.uint8(mask)*255).save(OUT/f'cg-root-paper-mask-v{v}.png')
    note={2:'첫 편집 후보. 동심원 표적을 긴 종이로 바꾸었으나 일부 붓획이 숫자 2/S처럼 읽힐 수 있어 미추천.',3:'열린 붓획 후보. 큰 반원이 C처럼 읽힐 여지가 있어 v4를 추가했다. 채택·게임 반영은 하지 않았다.',4:'비대칭 말림과 긴 마른 붓끝 후보. v5에서 부적이 아닌 작은 반짝임 3곳을 마스크에서 제외했다.',5:'권장 검토 후보. v4 생성 원본에서 부적 37곳만 합성했다. 숫자·문자처럼 보이는 획을 비대칭 마른 붓자국으로 줄였고, 마스크 밖과 하단 25%는 원본과 동일하다. 채택·게임 반영은 하지 않았다.'}[v]
    metadata={'task':'SART-03','status':'candidate','note_ko':note,'source':'smash-nine-prototype/assets/art/story/cg_root.png',
      'raw':rawpath.relative_to(ROOT).as_posix(),'raw_sha256':hashlib.sha256(rawpath.read_bytes()).hexdigest(),
      'mask':f'reports/codex-sart-03/cg-root-paper-mask-v{v}.png','edit_alpha':f'reports/codex-sart-03/cg-root-edit-alpha-v{v}.png',
      'metrics':metrics,'localization':{'roi_coordinates':'source 1600x900','silhouette_selection':'largest warm-neutral connected component in each paper ROI, fill mark holes','dilation_px':5,'feather_gaussian_sigma_px':1.2,'alpha_less_than_2_zeroed':True,'bottom_quarter_locked':True,'rois':records},
      'human_judgment_ko':'모든 부적의 붓획이 글자로 읽히지 않는지, 긴 종이 비례와 펄럭임, 부적 주변 복원 경계와 봉인 고리의 자연스러움을 판단해 주세요.'}
    dst.with_suffix('.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for label,size in [('full',(1600,900)),('1280',(1280,720))]:
        w,h=size;sheet=Image.new('RGB',(w*2,h+64),'#101827');d=ImageDraw.Draw(sheet)
        d.text((20,14),'기존 cg_root',font=font(26),fill='#f3cd7c')
        d.text((w+20,14),f'후보 cg_root-v{v} · 부적만 편집',font=font(26),fill='#9fd2ff')
        sheet.paste(original.resize(size,Image.Resampling.LANCZOS),(0,64));sheet.paste(out.resize(size,Image.Resampling.LANCZOS),(w,64))
        jpg(f'cg-root-compare-{label}-v{v}.jpg',sheet)
    crops=[(190,376,312,520),(1030,500,1118,625),(1392,525,1535,662)]
    sh=Image.new('RGB',(1320,960),'#101827');sd=ImageDraw.Draw(sh)
    for i,box in enumerate(crops):
        x=15+440*i
        for row,im in enumerate([original,out]):
            y=48+470*row;cr=im.crop(box);cr=cr.resize((cr.width*3,cr.height*3),Image.Resampling.NEAREST)
            sh.paste(cr,(x,y));sd.text((x,y-37),f'{"기존" if row==0 else "후보 v"+str(v)} / 부적 {i+1} / 3×',fill='white',font=font(24))
    jpg(f'cg-root-papers-3x-v{v}.jpg',sh)
    overview=original.resize((800,450),Image.Resampling.LANCZOS).convert('RGBA')
    tint=Image.new('RGBA',(1600,900),(255,83,150,0));tint.putalpha(Image.fromarray(np.uint8(mask)*150))
    ov=Image.alpha_composite(original.convert('RGBA'),tint).resize((800,450),Image.Resampling.LANCZOS)
    heat=np.minimum(diff.max(axis=2)*5,255).astype(np.uint8)
    him=Image.fromarray(np.stack([heat,np.zeros_like(heat),heat],axis=2)).resize((800,450),Image.Resampling.NEAREST)
    sh=Image.new('RGB',(1600,548),'#101827');sd=ImageDraw.Draw(sh);sh.paste(ov.convert('RGB'),(0,54));sh.paste(him,(800,54))
    sd.text((16,12),'분홍: 넉넉한 부적 마스크',fill='white',font=font(24));sd.text((816,12),'차이 ×5 (검정: 동일)',fill='white',font=font(24))
    sd.text((16,514),f"마스크 {metrics['mask_percent']:.2f}% · 바깥 MAE {metrics['final_outside_mask_rgb_MAE_0_255']:.6f}/255 · 하단 25% MAE 0",fill='#9fd2ff',font=font(22))
    jpg(f'cg-root-diff-mask-v{v}.jpg',sh)
    print(json.dumps(metrics,indent=2))

if __name__=='__main__':main()
