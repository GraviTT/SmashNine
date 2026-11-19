"""Build final QA boards and measurements from delivered PNGs (UTF-8)."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageFilter

ROOT=Path(__file__).resolve().parents[2]
R=ROOT/'reports/codex-art-95b'
RAW=ROOT/'art/raw/xion-95b'

def font(n):
    return ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)

def rgba(path): return Image.open(path).convert('RGBA')
def hsh(path): return hashlib.sha256(path.read_bytes()).hexdigest()

roster=[
 ('Xion E',ROOT/'art/bakeoff/xion/e/xion-idle-e.png'),
 ('Xion F',ROOT/'art/bakeoff/xion/f/xion-idle-f.png'),
 ('Frey',ROOT/'smash-nine-prototype/assets/art/frey/frey_sheet.png'),
 ('Rio female',ROOT/'smash-nine-prototype/assets/art/rio/rio_female_sheet.png'),
 ('Nova female',ROOT/'smash-nine-prototype/assets/art/nova/nova_female_sheet.png'),
 ('Luna',ROOT/'smash-nine-prototype/assets/art/luna/luna_sheet.png'),
]

def boards():
    W=2400
    board=Image.new('RGB',(W,1360),'#171b22');d=ImageDraw.Draw(board)
    d.text((28,18),'XION E / F  -  CURRENT ROSTER COMPARISON',font=font(28),fill='white')
    d.text((28,56),'One idle frame each. Same native pixel scale. Feet y=120. Nearest-neighbour enlargement.',font=font(18),fill='#aeb4bf')
    y=90
    for scale,bg in [(1,'#2a2d34'),(1,'#c8c4b8'),(3,'#2a2d34'),(3,'#c8c4b8')]:
        rh=128*scale+46
        d.rectangle((0,y,W,y+rh-1),fill=bg)
        fg='#f0efeb' if bg=='#2a2d34' else '#242933'
        d.text((8,y+6),str(scale)+'x',font=font(15),fill=fg)
        line_y=y+36+120*scale
        d.line((0,line_y,W,line_y),fill='#8a716a',width=1)
        for i,(name,path) in enumerate(roster):
            im=rgba(path).crop((0,0,128,128))
            im=im.resize((128*scale,128*scale),Image.Resampling.NEAREST)
            x=i*400+(400-im.width)//2
            d.text((i*400+55,y+7),name,font=font(20),fill=fg)
            board.paste(im,(x,y+36),im)
        y+=rh+8
    board.save(R/'lineup.png')

    # Two final single frames at exactly 4x, each against both QA backgrounds.
    b=Image.new('RGB',(1088,1128),'#171b22');dd=ImageDraw.Draw(b)
    for j,bg in enumerate(['#2a2d34','#c8c4b8']):
        for i,k in enumerate('ef'):
            tile=Image.new('RGBA',(512,512),bg)
            tile.alpha_composite(rgba(ROOT/f'art/bakeoff/xion/{k}/xion-idle-{k}.png').resize((512,512),Image.Resampling.NEAREST))
            x=16+i*544;y=40+j*552
            dd.text((x,y-28),f'Xion {k.upper()}  /  4x',font=font(20),fill='white')
            b.paste(tile.convert('RGB'),(x,y))
    b.save(R/'idle-review-4x.png')

    # Compact visual handoff; full-resolution QA files are also kept.
    p=Image.new('RGB',(1024,832),'#23262c');dp=ImageDraw.Draw(p)
    for i,(k,title) in enumerate([('e','E  CHRONO HUNTER'),('f','F  VOID HUNTRESS')]):
        im=rgba(ROOT/f'art/bakeoff/xion/{k}/xion_illustration-{k}.png').resize((512,768),Image.Resampling.LANCZOS)
        p.paste(im,(i*512,48),im);dp.text((i*512+22,15),title,font=font(24),fill='#eee9df')
    p.save(R/'concepts.png')

    h=Image.new('RGB',(1536,600),'#c8c4b8');hd=ImageDraw.Draw(h)
    for i,(name,path) in enumerate([roster[3],roster[0],roster[1]]):
        im=rgba(path).crop((32,16,96,80)).resize((512,512),Image.Resampling.NEAREST)
        h.paste(im,(i*512,40),im);hd.text((i*512+12,10),name,font=font(20),fill='black')
        for yy in range(16,80,4):
            y=40+(yy-16)*8
            hd.line((i*512,y,(i+1)*512-1,y),fill='#638d80')
            hd.text((i*512+2,y+1),str(yy),font=font(12),fill='black')
    h.save(R/'heads-grid-8x.png')

def statistics():
    result={'method':{
        'automated':'Pillow/NumPy image measurements; normalize.py metrics unchanged; human ROI alpha statistics',
        'manual':'Crown/chin landmarks selected by eye; uncertainty approximately +/-1 sprite px, +/-5 illustration px. Not an anatomical detector.',
        'detail':'normalize.py interior contrast metric, not a semantic detail/quality score',
        'fringe_proxy':'nonzero-alpha pixels farther than 2px from alpha >=32 support; does not prove all colour halos absent',
    },'concepts':{}}
    for k in 'ef':
        p=ROOT/f'art/bakeoff/xion/{k}/xion_illustration-{k}.png';a=np.array(rgba(p));al=a[:,:,3];rgb=a[:,:,:3].astype(np.int16)
        ys,xs=np.nonzero(al)
        near=np.array(Image.fromarray((al>=32).astype('uint8')*255).filter(ImageFilter.MaxFilter(5)))>0
        # Boxes are small, wholly interior, and independently recorded below.
        holo_boxes={'e':(285,545,300,560),'f':(300,540,315,555)}
        body_boxes={'e':(583,790,616,823),'f':(576,824,604,852)}
        def roi(box):
            x0,y0,x1,y1=box;q=al[y0:y1,x0:x1]
            return {'box':list(box),'min':int(q.min()),'median':float(np.median(q)),'max':int(q.max())}
        n=json.loads((R/f'normalize-{k}/metrics.json').read_text(encoding='utf-8'))
        s=rgba(ROOT/f'art/bakeoff/xion/{k}/xion-idle-{k}.png')
        src=rgba(R/f'normalize-{k}/frames/xion-idle-{k}-00.png')
        result['concepts'][k]={
          'illustration':{'file':p.relative_to(ROOT).as_posix(),'size':list(a.shape[1::-1]),'mode':'RGBA',
          'file_bytes':p.stat().st_size,'alpha_min':int(al.min()),'alpha_max':int(al.max()),
          'transparent_pixels':int((al==0).sum()),'partial_alpha_pixels':int(((al>0)&(al<255)).sum()),
          'opaque_pixels':int((al==255).sum()),'bbox':[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)],
          'border_nontransparent_pixels':int(np.count_nonzero(al[0])+np.count_nonzero(al[-1])+np.count_nonzero(al[:,0])+np.count_nonzero(al[:,-1])),
          'transparent_rgb_residue_pixels':int(((al==0)&np.any(rgb!=0,axis=2)).sum()),
          'green_fringe_pixels':int(((al>0)&(rgb[:,:,1]>rgb[:,:,0]+20)&(rgb[:,:,1]>rgb[:,:,2]+20)).sum()),
          'weak_alpha_beyond_2px_support':int(((al>0)&(~near)).sum()),
          'hologram_sample':roi(holo_boxes[k]),'main_sample':roi(body_boxes[k]),
          'main_hair_to_boots_manual_height_target_px':1267,'main_manual_canvas_fraction':1267/1536,
          },
          'sprite':{'size':list(s.size),'mode':s.mode,'file_bytes':(ROOT/f'art/bakeoff/xion/{k}/xion-idle-{k}.png').stat().st_size,
          'normalizer_frame_identical':bool(np.array_equal(np.array(s),np.array(src))),
          **n['summary'],'frame':n['frames'][0],
          'detail_ratio_to_rio_frame1':round(n['summary']['interior_detail_mean']/n['reference']['frames'][0]['interior_detail'],4)},
        }
        skull_crown,chin,feet=(174,350,1467) if k=='e' else (43,258,1519)
        sprite_crown,sprite_chin=(34,63) if k=='e' else (33,63)
        result['concepts'][k]['manual_landmark_measurements']={
            'illustration_source':'art/raw/xion-95b/'+k+'-illustration-v2.png',
            'illustration_main_skull_crown_y':skull_crown,
            'illustration_main_chin_y':chin,'illustration_main_boot_y':feet,
            'illustration_heads_excluding_ponytail':round((feet-skull_crown)/(chin-skull_crown),2),
            'sprite_main_skull_crown_y':sprite_crown,'sprite_main_chin_y':sprite_chin,
            'sprite_main_head_height_px':sprite_chin-sprite_crown,
            'sprite_heads_excluding_ponytail':round((120-sprite_crown)/(sprite_chin-sprite_crown),2),
            'rio_comparison_crown_chin_y':[33,61],'rio_comparison_head_height_px':28,
            'sprite_head_ratio_to_rio':round((sprite_chin-sprite_crown)/28,3),
            'uncertainty':'sprite +/-2px; illustration +/-5px; manual visual landmark estimates, not automatic detection',
        }
    (R/'metrics.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    sources=[]
    for p in sorted(RAW.glob('*.png')):
        sources.append({'file':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':hsh(p),'size':list(Image.open(p).size)})
    calls=[]
    for k in 'ef':
        calls.append({'output':k+'-illustration-v1.png','prompt':'prompt-'+k+'-illustration.txt','references':[],'transparent_background':True})
        calls.append({'output':k+'-illustration-v2.png','prompt':'prompt-'+k+'-illustration-fix.txt','references':[k+'-illustration-v1.png'],'transparent_background':True})
        for version in range(1,4 if k=='e' else 3):
            calls.append({'output':k+'-idle-v'+str(version)+'.png','prompt':'prompt-'+k+'-idle-v'+str(version)+'.txt',
                'references':['rio-female-idle-1-4x.png',k+'-illustration-v'+('2' if k=='e' else '1')+'.png'],'transparent_background':False})
    (R/'provenance.json').write_text(json.dumps({'generator':'built-in image_gen','raw_images':sources,'generation_calls':calls,'selected':{'e_illustration':'e-illustration-v2.png','f_illustration':'f-illustration-v2.png','e_idle':'e-idle-v3.png','f_idle':'f-idle-v2.png'}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps({k:{'illustration':v['illustration'],'sprite_summary':{x:v['sprite'][x] for x in ['common_scale','body_height_range','interior_detail_ratio','detail_ratio_to_rio_frame1','normalizer_frame_identical']}} for k,v in result['concepts'].items()},indent=2))

if __name__=='__main__':
    boards();statistics()
