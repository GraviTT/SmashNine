"""Retain only the connected eye-light components, removing tiny skin flecks.
This changes protection masks only. Source image details are never painted.
"""
import build_shadows as base
import build_shadows_selected as selected
from build_shadows_selected import *

def final_masks(stem,rgb):
    protect,eye,face=selected.selected_masks(stem,rgb)
    if stem not in ['luna_brave','nova_male','nova_female']: return protect,eye,face
    # Threshold before a tiny mask feather. Eight-connected islands <=4 pixels
    # are skin/hair glints outside the two principal eye components.
    active=protect>.12; visited=np.zeros(active.shape,dtype=bool); keep=np.zeros_like(active)
    for sy,sx in zip(*np.where(active)):
        if visited[sy,sx]: continue
        stack=[(sy,sx)]; visited[sy,sx]=True; points=[]
        while stack:
            y,x=stack.pop(); points.append((y,x))
            for dy in [-1,0,1]:
                for dx in [-1,0,1]:
                    yy,xx=y+dy,x+dx
                    if 0<=yy<256 and 0<=xx<256 and active[yy,xx] and not visited[yy,xx]:
                        visited[yy,xx]=True; stack.append((yy,xx))
        if len(points)>=5:
            for y,x in points: keep[y,x]=True
    envelope=np.array(Image.fromarray(keep.astype('uint8')*255).filter(ImageFilter.MaxFilter(3)))/255
    return protect*envelope,eye&keep,face

def final_transform(stem,im):
    a=np.array(im); rgb=a[:,:,:3].astype(float)
    protect,eye,face=final_masks(stem,rgb)
    dark=255*GAINS*(rgb/255)**POWER
    light=255*(rgb/255)**EYE_POWERS[stem]
    out=a.copy(); out[:,:,:3]=np.rint(dark*(1-protect[:,:,None])+light*protect[:,:,None]).clip(0,255).astype('uint8')
    out[a[:,:,3]==0,:3]=0
    return Image.fromarray(out),protect,eye,face

if __name__=='__main__':
    base.transform=final_transform
    base.run(RAW/'shadow-final')
    dump(RAW/'shadow-final'/'final-tone-config.json',{
        'gains':GAINS.tolist(),'power':POWER,'eye_powers':EYE_POWERS,
        'eye_boxes':EYES,'cheek_polygons':CHEEKS,
        'violet_mask':'build_shadows_selected.selected_masks, followed by >=5-pixel 8-connected components at protection >0.12',
        'eye_sampling':'protection core >0.65 (before small-island cleanup); fixed v1-derived sample used for both images',
        'image_geometry':'identity; no translation, resampling, blur, dilation or repaint of source pixels',
        'quantization':'float curves monotone, final uint8 rounding; one-level distinctions may merge'})
