"""Record visually inspected face landmarks, with explicit corrections; does not change sprites."""
import sys,json,hashlib
from pathlib import Path
from PIL import Image,ImageDraw
stem,row,attempt=sys.argv[1:4]
base=Path('reports/codex-skm-05')/stem/row/f'attempt-{attempt}'
d=json.loads((base/'face-proposed.json').read_text(encoding='utf-8'))
corrections=json.loads(Path(sys.argv[4]).read_text(encoding='utf-8')) if len(sys.argv)>4 else {}
im=Image.open(base/f'{stem}-{row}.png').convert('RGBA')
a=Image.open(f'art/bakeoff/nova/{stem}-idle-v2.png').convert('RGBA').crop((0,0,128,128))
board=Image.new('RGB',(1792,320),(31,38,55));draw=ImageDraw.Draw(board)
for item in d['frames']:
    correction=corrections.get(str(item['frame']))
    if correction:
        item['original_proposal']={'landmarks':item['landmarks'],'face_width_ratio':item['face_width_ratio']}
        item['landmarks']=[dict(p) for p in item['landmarks']]
        for mark,xy in zip(item['landmarks'][2:],correction['points']):mark.update(x=xy[0],y=xy[1])
        item['face_width']=item['landmarks'][3]['x']-item['landmarks'][2]['x']
        item['face_width_ratio']=round(item['face_width']/d['reference_face_width'],4)
        item['correction_reason']=correction['reason']
    item['review']='4x full-body and face landmarks visually inspected; far-eye metric excluded.'
for i,marks in enumerate([d['anchor_landmarks']]+[x['landmarks'] for x in d['frames']]):
    f=a if i==0 else im.crop(((i-1)*192,0,i*192,192))
    cx=(marks[2]['x']+marks[3]['x'])/2;cy=(marks[2]['y']+marks[3]['y'])/2
    ox,oy=round(cx)-24,round(cy)-24
    cr=f.crop((ox,oy,ox+48,oy+48)).resize((192,192),Image.Resampling.NEAREST)
    bx=i*256+32;by=48;board.paste(cr,(bx,by),cr)
    for mark in marks[2:]:
        x=bx+(mark['x']-ox)*4;y=by+(mark['y']-oy)*4
        draw.line((x-4,y,x+4,y),fill='yellow');draw.line((x,y-4,x,y+4),fill='yellow')
    label='ANCHOR / eyes N/A' if i==0 else f'F{i} W={d["frames"][i-1]["face_width_ratio"]:.3f} / eyes N/A'
    draw.text((i*256+8,8),label,fill='white')
    if str(i) in corrections:draw.text((i*256+8,270),'Manual boundary correction; see JSON',fill='white')
board.save(base/'face-measured.png')
d['review_note']='Inspected ART-72 landmarks; corrections, if any, retain the original proposal and reason. Same row factor; no image editing. Eye distance remains unavailable.'
d['sheet_sha256']=hashlib.sha256((base/f'{stem}-{row}.png').read_bytes()).hexdigest()
(base/'face-measured.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print([(f['frame'],f['face_width_ratio']) for f in d['frames']])
