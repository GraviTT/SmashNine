"""Final shadow pass: tighter violet-eye chroma mask avoids pale skin rings."""
import build_shadows as base
from build_shadows import *

EYE_POWERS={'frey':1.,'luna':.85,'luna_brave':.75,'yuki':.65,'nova_male':.85,'nova_female':.85,'rio_male':.90,'rio_female':.55}
original_masks=base.masks

def selected_masks(stem,rgb):
    protect,eye,face=original_masks(stem,rgb)
    if stem not in ['luna_brave','nova_male','nova_female']: return protect,eye,face
    region=Image.new('L',(256,256)); d=ImageDraw.Draw(region)
    for box in EYES[stem]: d.ellipse(box,fill=255)
    r,g,b=rgb.transpose(2,0,1)
    chroma=np.clip((b-g-35)/25,0,1)*np.clip((b-145)/45,0,1)
    bright=np.clip((rgb.min(axis=2)-205)/25,0,1)
    core=np.maximum(chroma,bright)*(np.array(region)/255)
    soft=np.array(Image.fromarray(np.rint(core*255).astype('uint8')).filter(ImageFilter.GaussianBlur(.55)))/255
    return np.maximum(core,soft*.8),core>.65,face

def selected_transform(stem,im):
    a=np.array(im); rgb=a[:,:,:3].astype(float)
    protect,eye,face=selected_masks(stem,rgb)
    dark=255*GAINS*(rgb/255)**POWER
    light=255*(rgb/255)**EYE_POWERS[stem]
    out=a.copy(); out[:,:,:3]=np.rint(dark*(1-protect[:,:,None])+light*protect[:,:,None]).clip(0,255).astype('uint8')
    out[a[:,:,3]==0,:3]=0
    return Image.fromarray(out),protect,eye,face

if __name__=='__main__':
    base.transform=selected_transform
    base.run(RAW/'shadow-selected')
    dump(RAW/'shadow-selected'/'selected-tone-config.json',{
        'gains':GAINS.tolist(),'power':POWER,'eye_powers':EYE_POWERS,
        'eye_boxes':EYES,'cheek_polygons':CHEEKS,
        'violet_chroma':'clip((B-G-35)/25)*clip((B-145)/45)',
        'violet_bright':'clip((min(R,G,B)-205)/25)',
        'violet_mask_blur':.55,'violet_blur_gain':.8,
        'all_curves':'strictly monotone in float; 8-bit quantization can merge one-level differences; no spatial image blur, no clipping, no silhouette change'})
