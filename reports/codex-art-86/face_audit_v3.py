"""ART-72 align_head/match/refine_eyes, parametrized for ART-86 anchors.
Proposed landmarks are evidence, not an automatic acceptance verdict.
"""
from common import *
import ast, math
stem=sys.argv[1];row=sys.argv[2];path=Path(sys.argv[3]);tag=sys.argv[4]
folder='nova' if stem.startswith('nova') else 'rio' if stem.startswith('rio') else 'frey'
a=cells(ROOT/f'art/bakeoff/{folder}/{stem}-idle-v2.png')[0]
points={
 'nova_male':[(72.5,57.5,3,4),(81,58,3,3),(67,60,3,4),(81,60,3,4)],
 'nova_female':[(72.5,59.5,3,4),(81,60,3,3),(67,62,3,4),(81,62,3,4)],
 'rio_female':[(83,50.5,3,4),(88,51,2,3),(78,53,3,4),(88.5,53,3,4)],
 'rio_male':[(75.5,49.5,3,4),(81,50,2,3),(66,53,3,4),(81,53,3,4)],
 'frey':[(79,51,3,4),(85,51,3,4),(68,53,4,4),(85.5,53,4,4)],
}[stem]
ac=h.face_centre(np.array(a));an=np.array(a.resize((512,512),Image.Resampling.NEAREST))[...,:3].astype(float)
def centre(f):return h.face_centre(np.array(f))
tree=ast.parse((ROOT/'reports/codex-art-72/face_check.py').read_text(encoding='utf-8'))
funcs=[x for x in tree.body if isinstance(x,ast.FunctionDef) and x.name in ['align_head','match','refine_eyes']]
exec(compile(ast.Module(body=funcs,type_ignores=[]),'ART72-functions','exec'))
# All forms here have blue/teal eyes; use the original Frey blue-eye refinement.
form=stem;stem='frey'
am=refine_eyes(a,[{'x':p[0],'y':p[1],'score':1} for p in points])
ae=math.dist((am[0]['x'],am[0]['y']),(am[1]['x'],am[1]['y']));aw=points[3][0]-points[2][0]
fs=cells(path);records=[];boards=[];template=h.head_template(a)
for i,f in enumerate([a]+fs):
    if i:
        scale,score=h.head_scale(f,template);alignment=align_head(f,scale if score>=.6 else 1.0)
        marks=refine_eyes(f,[match(f,p) for p in points])
    else:scale,score=1.,1.;marks=am
    eye=math.dist((marks[0]['x'],marks[0]['y']),(marks[1]['x'],marks[1]['y']));fw=marks[3]['x']-marks[2]['x']
    cy,cx=centre(f);ox,oy=round(cx)-26,round(cy)-26
    cr=f.crop((ox,oy,ox+52,oy+52)).resize((208,208),Image.Resampling.NEAREST)
    b=Image.new('RGB',(240,300),(31,38,55));b.paste(cr,(16,40),cr);d=ImageDraw.Draw(b)
    for j,m in enumerate(marks):
        x=16+(m['x']-ox)*4;y=40+(m['y']-oy)*4;col='cyan' if j<2 else 'yellow';d.line((x-4,y,x+4,y),fill=col);d.line((x,y-4,x,y+4),fill=col)
    d.text((5,5),'ANCHOR' if not i else f'F{i} head {scale:.2f}',fill='white',font=n.font(16))
    d.text((5,255),f'E {eye/ae:.3f} W {fw/aw:.3f}',fill='white',font=n.font(16));boards.append(b)
    if i:records.append({'frame':i,'head_scale':scale,'head_score':round(score,3),'eye_ratio':round(eye/ae,3),'width_ratio':round(fw/aw,3),'landmarks':marks})
out=Image.new('RGB',(240*len(boards),300))
for i,b in enumerate(boards):out.paste(b,(240*i,0))
save(out,OUT/f'{tag}-landmarks.png')
js({'method':'ART-72 functions verbatim; form-specific anchor points, blue-eye refinement. Proposals require direct visual review; occlusion is not a numeric pass.','anchor':points,'frames':records},OUT/f'{tag}-face.json')
print([(x['frame'],x['head_scale'],x['head_score'],x['eye_ratio'],x['width_ratio']) for x in records])
