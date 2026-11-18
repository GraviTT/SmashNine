from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[2]
R=ROOT/'reports/codex-art-94a'
O=ROOT/'art/bakeoff/xion/a'
def font(s):
    return ImageFont.truetype('C:/Windows/Fonts/arial.ttf',s)
def frame(p,i=0):
    return Image.open(ROOT/p).convert('RGBA').crop((i*128,0,(i+1)*128,128))
rows=[
('Xion A','art/bakeoff/xion/a/xion-idle-a.png'),
('Frey','smash-nine-prototype/assets/art/frey/frey_sheet.png'),
('Rio female','smash-nine-prototype/assets/art/rio/rio_female_sheet.png'),
('Nova female','smash-nine-prototype/assets/art/nova/nova_female_sheet.png'),
('Luna','smash-nine-prototype/assets/art/luna/luna_sheet.png')]
panels=[('#2a2d34',1),('#c8c4b8',1),('#2a2d34',3),('#c8c4b8',3)]
heights=[128*s+64 for _,s in panels]
lineup=Image.new('RGBA',(1960,sum(heights)), '#17191e')
d=ImageDraw.Draw(lineup); y=0
for (bg,s),h in zip(panels,heights):
    d.rectangle((0,y,1959,y+h-1),fill=bg)
    fg='#f1eee6' if bg=='#2a2d34' else '#24262c'
    d.text((14,y+8),f'{s}x  /  {bg}  /  common foot baseline',font=font(18),fill=fg)
    fy=y+55+121*s
    d.line((12,fy,1948,fy),fill='#777b81',width=1)
    for i,(name,path) in enumerate(rows):
        sprite=frame(path); x=20+i*384+(384-128*s)//2
        lineup.alpha_composite(sprite.resize((128*s,128*s),Image.Resampling.NEAREST),(x,y+55))
        d.text((20+i*384+8,y+30),name,font=font(20),fill=fg)
    y+=h
lineup.convert('RGB').save(R/'lineup.png')
frames=[frame('art/bakeoff/xion/a/xion-idle-a.png',i) for i in range(6)]
# Quantize only this GIF preview, with one shared palette to avoid palette flicker.
gif_rgb=[Image.alpha_composite(Image.new('RGBA',(512,512),'#2a2d34'),f.resize((512,512),Image.Resampling.NEAREST)).convert('RGB') for f in frames]
mosaic=Image.new('RGB',(512*6,512))
for i,im in enumerate(gif_rgb):mosaic.paste(im,(i*512,0))
pal=mosaic.quantize(colors=256,method=Image.Quantize.MEDIANCUT)
gif_frames=[im.quantize(palette=pal,dither=Image.Dither.NONE) for im in gif_rgb]
durations=[160,160,160,150,160,160]
gif_frames[0].save(R/'idle-4x.gif',save_all=True,append_images=gif_frames[1:],duration=durations,loop=0,disposal=2,optimize=False)
# Small per-frame head crops at exactly 4x, with Rio as the scale reference.
board=Image.new('RGBA',(7*192,250),'#c8c4b8'); draw=ImageDraw.Draw(board)
all_heads=frames+[frame('smash-nine-prototype/assets/art/rio/rio_female_sheet.png')]
for i,im in enumerate(all_heads):
    # Identical 48x48 crop dimensions preserve scale; position only selects the head area.
    box=(42,18,90,66) if i<6 else (56,21,104,69)
    board.alpha_composite(im.crop(box).resize((192,192),Image.Resampling.NEAREST),(192*i,40))
    draw.text((192*i+8,10),f'Xion F{i+1}' if i<6 else 'Rio female',font=font(20),fill='#17191e')
board.convert('RGB').save(R/'heads-4x.png')
# Re-open encoded GIF to validate timing, dimensions, frames and looping.
gif=Image.open(R/'idle-4x.gif')
gif_measure={'size':list(gif.size),'frames':gif.n_frames,'loop':gif.info.get('loop'),'durations_ms':[]}
for i in range(gif.n_frames):
    gif.seek(i);gif_measure['durations_ms'].append(gif.info['duration'])
gif_measure['cycle_ms']=sum(gif_measure['durations_ms'])
gif_measure['effective_fps']=round(6000/gif_measure['cycle_ms'],6)
gif_measure['timing_note']='GIF uses 10ms ticks: nearest 6-frame cycle is 950ms (exact 6.3fps is 952.381ms). Candidate JSON remains exactly 6.3.'
# Measure contact x positions of both boot clusters on the last 4 pixel rows.
contacts=[]
for i,im in enumerate(frames):
    a=np.array(im)[:,:,3]; cols=np.where(np.any(a[117:121]>0,axis=0))[0]
    groups=np.split(cols,np.where(np.diff(cols)>1)[0]+1)
    contacts.append({'frame':i+1,'boot_bottom_x_spans':[[int(g.min()),int(g.max())] for g in groups if len(g)],'foot_y':120})
metrics=json.loads((R/'metrics.json').read_text(encoding='utf-8'))
metrics['head_scale']=json.loads((R/'head-scale.json').read_text(encoding='utf-8'))[0]
metrics['illustration_and_face']=json.loads((R/'illustration-metrics.json').read_text(encoding='utf-8'))
metrics['gif']=gif_measure
metrics['boot_contacts']=contacts
metrics['generation']={'tool':'built-in image_gen','reported_backend_model':None,'illustration_calls':1,'idle_calls':3,'selected_idle':'idle-03.png','source_sha256':{name:hashlib.sha256((ROOT/'art/raw/xion-94a'/name).read_bytes()).hexdigest() for name in ['illustration-01.png','idle-01.png','idle-02.png','idle-03.png']},'retries':[{'attempt':1,'reason':'4px total horizontal boot drift; nearly no vertical breathing'}, {'attempt':2,'reason':'remaining 1px boot drift and weaker breathing'}, {'attempt':3,'decision':'selected for clearer breathing, detail and identical head scale; 2px boot drift still unresolved'}]}
metrics['manual_sprite_head_comparison']={'method':'visual 4x main-crown-to-chin boxes; ponytails excluded; uncertainty about 1px','xion_f1_box':[45,24,84,53],'rio_female_f1_box':[65,35,99,63],'xion_head_height_px':29,'rio_head_height_px':28,'height_ratio':round(29/28,4),'xion_body_in_heads_approx':round(97/29,3),'note':'About 3.3 heads by these manually selected landmarks; visually close to current Rio, not an exact measured 3.0-head body.'}
metrics['acceptance']={'format_alpha_margin_head_detail':'pass','planted_feet_exact':'fail: boot span x varies up to 2px; y is fixed at 120','proportions':'manual estimate about 3.3 heads, close to Rio head size; strict 3.0 not met','candidate_status':'delivered for look comparison; idle needs lead review before adoption','review_method':'full-size illustration, 2x face and grip/boot crops, every final sprite frame at 4x, head board and lineup; GIF encoding inspected, no real-time playback or in-game validation'}
(R/'metrics.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'xion-idle-a.json').write_text(json.dumps({'note':'Xion A 긴 코트 후보. 검정·은색 테두리·진홍 안감, 낮은 포니테일, 쌍산탄총. 키 97–100px, 대기 6프레임. 발 좌우 최대 2px 흔들림이 남아 완전 고정 미달. 수동 등신 약 3.3. 외형 비교용 납품, 채택 전 재검토 필요. 게임 미적용.','fps':6.3,'frames':6,'loop':True},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'gif':gif_measure,'boot_contacts':contacts,'lineup_size':lineup.size},indent=2))

