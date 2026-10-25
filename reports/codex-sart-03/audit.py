"""Read-only ART-70 pixel audit. Writes only this report directory; no Godot."""
from pathlib import Path
import hashlib
import json
from datetime import datetime
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
SRC = ROOT / 'smash-nine-prototype/assets/art/story'
FONT = ROOT / 'smash-nine-prototype/assets/fonts/NotoSansKR-UI.ttf'
INK = np.array([16, 24, 39], dtype=np.float64)
NAMES = ['cg_prologue.png', 'cg_root.png', 'cg_epilogue.png',
         'dialogue_frame.png', 'name_plate.png', 'shadow_aura.png']

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def font(size):
    return ImageFont.truetype(str(FONT), size)

def save_json(name, obj):
    path = OUT / name
    if path.exists():
        raise FileExistsError(path)
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def jpg(name, im):
    path = OUT / name
    if path.exists():
        raise FileExistsError(path)
    im.convert('RGB').save(path, quality=90, subsampling=0, optimize=True)
    assert path.stat().st_size <= 2_000_000, (path, path.stat().st_size)

def stats(rgb):
    a = np.asarray(rgb, dtype=np.float64)
    hi, lo = a.max(axis=2), a.min(axis=2)
    saturation = np.divide(hi-lo, hi, out=np.zeros_like(hi), where=hi>0)
    brightness = a @ np.array([0.2126, 0.7152, 0.0722])
    return {'mean_brightness_Yprime_0_255': round(float(brightness.mean()),4),
            'mean_HSV_saturation_percent': round(float(saturation.mean()*100),4),
            'mean_HSV_value_0_255': round(float(hi.mean()),4)}

def lum(a):
    a = np.asarray(a, dtype=float)/255
    linear = np.where(a <= .04045, a/12.92, ((a+.055)/1.055)**2.4)
    return linear @ np.array([.2126,.7152,.0722])

def contrast(rgb):
    backing = .95*INK + .05*np.asarray(rgb, dtype=np.float64)
    ratios = 1.05/(lum(backing)+.05)
    mask = Image.new('L', rgb.size)
    d = ImageDraw.Draw(mask)
    for y in [18,65,112]:
        d.text((40,y), '스테이지 3  달빛 다리  봉인의 빛을 따라가세요.', fill=255, font=font(24))
    core = np.asarray(mask)>=250
    core_ratios = ratios[core]
    return {'backing_hex':'#101827','backing_alpha':.95,'text_hex':'#ffffff','font_px':24,
            'min_ratio':round(float(ratios.min()),4),'mean_ratio':round(float(ratios.mean()),4),
            'p05_ratio':round(float(np.percentile(ratios,5)),4),'median_ratio':round(float(np.median(ratios)),4),
            'sample_glyph_core_min_ratio':round(float(core_ratios.min()),4),
            'sample_glyph_core_mean_ratio':round(float(core_ratios.mean()),4),
            'method':'sRGB source-over model, then linear-sRGB relative luminance; UI 1280x720 bottom quarter; not a Godot render; antialiased glyph fringe excluded'}

def nine_audit(im, margin):
    a = np.asarray(im.convert('RGBA'))
    c = a[margin:-margin,margin:-margin]
    centre_alpha = c[:,:,3]
    top = a[:margin,margin:-margin]
    bot = a[-margin:,margin:-margin]
    left = a[margin:-margin,:margin]
    right = a[margin:-margin,-margin:]
    return {'size':list(im.size),'mode':im.mode,'margin_px':margin,
            'centre_alpha_unique':np.unique(centre_alpha).tolist(),
            'centre_fully_transparent':bool(np.all(centre_alpha==0)),
            'opaque_pixels_outside_margins':int(np.count_nonzero(centre_alpha==255)),
            'nonzero_alpha_pixels_outside_margins':int(np.count_nonzero(centre_alpha>0)),
            'centre_rgba_unique_count':int(np.unique(c.reshape(-1,4),axis=0).shape[0]),
            'horizontal_top_repeatable':bool(np.all(top==top[:,0:1])),
            'horizontal_bottom_repeatable':bool(np.all(bot==bot[:,0:1])),
            'vertical_left_repeatable':bool(np.all(left==left[0:1,:])),
            'vertical_right_repeatable':bool(np.all(right==right[0:1,:]))}

def checker(size, cell=12):
    im=Image.new('RGBA', size, (45,54,68,255)); d=ImageDraw.Draw(im)
    for y in range(0,size[1],cell):
        for x in range(0,size[0],cell):
            if (x//cell+y//cell)%2:
                d.rectangle((x,y,x+cell-1,y+cell-1),fill=(71,80,94,255))
    return im

def main():
    audit={'timestamp_local':datetime.now().isoformat(timespec='seconds'),
           'sources':{n:{'sha256':sha(SRC/n),'bytes':(SRC/n).stat().st_size} for n in NAMES},
           'brightness_definition':'Rec.709 luma of stored sRGB samples: 0.2126R+0.7152G+0.0722B (0..255), not linear luminance',
           'saturation_definition':'mean HSV S=(maxRGB-minRGB)/maxRGB, 0 for black, percent',
           'scenes':{},'ui':{},'aura':{}}
    scene_sheet=Image.new('RGB',(1920,840),'#101827'); sd=ImageDraw.Draw(scene_sheet)
    for i,name in enumerate(NAMES[:3]):
        im=Image.open(SRC/name).convert('RGB')
        bottom=im.crop((0,675,1600,900))
        ui=im.resize((1280,720),Image.Resampling.LANCZOS)
        ui_bottom=ui.crop((0,540,1280,720))
        m={'size':list(im.size),'mode':im.mode,'whole':stats(im),'bottom_quarter':stats(bottom),'white_text_contrast':contrast(ui_bottom)}
        audit['scenes'][name]=m
        x=i*640
        sd.text((x+18,12),name,fill='#f3cd7c',font=font(24))
        scene_sheet.paste(im.resize((640,360),Image.Resampling.LANCZOS),(x,56))
        sd.line((x,326,x+639,326),fill='#f3cd7c',width=1)
        sd.text((x+18,432),'하단 25% / 원본',fill='white',font=font(22))
        scene_sheet.paste(bottom.resize((640,90),Image.Resampling.LANCZOS),(x,468))
        sd.text((x+18,578),'배경 α0.95 + 흰 글자 24px / Pillow 검토',fill='white',font=font(22))
        preview=Image.fromarray(np.uint8(np.round(.95*INK+.05*np.asarray(ui_bottom))))
        preview=preview.crop((0,0,640,180))
        pd=ImageDraw.Draw(preview)
        pd.text((26,40),'스테이지 3  달빛 다리',fill='white',font=font(24))
        pd.text((26,84),'봉인의 빛을 따라가세요.',fill='white',font=font(24))
        scene_sheet.paste(preview,(x,620))
        sd.text((x+18,804),f"최소 대비 {m['white_text_contrast']['min_ratio']:.2f}:1",fill='#9fd2ff',font=font(22))
    jpg('art70-scenes-audit-v1.jpg',scene_sheet)
    for name,margin in [('dialogue_frame.png',24),('name_plate.png',12)]:
        audit['ui'][name]=nine_audit(Image.open(SRC/name),margin)
    ui_sheet=Image.new('RGB',(1100,520),'#101827'); ud=ImageDraw.Draw(ui_sheet)
    ud.text((24,16),'ART-70 프레임 / 이름판  —  수정 없는 픽셀 감사',fill='white',font=font(26))
    for name,pos,scale,margin in [('dialogue_frame.png',(24,72),2,24),('name_plate.png',(24,368),3,12)]:
        im=Image.open(SRC/name).convert('RGBA'); bg=checker(im.size);bg.alpha_composite(im)
        bg=bg.resize((im.width*scale,im.height*scale),Image.Resampling.NEAREST)
        bd=ImageDraw.Draw(bg)
        for x in [margin*scale,(im.width-margin)*scale]:bd.line((x,0,x,bg.height-1),fill='#ff80bd')
        for y in [margin*scale,(im.height-margin)*scale]:bd.line((0,y,bg.width-1,y),fill='#ff80bd')
        ui_sheet.paste(bg.convert('RGB'),pos)
    ud.text((24,320),'대화 틀 2× · 중앙 α0 · 분홍 선=24px 경계',fill='#9fd2ff',font=font(22))
    ud.text((620,400),'이름판 3× / 경계 12px\n중앙 α235 (의도된 채움)',fill='#9fd2ff',font=font(22))
    jpg('art70-ui-audit-v1.jpg',ui_sheet)
    aura=Image.open(SRC/'shadow_aura.png').convert('RGBA'); frames=[];cells=[]
    for i in range(6):
        frame=aura.crop((128*i,0,128*(i+1),176));a=np.asarray(frame,dtype=float)
        bb=frame.getchannel('A').getbbox()
        edges=[bb[0],bb[1],128-bb[2],176-bb[3]]
        pm=a.copy();pm[:,:,:3]*=a[:,:,3:4]/255;frames.append(pm)
        cells.append({'frame':i+1,'alpha_bbox_xyxy_exclusive':list(bb),'empty_LTRB_px':edges,
                      'at_least_4px_empty_each_side':min(edges)>=4,'bottom_exclusive_y':bb[3],
                      'pixels_at_or_below_y160':int(np.count_nonzero(a[160:,:,3])),
                      'row_159_nonzero_pixels':int(np.count_nonzero(a[159,:,3]))})
    diffs=[float(np.abs(frames[(i+1)%6]-frames[i]).mean()) for i in range(6)]
    audit['aura']={'size':list(aura.size),'mode':aura.mode,'cell_size':[128,176],'cells':cells,
                   'transition_premultiplied_RGBA_MAE_0_255':[round(v,6) for v in diffs],
                   'seam_6_to_1':round(diffs[-1],6),'ordinary_transition_median':round(float(np.median(diffs[:5])),6),
                   'seam_over_ordinary_median':round(diffs[-1]/float(np.median(diffs[:5])),6),
                   'feet_line_note':'PNG has no pivot metadata; bottom-exclusive bbox y ranges 155..160, with no visible pixels at/below y160. This is consistent with the documented lower-envelope baseline, but runtime placement is not verified.'}
    aa=checker(aura.size);aa.alpha_composite(aura);aa=aa.resize((1536,352),Image.Resampling.NEAREST)
    ad=ImageDraw.Draw(aa)
    for i in range(6):
        x=i*256;ad.rectangle((x+8,8,x+247,343),outline='#7cddaf');ad.line((x,320,x+255,320),fill='#ff80bd',width=2)
        ad.line((x+128,0,x+128,351),fill='#8093b5')
    ash=Image.new('RGB',(1584,480),'#101827');asd=ImageDraw.Draw(ash)
    asd.text((24,12),'shadow_aura · 6프레임 2× · 초록=4px 여백 · 분홍=발선 y160',fill='white',font=font(24))
    ash.paste(aa.convert('RGB'),(24,64));asd.text((24,432),f'6→1 MAE {diffs[-1]:.4f}/255 · 일반 전환 중앙값 대비 {diffs[-1]/np.median(diffs[:5]):.4f}배 · 시간감은 사람 판단',fill='#9fd2ff',font=font(22))
    jpg('art70-aura-audit-v1.jpg',ash)
    save_json('audit-v1.json',audit)
    print(json.dumps(audit,ensure_ascii=False,indent=2))

if __name__=='__main__':main()
