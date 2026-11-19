"""ART-95B deterministic delivery preparation; no drawing or part replacement.
Raw alpha matte cleanup, manually scoped crimson-double alpha, one whole-image
scale; normalizer's first 128px cell is copied without pixel changes.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/raw/xion-95b'
REPORT = ROOT / 'reports/codex-art-95b'

def poly_mask(size, points):
    im = Image.new('L', size)
    ImageDraw.Draw(im).polygon(points, fill=255)
    return np.array(im) > 0

# Hand-traced protection regions around FOREGROUND features. These only scope
# a crimson colour selector; they do not redraw, erase or paste any anatomy.
E_PROTECT = [(490,110),(570,110),(630,165),(690,210),(700,350),(780,530),
 (1024,650),(1024,1536),(240,1536),(250,1390),(265,1360),(265,1260),
 (280,1225),(300,1180),(320,1135),(338,1085),(353,1050),(370,1000),
 (385,960),(395,905),(405,850),(415,800),(427,755),(445,714),(456,697),
 (450,675),(428,668),(400,651),(376,633),(361,613),(357,595),(368,575),
 (381,551),(395,530),(406,512),(414,490),(400,486),(374,483),(350,460),
 (350,435),(365,396),(376,362),(383,329),(390,300),(401,260),(413,232),
 (415,210),(429,183),(449,158)]
# The exposed second hologram leg sits in the gap between the foreground legs.
E_SECOND_LEG = [(473,1000),(490,1035),(490,1110),(515,1190),(525,1260),
 (575,1340),(575,1395),(420,1395),(420,1180),(404,1110),(443,1040)]
F_PROTECT = [(480,0),(1024,0),(1024,1536),(245,1536),(245,1260),
 (210,1200),(190,1120),(198,1050),(219,970),(239,910),(260,855),
 (283,814),(67,850),(58,780),(205,700),(316,679),(334,617),(345,555),
 (332,490),(364,435),(389,390),(403,337),(428,289),(443,230)]

def process(letter):
    raw_name = f'{letter}-illustration-v2.png'
    im = Image.open(RAW/raw_name).convert('RGBA')
    a = np.array(im)
    rgb = a[:,:,:3].astype(np.int16)
    old_alpha = a[:,:,3].copy()
    # Built-in output uses 252/253 in opaque interiors. Restore matte to solid
    # and remove <=8 numerical residuals; retain normal anti-aliased edges.
    alpha = np.clip((old_alpha.astype(float)-8)*255/(248-8),0,255)
    if letter == 'e':
        protected = poly_mask(im.size,E_PROTECT)
        protected[poly_mask(im.size,E_SECOND_LEG)] = False
        # Gaps between foreground ponytail strands and along its bent leg.
        for pts in [
            [(0,0),(430,0),(430,285),(447,285),(437,320),(411,350),
             (392,370),(375,391),(360,420),(349,450),(352,480),(0,500)],
            [(0,720),(417,720),(398,790),(395,850),(389,900),(365,935),
             (372,950),(355,977),(364,995),(372,1013),(361,1035),(345,1045),(0,1110)],
        ]:
            protected[poly_mask(im.size,pts)] = False
    else:
        protected = poly_mask(im.size,F_PROTECT)
        for pts in [
            [(0,0),(460,0),(460,300),(425,400),(409,480),(390,550),
             (375,600),(330,660),(325,690),(0,750)],
            [(0,650),(360,650),(360,800),(328,800),(300,850),(272,900),
             (248,950),(225,1000),(210,1025),(224,1050),(221,1100),
             (219,1150),(208,1200),(202,1250),(270,1300),(270,1450),(0,1450)],
        ]:
            protected[poly_mask(im.size,pts)] = False
        # Protect the foreground shotgun, hands and crimson bindings.
        gun=[(65,779),(98,760),(129,754),(165,739),(190,727),(222,715),
             (244,700),(276,688),(297,691),(315,689),(329,677),(344,693),
             (360,700),(358,728),(351,745),(349,764),(341,784),(330,795),
             (310,781),(299,777),(282,781),(272,791),(241,804),(212,817),
             (176,828),(143,835),(118,846),(102,844),(84,828),(64,805)]
        protected[poly_mask(im.size,gun)] = True
    crimson = (rgb[:,:,0] > rgb[:,:,1]*1.42) & (rgb[:,:,0] > rgb[:,:,2]*1.22) & (rgb[:,:,0]-rgb[:,:,1]>16)
    holo = (~protected) & crimson & (alpha > 0)
    if letter == 'e':
        gap = poly_mask(im.size,[(330,380),(397,380),(412,500),(330,500)])
        # The ghost's scanlined red has more green/blue than opaque crimson hair.
        ghost_red = (rgb[:,:,1] > rgb[:,:,0]*.255) & (rgb[:,:,2] > rgb[:,:,0]*.30)
        holo |= gap & crimson & ghost_red & (alpha>0)
        gap = poly_mask(im.size,[(0,850),(395,850),(395,1040),(0,1040)])
        holo |= gap & crimson & (alpha>0)
    else:
        for pts in [
            [(115,835),(139,821),(176,810),(214,798),(252,781),(273,769),
             (291,767),(313,780),(329,791),(272,816),(200,846)],
            [(210,980),(270,950),(261,990),(251,1032),(238,1042),(230,1070),
             (226,1110),(221,1150),(214,1200),(203,1250),(190,1250),(200,1100)],
        ]:
            holo |= poly_mask(im.size,pts) & crimson & (alpha>0)
        # Updated F illustration: preserve the entire printed foreground cape,
        # including its crimson stars, while the double remains visible behind
        # the narrow split and to the right of the pointed lower cape tip.
        cape=[(259,900),(249,940),(248,961),(244,990),(237,1012),(229,1035),
              (225,1052),(223,1070),(217,1095),(213,1120),(207,1150),
              (202,1180),(201,1210),(202,1240),(210,1200),(225,1175),
              (241,1150),(257,1125),(274,1110),(299,1096),(320,1070),
              (400,1000),(400,900)]
        gap=poly_mask(im.size,[(180,1110),(275,1110),(275,1270),(180,1270)])
        holo |= gap & crimson & (alpha>0)
        holo[poly_mask(im.size,cape)]=False
    # Pale scanline highlights on the double's face must share its opacity.
    face_box = (210,280,354,398) if letter=='e' else (225,150,361,289)
    face_region = Image.new('L',im.size)
    ImageDraw.Draw(face_region).rectangle(face_box,fill=255)
    holo |= (np.array(face_region)>0) & (alpha>0)
    # 55% opacity for secondary figure, preserving generated scanlines and
    # edge alpha. Colour classification keeps dark foreground hair intact.
    alpha[holo] *= .55
    a[:,:,3] = np.rint(alpha).astype('uint8')
    a[a[:,:,3]==0,:3] = 0
    clean = Image.fromarray(a)
    # Main foreground top/feet landmarks include hair; 82.5% total canvas.
    landmarks = (117,1467) if letter=='e' else (12,1519)
    factor = 1267/(landmarks[1]-landmarks[0])
    w,h = round(1024*factor),round(1536*factor)
    scaled = clean.resize((w,h),Image.Resampling.LANCZOS)
    dest = Image.new('RGBA',(1024,1536))
    offset = ((1024-w)//2,round((1536-1267)/2-landmarks[0]*factor))
    dest.alpha_composite(scaled,offset)
    arr = np.array(dest)
    arr[arr[:,:,3]<=2] = 0
    support=np.array(Image.fromarray((arr[:,:,3]>=32).astype('uint8')*255).filter(ImageFilter.MaxFilter(5)))>0
    weak=(arr[:,:,3]>0)&(~support)
    weak_count=int(weak.sum())
    arr[weak]=0
    rgb_post=arr[:,:,:3].astype(np.int16)
    green=(arr[:,:,3]>0)&(rgb_post[:,:,1]>rgb_post[:,:,0]+20)&(rgb_post[:,:,1]>rgb_post[:,:,2]+20)
    green_count=int(green.sum())
    arr[:,:,1][green]=np.maximum(arr[:,:,0],arr[:,:,2])[green]
    arr[arr[:,:,3]==0,:3]=0
    dest = Image.fromarray(arr)
    out = ROOT/f'art/bakeoff/xion/{letter}/xion_illustration-{letter}.png'
    dest.save(out)
    for name,col in [('dark','#2a2d34'),('light','#c8c4b8')]:
        board=Image.new('RGBA',dest.size,col); board.alpha_composite(dest)
        board.convert('RGB').save(REPORT/f'{letter}-illustration-{name}.png')
    # Mask review: cyan identifies exactly the scoped secondary figure.
    mask_review=np.array(clean)
    mask_review[holo,:3]=[0,190,235]
    check=Image.new('RGBA',im.size,'#777777');check.alpha_composite(Image.fromarray(mask_review))
    check.convert('RGB').save(REPORT/f'{letter}-hologram-mask-review.png')
    source=REPORT/f'normalize-{letter}/frames/xion-idle-{letter}-00.png'
    sprite=Image.open(source).convert('RGBA')
    sprite.save(ROOT/f'art/bakeoff/xion/{letter}/xion-idle-{letter}.png')
    sprite.resize((512,512),Image.Resampling.NEAREST).save(REPORT/f'{letter}-idle-4x.png')
    note='현대 전술복과 시계 장식의 크로노 헌터. 대기 1프레임 후보.' if letter=='e' else '괴물 갑각과 갈라진 별무늬 망토의 공허 사냥꾼. 대기 1프레임 후보.'
    (ROOT/f'art/bakeoff/xion/{letter}/xion-idle-{letter}.json').write_text(json.dumps({'note':note,'frames':1},ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    return {'raw':str((RAW/raw_name).relative_to(ROOT)), 'alpha_cleanup':'map input alpha 8..248 to 0..255; <=2 after resize ->0; remove weak alpha >2px from alpha32 support; clamp isolated green fringe', 'weak_alpha_pixels_removed':weak_count,'green_fringe_pixels_corrected':green_count, 'hologram_target_alpha':.55,'hologram_selected_source_pixels':int(holo.sum()),'illustration_whole_image_scale':factor,'offset':list(offset),'main_source_manual_hair_to_boots':list(landmarks)}

if __name__=='__main__':
    records={k:process(k) for k in 'ef'}
    (REPORT/'processing.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps(records,ensure_ascii=False,indent=2))
