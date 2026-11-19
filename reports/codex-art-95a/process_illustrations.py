from pathlib import Path
from collections import deque
import json
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/raw/xion-95a'
REPORT = ROOT / 'reports/codex-art-95a'

def components(mask, minimum):
    seen = np.zeros(mask.shape, bool)
    result = np.zeros(mask.shape, bool)
    h, w = mask.shape
    sizes = []
    for y, x in zip(*np.where(mask)):
        if seen[y,x]: continue
        seen[y,x] = True
        q = deque([(int(y),int(x))]); points=[]
        while q:
            cy,cx=q.popleft();points.append((cy,cx))
            for ny,nx in ((cy-1,cx),(cy+1,cx),(cy,cx-1),(cy,cx+1)):
                if 0 <= ny < h and 0 <= nx < w and mask[ny,nx] and not seen[ny,nx]:
                    seen[ny,nx]=True;q.append((ny,nx))
        if len(points)>=minimum:
            yy,xx=zip(*points);result[yy,xx]=True;sizes.append(len(points))
    return result,sizes

def process(letter):
    source=Image.open(RAW/(f'{letter}-illustration-chroma.png' if letter=='c' else 'd-illustration-proportion.png')).convert('RGBA')
    rgba=np.array(source);rgb=rgba[:,:,:3].astype(float)
    r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    # Chroma coverage, followed by edge decontamination. No character repainting.
    excess=np.maximum(g-np.maximum(r,b),0)
    alpha=np.clip(1-excess/240,0,1)
    alpha[alpha<0.06]=0;alpha[alpha>0.96]=1
    alpha[(g>r+45)&(g>b+45)&(g>100)]=0
    safe=np.maximum(alpha,0.01)
    clean=(rgb-(1-alpha[:,:,None])*np.array([0.,255.,0.]))/safe[:,:,None]
    clean=np.clip(clean,0,255)
    clean[:,:,1]=np.minimum(clean[:,:,1],np.maximum(clean[:,:,0],clean[:,:,2]))
    near_key=np.array(Image.fromarray(((alpha==0)*255).astype('uint8')).filter(ImageFilter.MaxFilter(7)))>0
    yellow_green_edge=near_key&(alpha>0)&(g>=r-4)&(g>b+15)
    clean[:,:,1][yellow_green_edge]=(clean[:,:,0][yellow_green_edge]+clean[:,:,2][yellow_green_edge])/2
    rgba[:,:,:3]=np.rint(clean).astype('uint8');rgba[:,:,3]=np.rint(alpha*255).astype('uint8')
    rr,gg,bb=clean[:,:,0],clean[:,:,1],clean[:,:,2]
    red=(rr>1.9*gg+4)&(rr>1.45*bb+6)&(rr>45)&(alpha>0)
    yy,xx=np.indices(red.shape)
    if letter=='c':
        roi=xx<550
    else:
        red=(rr>2.6*gg+10)&(rr>1.8*bb+10)&(rr>45)&(alpha>0)
        # Manual spatial gate along the main figure's left outline; colour is
        # still required, so this is not a silhouette drawn into the artwork.
        points=[(0,490),(285,490),(310,445),(350,428),(405,407),(435,375),
                (458,351),(488,378),(518,360),(550,360),(580,377),(603,408),
                (623,461),(651,440),(687,396),(723,360),(760,323),(800,292),
                (840,272),(880,251),(925,226),(970,187),(1018,146),(1050,105),(1535,0)]
        limit=np.interp(yy[:,0],[p[0] for p in points],[p[1] for p in points])
        roi=xx<limit[:,None]+3
    red &= roi
    chosen,sizes=components(red,1200)
    # Close scanline gaps and include the narrow dark outline of the selected
    # large crimson regions. Separate small crimson stitches are excluded.
    mask=Image.fromarray((chosen*255).astype('uint8')).filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(7)).filter(ImageFilter.MaxFilter(3))
    m=(np.array(mask)>0)&roi&(alpha>0)
    # Retain near-black contour inside the same crimson region.
    mask=Image.fromarray((m*255).astype('uint8'))
    mask.save(RAW/f'{letter}-hologram-mask.png')
    front=rgba.copy();front[m]=0
    holo=rgba.copy();holo[~m]=0
    holo[:,:,3]=np.rint(holo[:,:,3].astype(float)*0.55).astype('uint8')
    # Two actual 3px slices on the hologram only, +/-4px; no front-body effects.
    for y,shift in ((392,4),(735,-4)):
        strip=holo[y:y+3].copy();holo[y:y+3]=0
        if shift>0: holo[y:y+3,shift:]=strip[:,:-shift]
        else: holo[y:y+3,:shift]=strip[:,-shift:]
    front_im=Image.fromarray(front);holo_im=Image.fromarray(holo)
    full=Image.alpha_composite(holo_im,front_im)
    # Use a single uniform factor for both figures; 1400px input main height -> 1260px.
    scale=0.9;dest=(1024,1536);size=(round(1024*scale),round(1536*scale))
    offset=((dest[0]-size[0])//2,(dest[1]-size[1])//2)
    final=Image.new('RGBA',dest)
    final.alpha_composite(full.resize(size,Image.Resampling.LANCZOS),offset)
    out=np.array(final);out[out[:,:,3]<=2]=0
    out[:,:,1]=np.minimum(out[:,:,1],np.maximum(out[:,:,0],out[:,:,2]))
    final=Image.fromarray(out)
    final.save(ROOT/f'art/bakeoff/xion/{letter}/xion_illustration-{letter}.png')
    front_im.save(RAW/f'{letter}-front-only.png')
    for name,bg in [('dark','#2a2d34'),('light','#c8c4b8')]:
        Image.alpha_composite(Image.new('RGBA',dest,bg),final).convert('RGB').save(REPORT/f'illustration-{letter}-{name}.png')
    a=out[:,:,3];visible=a>0
    bbox=final.getbbox()
    report={'size':list(final.size),'mode':final.mode,'uniform_factor':scale,'bbox':list(bbox),
      'margin_ltrb':[bbox[0],bbox[1],1024-bbox[2],1536-bbox[3]],
      'alpha_range':[int(a.min()),int(a.max())], 'opaque_pixels':int((a==255).sum()),
      'partial_alpha_pixels':int(((a>0)&(a<255)).sum()),'transparent_pixels':int((a==0).sum()),
      'hologram_core_alpha':140,'hologram_opacity':140/255,
      'hologram_mask_pixels_source':int(m.sum()),'selected_crimson_components':sizes,
      'yellow_green_edge_despill_pixels':int(yellow_green_edge.sum()),
      'glitch_slices_source':[[392,395,4],[735,738,-4]],
      'green_spill_pixels':int((visible&(out[:,:,1].astype(int)>out[:,:,0].astype(int)+12)&(out[:,:,1].astype(int)>out[:,:,2].astype(int)+12)).sum()),
      'transparent_rgb_nonzero':int(((a==0)&np.any(out[:,:,:3]!=0,axis=2)).sum()),
      'edge_pixels':int(visible[0].sum()+visible[-1].sum()+visible[:,0].sum()+visible[:,-1].sum()),
      'processing':'ImageGen chroma source; green-key coverage/despill, selected large crimson regions alpha 55%, two 3px +/-4px slices, uniform 0.9 scale. No body part collage.'}
    return report

if __name__=='__main__':
    result={c:process(c) for c in 'cd'}
    (REPORT/'illustration-metrics.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2))
