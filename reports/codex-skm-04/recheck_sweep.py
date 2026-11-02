import os,sys,json,subprocess
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
root=Path('reports/codex-skm-04');results=[]
for p in sorted((root/'sweeps/star_warp').iterdir()):
 if not p.is_dir() or not (p/'head-scale.json').exists():continue
 r=subprocess.run([sys.executable,str(root/'face_check.py'),'luna','star_warp','1',str(p)],capture_output=True,text=True);r.check_returncode()
 f=json.loads((p/'face-proposed.json').read_text());vals=[v[k] for v in f['frames'] for k in ['eye_ratio','face_width_ratio']]
 item={'factor':float(p.name),'max_error':max(abs(v-1) for v in vals),'pass':all(.95<=v<=1.06 for v in vals),'faces':[(v['eye_ratio'],v['face_width_ratio']) for v in f['frames']]};results.append(item);print(json.dumps(item),flush=True)
(root/'sweeps/star_warp/rechecked.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
