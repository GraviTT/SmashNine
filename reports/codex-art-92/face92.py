"""Reuse ART-89 landmarks; report unavailable measurements explicitly, never invent a pass."""
import os,sys,json,math
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
stem,row,label=sys.argv[1:4]
out=Path('art/raw/motions-92')/f'{stem}-{row}'/label
skip={int(x) for x in sys.argv[4].split(',') if x} if len(sys.argv)>4 else set()
family='_75' if stem in ['yuki','nova_male','nova_female'] else '_77' if stem.startswith('rio_') else ''
source=(Path('reports/codex-art-92')/f'art89_face_check{family}.py').read_text(encoding='utf-8')
pre=source[:source.index("report={'method'")]
refine=source[source.index('def refine_eyes'):source.index("for row,count in")]
env={'__name__':'__main__'}
exec(compile(pre+'\n'+refine,'ART89-face-method','exec'),env)
Image=env['Image'];ImageDraw=env['ImageDraw'];h=env['h'];np=env['np'];a=env['a'];points=env['points'];am=env['am']
im=Image.open(out/f'{stem}-{row}.png').convert('RGBA');cell=im.height
head=json.loads((out/'head-scale.json').read_text())
board=Image.new('RGB',(7*256,310),(31,38,55));draw=ImageDraw.Draw(board)
ae=math.dist((am[0]['x'],am[0]['y']),(am[1]['x'],am[1]['y']));aw=points[3][0]-points[2][0]
results=[]
for i,f in enumerate([a]+[im.crop((j*cell,0,(j+1)*cell,cell)) for j in range(6)]):
 env.update(row=row,i=i)
 if i in skip:
  # Pose explicitly reviewed as facing away/hidden/closed, not used to tune scale.
  results.append({'frame':i,'eye_ratio':None,'face_width_ratio':None,'reason':'회전으로 얼굴 방향이 바뀌거나 얼굴이 가려져 대응점 측정 불가'})
  tile=f.resize((256,256),Image.Resampling.NEAREST);board.paste(tile,(i*256,30),tile);draw.text((i*256+4,4),f'F{i} EXCLUDED',fill='white');continue
 if i:
  hf=head['frames'][i-1];env['alignment']=env['align_head'](f,hf['scale'] if hf['score']>=.6 else (head['median'] or 1.0))
 marks=[dict(m) for m in am] if i==0 else env['refine_eyes'](f,[env['match'](f,p) for p in points])
 cy,cx=env['centre'](f);ox,oy=round(cx)-24,round(cy)-24
 cr=f.crop((ox,oy,ox+48,oy+48)).resize((192,192),Image.Resampling.NEAREST);bx=i*256+32;by=40;board.paste(cr,(bx,by),cr)
 for j,m in enumerate(marks):
  x=bx+(m['x']-ox)*4;y=by+(m['y']-oy)*4;col='cyan' if j<2 else 'yellow'
  draw.line((x-4,y,x+4,y),fill=col);draw.line((x,y-4,x,y+4),fill=col)
 eye=math.dist((marks[0]['x'],marks[0]['y']),(marks[1]['x'],marks[1]['y']))/ae
 width=(marks[3]['x']-marks[2]['x'])/aw
 draw.text((i*256+4,4),f'{i} E{eye:.3f} W{width:.3f}',fill='white')
 if i:results.append({'frame':i,'eye_ratio':round(eye,3),'face_width_ratio':round(width,3),'landmarks':marks,'head_alignment':env['alignment'],'reason':'자동 대응점 제안; 4배 육안 검토 필요'})
with (out/'face-proposed.json').open('x',encoding='utf-8') as f:json.dump({'anchor':points,'anchor_landmarks':am,'reference_eye_distance':ae,'reference_face_width':aw,'frames':results},f,indent=2,ensure_ascii=False)
with (out/'face-board.png').open('xb') as f:board.save(f,format='PNG')
print(json.dumps(results,ensure_ascii=False))
