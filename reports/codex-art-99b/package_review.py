"""ART-99B comparison sheets and measured delivery manifest (no drawing)."""
import hashlib,json,sys
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
REP=ROOT/'reports/codex-art-99b'
RAW=ROOT/'art/raw/newchar-99b'
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
import normalize as norm

LOOKS=[
 ('doron',1,'도론 1 · 수집가','doron-1-idle-v1.png',(33,68,120),(145,338,1482),[(230,750,370,900),(520,410,650,590)],(170,1240,705,1500)),
 ('doron',2,'도론 2 · 성장형 슈트','doron-2-idle-v4.png',(33,67,120),(138,319,1456),[(215,690,340,850),(680,620,880,900)],(230,1220,770,1480)),
 ('doron',3,'도론 3 · 예비 조종사','doron-3-idle-v3.png',(33,70,120),(194,370,1464),[(315,645,445,775),(750,625,895,750)],(410,1245,850,1480)),
 ('jupi',2,'유피 2 · 천둥 연주자','jupi-2-idle-v2.png',(32,67,120),(236,428,1493),[(210,560,310,675),(755,500,915,600)],(320,1290,750,1510)),
 ('jupi',3,'유피 3 · 스파크 선수','jupi-3-idle-v5.png',(31,65,120),(225,401,1433),[(185,615,285,720),(675,745,760,865)],(265,1260,840,1450)),
]
def font(sz):return ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',sz)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def image_metrics(im):
    a=np.array(im.convert('RGBA')); alpha=a[:,:,3]; visible=alpha>0
    box=im.getchannel('A').getbbox(); x0,y0,x1,y1=box
    return {'size':list(im.size),'mode':im.mode,'alpha_min':int(alpha.min()),'alpha_max':int(alpha.max()),
      'alpha_unique_count':int(len(np.unique(alpha))),'bbox':list(box),'silhouette_height_px':y1-y0,
      'margins_ltrb':[x0,y0,im.width-x1,im.height-y1],
      'border_pixels':int(visible[0,:].sum()+visible[-1,:].sum()+visible[:,0].sum()+visible[:,-1].sum()),
      'transparent_rgb_nonzero_pixels':int(np.count_nonzero((alpha==0)&np.any(a[:,:,:3]!=0,axis=2))),
      'green_spill_pixels':norm.spill_pixel_count(im),'file_alpha_meaning':'transparent background, opaque subjects'}
def head_measure(points,uncertainty):
    crown,chin,feet=points; body=feet-crown+1; head=chin-crown+1
    return {'crown_y':crown,'chin_y':chin,'sole_y':feet,'body_height_px':body,'head_height_px':head,
      'heads':round(body/head,3),'landmark_uncertainty_px':uncertainty,
      'method':'manual landmarks; ratio calculated; not automatic anatomy detection'}

def main():
    assets=[]; metrics={'tool':'built-in image_gen','looks':{},'measurement_definitions':{
       'sprite_head':'Hair crown to chin, excluding Jupi ponytail and staff; inclusive pixel heights. Manual +/-1 px.',
       'illustration_head':'Estimated anatomical crown to chin, excluding loose hair spikes, goggles and ponytail. Manual +/-4 px.',
       'detail':'normalize.py interior_detail: mean absolute luminance Laplacian inside opaque cross-neighbours; contrast, not semantic quality.',
       'green_spill':'Opaque G > max(R,B)+20. Zero does not automatically prove absence of all other fringe colours.',
       'body_vs_silhouette':'For Jupi, normalizer body_height includes the staff. Report body height separately from manual head crown.',
    }}
    concepts=Image.new('RGBA',(2080,1050),'#2a2d34'); cd=ImageDraw.Draw(concepts)
    cd.text((26,10),'ART-99B · 외형 후보 / 게임 미적용',font=font(31),fill='#f4f2e9')
    faces=Image.new('RGBA',(1280,300),'#c8c4b8'); fd=ImageDraw.Draw(faces)
    for i,(c,n,label,source,spoints,ipoints,hands,feetbox) in enumerate(LOOKS):
        out=ROOT/f'art/bakeoff/newchar-2026-11-26/{c}/{n}'
        ip=out/f'{c}_illustration-{n}.png'; sp=out/f'{c}-idle-{n}.png'; fp=out/f'{c}_face-{n}.png'
        ill=Image.open(ip).convert('RGBA'); spr=Image.open(sp).convert('RGBA'); face=Image.open(fp).convert('RGBA')
        nm=json.loads((REP/f'normalize-{c}-{n}/metrics.json').read_text(encoding='utf-8'))
        metrics['looks'][f'{c}-{n}']={'label':label,'delivered':True,'illustration':image_metrics(ill),'face':image_metrics(face),
           'sprite':{**image_metrics(spr),'factor':nm['summary']['common_scale'],
           'detail':nm['summary']['interior_detail_mean'],'reference_detail':nm['summary']['reference_interior_detail_mean'],
           'detail_ratio_percent':round(nm['summary']['interior_detail_ratio']*100,2),
           'reference':nm['reference'],'binary_alpha':nm['summary']['alpha_binary'],'feet_y':nm['frames'][0]['bottom'],
           'margin4':nm['summary']['all_have_4px_margin'],'normalizer_output_equals_final':Image.open(next((REP/f'normalize-{c}-{n}/frames').glob('*.png'))).tobytes()==spr.tobytes()},
           'manual_sprite':head_measure(spoints,1),'manual_illustration':head_measure(ipoints,4),
           'selected_raw':{'illustration':f'{c}-{n}-illustration-green.png','idle':source},
           'files':[{'path':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in [ip,fp,sp,sp.with_suffix('.json')]],
           'visual_review':{'illustration_full_size':True,'sprite_nearest_4x':True,'hands_and_grips':True,'feet_and_complete_props':True,
             'limitation':'Occluded fingers cannot all be counted. Tiny fingers/remote/drum lacing are not individually readable at 1x.'}}
        assets += [(label,spr)]
        x=i*416
        cd.text((x+20,57),label,font=font(21),fill='#ffdd65')
        concepts.alpha_composite(ill.resize((384,576),Image.Resampling.LANCZOS),(x+16,94))
        cd.text((x+20,698),'얼굴 96px / 대기 2×',font=font(17),fill='#d2d2d2')
        concepts.alpha_composite(face.resize((96,96),Image.Resampling.LANCZOS),(x+16,754))
        concepts.alpha_composite(spr.resize((256,256),Image.Resampling.NEAREST),(x+135,734))
        fd.text((i*256+10,5),label,font=font(18),fill='#25272b'); faces.alpha_composite(face,(i*256,40))
        # Original-image hand details at 2x, feet at 1.5x. No anatomy retouch.
        anatomy=Image.new('RGBA',(1400,1000),'#c8c4b8'); ad=ImageDraw.Draw(anatomy)
        ad.text((20,12),label+' · 손 2× / 발 1.5×',font=font(26),fill='#25272b')
        for k,box in enumerate(hands):
            crop=ill.crop(box); anatomy.alpha_composite(crop.resize((crop.width*2,crop.height*2),Image.Resampling.NEAREST),(30+k*650,65))
        crop=ill.crop(feetbox); anatomy.alpha_composite(crop.resize((round(crop.width*1.5),round(crop.height*1.5)),Image.Resampling.NEAREST),(30,570))
        anatomy.convert('RGB').save(REP/f'{c}-{n}-anatomy.jpg',quality=90)
        # Landmarks shown on the unaltered sprite at 4x.
        lm=Image.new('RGBA',(590,552),'#2a2d34'); lm.alpha_composite(spr.resize((512,512),Image.Resampling.NEAREST),(60,20));ld=ImageDraw.Draw(lm)
        for name,y,col in [('crown',spoints[0],'#71cfff'),('chin',spoints[1],'#ffb25e'),('feet',spoints[2],'#9fdf89')]:
            ld.line((60,20+y*4,571,20+y*4),fill=col,width=1);ld.text((1,12+y*4),f'{name}\n{y}',font=font(12),fill=col)
        ld.text((65,525),f"{label}  {metrics['looks'][f'{c}-{n}']['manual_sprite']['heads']:.2f} heads",font=font(16),fill='white')
        lm.convert('RGB').save(REP/f'{c}-{n}-landmarks.png')
    concepts.convert('RGB').save(REP/'concepts.png');faces.convert('RGB').save(REP/'faces.png')
    for name,label in [('frey','프레이'),('rio_female','리오 여성'),('nova_female','노바 여성'),('luna','루나'),('xion','시온')]:
        assets.append((label+' · 현재 게임',Image.open(RAW/f'ref-{name}-idle.png').convert('RGBA')))
    lineup=Image.new('RGBA',(4000,1340),'#22252b'); d=ImageDraw.Draw(lineup)
    d.text((24,8),'현재 게임 첫 대기와 외형 후보 · 원본 픽셀 배율 · 공통 발선 y=120',font=font(28),fill='white')
    y=55
    for scale,bg in [(1,'#2a2d34'),(1,'#c8c4b8'),(3,'#2a2d34'),(3,'#c8c4b8')]:
        h=195 if scale==1 else 440; d.rectangle((0,y,3999,y+h-1),fill=bg)
        fg='#f4f2e9' if bg=='#2a2d34' else '#22252b'
        d.text((12,y+5),f'{scale}× / {bg}',font=font(15),fill=fg)
        for i,(label,im) in enumerate(assets):
            d.text((i*400+18,y+24),label,font=font(19),fill=fg)
            px=i*400+(400-128*scale)//2;py=y+55
            d.line((i*400+8,py+120*scale,i*400+391,py+120*scale),fill='#77766c')
            lineup.alpha_composite(im.resize((128*scale,128*scale),Image.Resampling.NEAREST),(px,py))
        y+=h
    lineup.convert('RGB').save(REP/'lineup.png')
    lineup.crop((0,0,2000,1340)).convert('RGB').save(REP/'lineup-candidates.png')
    lineup.crop((2000,0,4000,1340)).convert('RGB').save(REP/'lineup-roster.png')
    (REP/'metrics.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    provenance={'generator':'built-in image_gen; every used output copied into art/raw/newchar-99b',
      'raw_files':[{'path':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(RAW.glob('*.png'))],
      'no_body_part_pasting':True,'text_encoding':'UTF-8','python_packages_installed':False,
      'illustration_processing':'Generated transparency had wide halos. Background edits to flat green, existing normalizer chroma removal/despill, Doron 2 whole image scale 0.93. No anatomy edits in code.',
      'sprite_processing':'normalize.py LANCZOS / sharpen 60 / despill auto / palette none. One scale per source. First frame copied unchanged.'}
    (REP/'provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:{'body':v['manual_sprite']['body_height_px'],'heads':v['manual_sprite']['heads'],'detail_percent':v['sprite']['detail_ratio_percent'],'bytes':sum(f['bytes'] for f in v['files'])} for k,v in metrics['looks'].items()},ensure_ascii=False,indent=2))

if __name__=='__main__':main()
