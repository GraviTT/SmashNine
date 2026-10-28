"""Same ART-89 head measurement on visible upright faces only; rotated frames are explicit exclusions."""
import os,sys
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import head_scale as h
import numpy as np
include={int(x) for x in sys.argv.pop().split(',')}
def visible_measure(sheet,template,count,min_score):
 frames=[];good=[]
 for i,f in enumerate(h.cells(sheet,count),1):
  if i not in include:frames.append({'scale':None,'score':0,'reason':'Pose excluded from upright template measurement'});continue
  s,score=h.head_scale(f,template)
  frames.append({'scale':s,'score':round(score,3)})
  if s is not None and score>=min_score:good.append(s)
 return {'sheet':str(sheet),'frames':frames,'median':round(float(np.median(good)),3) if good else None,'used':len(good)}
h.measure=visible_measure
exec(compile(Path('reports/codex-art-92/process92.py').read_text(encoding='utf-8'),'process92-adapter','exec'))
