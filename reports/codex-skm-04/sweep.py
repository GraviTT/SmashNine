"""Compare common row downscale factors only; never edit a body part or per-frame scale."""
import os,sys,json,subprocess,shutil
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
row,attempt=sys.argv[1:3];stem='luna' if row=='star_warp' else 'luna_brave'
root=Path('reports/codex-skm-04');base=root/stem/row/f'attempt-{attempt}'
results=[]
for factor in map(float,sys.argv[3:]):
 dst=root/'sweeps'/row/str(factor);dst.mkdir(parents=True,exist_ok=True)
 p=subprocess.run([sys.executable,str(root/'process.py'),row,attempt,str(factor)],capture_output=True,text=True)
 (dst/'process.log').write_text(p.stdout+p.stderr,encoding='utf-8');p.check_returncode()
 p=subprocess.run([sys.executable,str(root/'face_check.py'),stem,row,attempt],capture_output=True,text=True)
 (dst/'face.log').write_text(p.stdout+p.stderr,encoding='utf-8');p.check_returncode()
 f=json.loads((base/'face-proposed.json').read_text());measured=f['frames']
 values=[v[k] for v in measured for k in ['eye_ratio','face_width_ratio']]
 r={'factor':factor,'max_error':round(max(abs(x-1) for x in values),4),'pass':all(.95<=x<=1.06 for x in values),'faces':[(v['eye_ratio'],v['face_width_ratio']) for v in measured]}
 for name in ['face-proposed.json','face-landmarks-proposed.png','metrics.json','head-scale.json',f'{stem}-{row}.png']:shutil.copyfile(base/name,dst/name)
 results.append(r);print(json.dumps(r),flush=True)
 (root/'sweeps'/row/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
