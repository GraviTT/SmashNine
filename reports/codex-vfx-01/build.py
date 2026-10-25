"""Build VFX-01 candidates from preserved ImageGen outputs; never writes product files."""
from pathlib import Path
import hashlib
import json
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.dont_write_bytecode = True
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path(__file__).resolve().parents[2]
REPORT = Path(__file__).resolve().parent
OUT = ROOT / 'art/bakeoff/effects/rio'
RAW = ROOT / 'art/raw/vfx-01'
FRAME = 64
ANCHOR = (32, 3)
FPS = 40
PALETTE_HEX = ['10172A', '15295B', '174788', '2869CA', '0F6683', '168FB8', '39D8FF', '80E6FF', 'B5F3FF', 'DCECF2', 'F1FCFF']
PALETTE = np.array([[int(s[i:i+2], 16) for i in (0, 2, 4)] for s in PALETTE_HEX], dtype=np.int32)
NAMES = {'a': 'A / MANA PLATE', 'b': 'B / GEM KICK', 'c': 'C / FLAT RIPPLE'}
NOTES = {
 'a': ['얇은 마력 발판이 번쩍인 뒤 아래로 갈라집니다. 첫 추가 점프용 청색 면입니다.', '마지막 추가 점프는 발판의 청백색 면을 밝히고 중앙 갈라짐을 강조합니다.'],
 'b': ['작은 보석 파편을 아래로 차내며 공중 점프 소모를 표시합니다. 첫 추가 점프는 청색 보석입니다.', '마지막 추가 점프는 가운데 보석과 파편의 청백색 면을 밝힙니다.'],
 'c': ['발 아래 납작한 마력 파문이 퍼지고 끊어집니다. 첫 추가 점프는 청색 테두리입니다.', '마지막 추가 점프는 청백색 이중 테두리가 밝게 번쩍인 뒤 사라집니다.'],
}

def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def rgba_clean(im):
    a = np.array(im.convert('RGBA'))
    a[:, :, 3] = np.where(a[:, :, 3] >= 128, 255, 0).astype(np.uint8)
    a[a[:, :, 3] == 0] = 0
    return Image.fromarray(a)

def palette_map(im):
    a = np.array(im)
    mask = a[:, :, 3] != 0
    rgb = a[:, :, :3][mask].astype(np.int32)
    distance = ((rgb[:, None] - PALETTE[None]) ** 2).sum(axis=2)
    a[:, :, :3][mask] = PALETTE[distance.argmin(axis=1)].astype(np.uint8)
    return Image.fromarray(a)

def measure(im):
    a = np.array(im)
    mask = a[:, :, 3] != 0
    yy, xx = np.where(mask)
    border = np.concatenate([mask[0], mask[-1], mask[:, 0], mask[:, -1]])
    light = a[:, :, :3][mask] @ np.array([0.2126, 0.7152, 0.0722])
    return dict(bbox=list(im.getbbox()), opaque_pixels=int(mask.sum()), above_soles_pixels=int(mask[:ANCHOR[1]].sum()),
                rise_above_soles_px=max(0, int(ANCHOR[1]-yy.min())), depth_below_soles_px=int(yy.max()-ANCHOR[1]),
                border_opaque_pixels=int(border.sum()), mean_luma=round(float(light.mean()), 2),
                bright_pixels=int((light >= 200).sum()))

def build():
    audit = {'frame_size': [64, 64], 'frames': 5, 'fps': FPS, 'duration_s': 5/FPS,
             'anchor_px': list(ANCHOR), 'anchor_status': 'PROVISIONAL: top-centre sole alignment; literal bottom-centre conflicts with below-sole art',
             'palette_hex': PALETTE_HEX, 'variants': {}}
    all_frames = {}
    for v in 'abc':
        raw_path = RAW / (v+'.png')
        raw = rgba_clean(Image.open(raw_path))
        cells = []
        for row in range(2):
            for col in range(5):
                cell = raw.crop((col*raw.width//5, row*raw.height//2, (col+1)*raw.width//5, (row+1)*raw.height//2))
                cells.append(cell.crop(cell.getbbox()))
        width = {'a': 54, 'b': 46, 'c': 58}[v]
        factor = min(1.0, width/max(im.width for im in cells), 40/max(im.height for im in cells))
        audit['variants'][v] = dict(raw_sha256=hashlib.sha256(raw_path.read_bytes()).hexdigest(), raw_size=list(raw.size), downscale_factor=factor, states={})
        for row in range(2):
            frames = []
            strip = Image.new('RGBA',(320,64))
            for col in range(5):
                cell = cells[row*5+col]
                resized = cell.resize((max(1, round(cell.width*factor)), max(1, round(cell.height*factor))), Image.Resampling.NEAREST)
                resized = palette_map(resized)
                frame = Image.new('RGBA',(64,64))
                top = [2,1,5,9,13][col]
                frame.alpha_composite(resized, ((64-resized.width)//2, top))
                frames.append(frame)
                strip.alpha_composite(frame,(col*64,0))
            name = f'rio_air_step-{v}-{row+1}-v1'
            strip.save(OUT/(name+'.png'))
            dump(OUT/(name+'.json'), dict(note=NOTES[v][row], replaces='smash-nine-prototype/assets/art/effects/skill/rio_air_step.png', frames=5, fps=FPS,
                 frame_size=[64,64], anchor_px=list(ANCHOR), loop=False, filter='nearest', blend='normal',
                 anchor_note='발밑 배치 우선의 임시 앵커 (32,3). 카드의 아래 중앙 문구와 충돌하므로 통합 전 확정 필요.'))
            measurements = [measure(im) for im in frames]
            a = np.array(strip)
            audit['variants'][v]['states'][str(row+1)] = dict(file=name+'.png', size=list(strip.size), alpha_values=np.unique(a[:,:,3]).tolist(), per_frame=measurements)
            all_frames[(v,row+1)] = frames
            assert strip.size == (320,64)
            assert set(np.unique(a[:,:,3])) == {0,255}
            assert all(m['border_opaque_pixels']==0 and m['rise_above_soles_px']<=2 for m in measurements)
        state = audit['variants'][v]['states']
        light1 = sum(m['mean_luma']*m['opaque_pixels'] for m in state['1']['per_frame'])
        light2 = sum(m['mean_luma']*m['opaque_pixels'] for m in state['2']['per_frame'])
        audit['variants'][v]['last_to_first_light_ratio'] = round(light2/light1,3)
        assert light2 > light1
    dump(REPORT/'measurements.json',audit)
    return all_frames,audit

def make_boards(all_frames,audit):
    font_path = 'C:/Windows/Fonts/arial.ttf'
    title = ImageFont.truetype(font_path,32)
    label = ImageFont.truetype(font_path,22)
    small = ImageFont.truetype(font_path,18)
    sheets = {}
    for sex in ['male','female']:
        im = Image.open(ROOT/f'smash-nine-prototype/assets/art/rio/rio_{sex}_sheet.png').convert('RGBA')
        sheets[sex] = im.crop((0,384,128,512))
    W, SECTION = 2640, 1490
    panels=[]
    for v in 'abc':
        pair = Image.new('RGB',(W,SECTION*2),'#111b2b')
        for state in [1,2]:
            panel=Image.new('RGB',(W,SECTION),'#111b2b')
            draw=ImageDraw.Draw(panel)
            draw.text((24,12),f'{NAMES[v]}  /  {state}: '+('FIRST EXTRA JUMP' if state==1 else 'LAST EXTRA JUMP'),font=title,fill='#c5edff')
            draw.text((24,57),'64 x 64 x 5 | 40 fps | 0.125 s | normal blend | 4x NEAREST | candidate, not in game',font=label,fill='#91aabc')
            draw.text((24,90),'Provisional anchor (32,3). Cyan ticks: game feet (sheet y=120). Sprite position is unchanged.',font=label,fill='#91aabc')
            strip=Image.open(OUT/f'rio_air_step-{v}-{state}-v1.png').convert('RGBA')
            panel.paste(strip,(1200,16),strip)
            draw.text((1540,35),'strip 1x',font=small,fill='#c5edff')
            for row,sex in enumerate(['male','female']):
                row_top=140+row*670
                for col,fx in enumerate(all_frames[(v,state)]):
                    tile=Image.new('RGBA',(128,158),'#172338')
                    tile.alpha_composite(fx,(64-ANCHOR[0],120-ANCHOR[1]))
                    tile.alpha_composite(sheets[sex],(0,0))
                    enlarged=tile.resize((512,632),Image.Resampling.NEAREST).convert('RGB')
                    px=20+col*522
                    panel.paste(enlarged,(px,row_top))
                    draw.text((px+5,row_top+4),f'{sex.upper()} / F{col+1}',font=small,fill='#b3c4d6')
                    baseline=row_top+120*4
                    draw.line((px+8,baseline,px+40,baseline),fill='#3fd4e8',width=2)
                    draw.line((px+472,baseline,px+504,baseline),fill='#3fd4e8',width=2)
                    m=audit['variants'][v]['states'][str(state)]['per_frame'][col]
                    draw.text((px+5,row_top+602),f"above {m['rise_above_soles_px']}px / {m['above_soles_pixels']} pixels",font=small,fill='#b3c4d6')
            panel.save(REPORT/f'board-{v}-{state}.png')
            pair.paste(panel,(0,(state-1)*SECTION))
            panels.append(panel)
        pair.save(REPORT/f'board-{v}.png')
    full=Image.new('RGB',(W,SECTION*6),'#111b2b')
    for i,p in enumerate(panels): full.paste(p,(0,i*SECTION))
    full.save(REPORT/'board.png')
    overview=Image.new('RGB',(1320,900),'#111b2b')
    d=ImageDraw.Draw(overview)
    d.text((24,16),'RIO AIR STEP / 3 IDEAS x 2 STATES',font=title,fill='#c5edff')
    for vi,v in enumerate('abc'):
        for si,state in enumerate([1,2]):
            x=vi*440; y=65+si*410
            d.text((x+20,y),f'{v.upper()}-{state}  '+('FIRST' if state==1 else 'LAST'),font=label,fill='#b3c4d6')
            tile=Image.new('RGBA',(128,158),'#172338')
            tile.alpha_composite(all_frames[(v,state)][1],(32,117))
            tile.alpha_composite(sheets['male'],(0,0))
            overview.paste(tile.resize((256,316),Image.Resampling.NEAREST).convert('RGB'),(x+75,y+35))
            strip=Image.open(OUT/f'rio_air_step-{v}-{state}-v1.png')
            overview.paste(strip,(x+50,y+345),strip)
    overview.save(REPORT/'overview.png')

if __name__ == '__main__':
    frames,audit=build()
    make_boards(frames,audit)
    for v in 'abc':
        print(v,'brightness ratio',audit['variants'][v]['last_to_first_light_ratio'])
        for s,data in audit['variants'][v]['states'].items():
            print(s,'rise',[m['rise_above_soles_px'] for m in data['per_frame']], 'above_pixels',[m['above_soles_pixels'] for m in data['per_frame']])
    print('All mechanical checks passed; anchor interpretation requires resolution.')
