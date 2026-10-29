"""ART-84 Part 2. Pointwise monotone tone mapping, no spatial resampling.
Color-dependent eye protection is restricted to manually reviewed eye boxes.
All original line geometry and alpha are retained; masks alone are feathered.
"""
from build_hurt import *
from PIL import ImageFilter

EYES={
 'frey':[(116,99,133,112),(141,106,150,119)],
 'luna':[(117,87,136,103),(146,96,158,111)],
 'luna_brave':[(112,122,133,140),(141,130,156,146)],
 'yuki':[(103,96,122,111),(130,106,143,119)],
 'nova_male':[(102,103,123,119),(130,115,142,127)],
 'nova_female':[(102,102,124,119),(131,111,143,123)],
 'rio_male':[(118,98,138,111),(144,108,155,120)],
 'rio_female':[(142,101,155,114)]
}
CHEEKS={
 'frey':[(117,115),(133,116),(138,127),(126,134),(116,125)],
 'luna':[(119,109),(140,111),(146,120),(133,127),(120,120)],
 'luna_brave':[(116,144),(135,144),(145,156),(132,164),(118,157)],
 'yuki':[(104,113),(119,113),(127,123),(116,133),(104,125)],
 'nova_male':[(100,120),(119,125),(128,137),(117,143),(103,134)],
 'nova_female':[(99,120),(119,123),(128,134),(118,141),(104,133)],
 'rio_male':[(117,113),(132,113),(141,124),(132,133),(119,125)],
 'rio_female':[(116,115),(132,115),(140,125),(130,132),(117,124)]
}
GAINS=np.array([.52,.43,.60],dtype=np.float64)
POWER=.90

def poly_mask(points):
    im=Image.new('L',(256,256)); ImageDraw.Draw(im).polygon(points,fill=255); return np.array(im)>0

def masks(stem,rgb):
    region=Image.new('L',(256,256)); d=ImageDraw.Draw(region)
    for box in EYES[stem]: d.ellipse(box,fill=255)
    r,g,b=rgb.transpose(2,0,1)
    if stem in ['frey','rio_male','rio_female']:
        chroma=np.clip((g-r-7)/18,0,1)*np.clip((g-90)/50,0,1)
    elif stem in ['luna','yuki']:
        chroma=np.clip((b-r-15)/22,0,1)*np.clip((g-r-3)/15,0,1)*np.clip((b-90)/50,0,1)
    else:
        chroma=np.clip((b-g-13)/22,0,1)*np.clip((b-100)/55,0,1)
    core=chroma*(np.array(region)/255)
    # Only mask is blurred, never the image: no loss of texture or linework.
    soft=np.array(Image.fromarray(np.rint(core*255).astype('uint8')).filter(ImageFilter.GaussianBlur(.6)))/255
    protect=np.maximum(core,soft*.85)
    return protect, core>.65, poly_mask(CHEEKS[stem])

def transform(stem,im):
    a=np.array(im); rgb=a[:,:,:3].astype(float)
    protect,eye,face=masks(stem,rgb)
    base=255*GAINS*(rgb/255)**POWER
    # Rio's single visible eye gets exposure of its existing colored pixels,
    # preserving shape and iris lines rather than drawing a new halo/second eye.
    eye_target=rgb.copy()
    if stem=='rio_female':
        eye_target=255*(rgb/255)**.76
    out=base*(1-protect[:,:,None])+eye_target*protect[:,:,None]
    result=a.copy(); result[:,:,:3]=np.rint(np.clip(out,0,255)).astype('uint8')
    result[a[:,:,3]==0,:3]=0
    return Image.fromarray(result),protect,eye,face

def luminance(im): return np.array(im).astype(float)[:,:,:3]@np.array([.2126,.7152,.0722])

def contrast(im,eye,face):
    l=luminance(im); e=float(l[eye].mean()); f=float(l[face].mean())
    # Fixed source-space masks; report displayed-code luma, not physical radiance.
    small=im.resize((142,142),Image.Resampling.BILINEAR)
    ew=np.array(Image.fromarray(eye.astype('uint8')*255).resize((142,142),Image.Resampling.BOX))/255
    fw=np.array(Image.fromarray(face.astype('uint8')*255).resize((142,142),Image.Resampling.BOX))/255
    sl=luminance(small); se=float((sl*ew).sum()/ew.sum()); sf=float((sl*fw).sum()/fw.sum())
    return {'eye_luma':round(e,4),'face_luma':round(f,4),'eye_face_ratio':round(e/f,4),
            'dialogue_eye_luma':round(se,4),'dialogue_face_luma':round(sf,4),'dialogue_eye_face_ratio':round(se/sf,4)}

def detail_measure(before,after,protect):
    a=np.array(before); b=np.array(after); sel=(a[:,:,3]==255)&(protect<.01)
    # Count strong adjacent RGB edges that survive quantization (not a claim
    # that every one-level color distinction survives an 8-bit darkening).
    count=kept=0
    for axis in [0,1]:
        da=np.diff(a[:,:,:3].astype(float),axis=axis); db=np.diff(b[:,:,:3].astype(float),axis=axis)
        valid=(sel[:-1,:]&sel[1:,:]) if axis==0 else (sel[:,:-1]&sel[:,1:])
        strong=(np.max(np.abs(da),axis=2)>=12)&valid
        count+=int(strong.sum()); kept+=int((strong&(np.max(np.abs(db),axis=2)>=3)).sum())
    return {'strong_adjacent_edges':count,'surviving_edges_delta_ge3':kept,'edge_retention_percent':round(100*kept/count,3)}

def run(dest):
    dest.mkdir(exist_ok=False); records=[]
    for stem,cfg in old.FORMS.items():
        n=Image.open(RAW/f'{stem}-neutral.png').convert('RGBA'); v1=Image.open(RAW/f'{stem}-shadow-v1.png').convert('RGBA')
        out,protect,eye,face=transform(stem,v1)
        prior=json.loads((RAW/f'{stem}-shadow-v1.json').read_text(encoding='utf-8'))
        a=np.array(out); na=np.array(n)
        rec={'stem':stem,'expression':'shadow','inherited_generation_offset':prior['offset'],'additional_offset':[0,0],
             'alpha_changed_pixels':int(np.any(a[:,:,3]!=na[:,:,3])),
             'transparent_nonzero_rgb_pixels':int(np.any(a[:,:,:3]!=0,axis=2)[na[:,:,3]==0].sum()),
             'eye_sample_pixels':int(eye.sum()),'face_sample_pixels':int(face.sum()),
             'before':contrast(v1,eye,face),'after':contrast(out,eye,face),**detail_measure(v1,out,protect)}
        if stem=='yuki':
            # Hand-held talisman (upper right), separate from the eye sample.
            roi=poly_mask([(214,80),(228,78),(227,131),(215,136)])
            rec['talisman_luma_before']=round(float(luminance(v1)[roi].mean()),4)
            rec['talisman_luma_after']=round(float(luminance(out)[roi].mean()),4)
        records.append(rec)
        save(out,dest/f'{stem}-shadow.png')
        save(board(stem,'shadow',n,v1,out),dest/f'{stem}-shadow-board.png')
        save(Image.fromarray(np.rint(protect*255).astype('uint8')),dest/f'{stem}-eye-protect.png')
        roi=old.on_bg(v1); roi.paste((255,195,0),mask=Image.fromarray(face.astype('uint8')*120)); roi.paste((30,255,160),mask=Image.fromarray(eye.astype('uint8')*220))
        crop=cfg['crop']; w=(crop[2]-crop[0])*4; h=(crop[3]-crop[1])*4
        detail=Image.new('RGB',(w*3,h+40),'#151621')
        for i,(name,im) in enumerate([('v1 x4',old.on_bg(v1)),('v2 x4',old.on_bg(out)),('measurement ROI',roi)]):
            text(detail,(i*w+3,4),name,14); detail.paste(im.crop(crop).resize((w,h),Image.Resampling.NEAREST),(i*w,36))
        save(detail,dest/f'{stem}-shadow-detail.png')
    dump(dest/'measurements.json',records)
    dump(dest/'tone-config.json',{'gains':GAINS.tolist(),'power':POWER,'eye_boxes':EYES,'cheek_polygons':CHEEKS,'rio_female_eye_power':.76})
    for r in records: print(r['stem'],r['inherited_generation_offset'],r['before']['eye_face_ratio'],'->',r['after']['eye_face_ratio'],'small',r['before']['dialogue_eye_face_ratio'],'->',r['after']['dialogue_eye_face_ratio'])

if __name__=='__main__': run(RAW/'shadow-pass1')
