"""Try only shared row factors with the copied ART-72 processing/face scripts.
No generation, per-frame rescaling, or feature drawing. Every probe is recorded.
"""
import sys,json,subprocess
from pathlib import Path
stem,row,attempt=sys.argv[1:4];factors=[float(x) for x in sys.argv[4:]]
root=Path('reports/codex-art-75');base=root/stem/row/f'attempt-{attempt}';entries=[]
for factor in factors:
 p=subprocess.run([sys.executable,str(root/'process.py'),stem,row,attempt,str(factor)],capture_output=True,text=True)
 if p.returncode:entries.append({'factor':factor,'error':p.stdout+p.stderr});continue
 q=subprocess.run([sys.executable,str(root/'face_check.py'),stem,row,attempt],capture_output=True,text=True,check=True)
 face=json.loads((base/'face-proposed.json').read_text());m=json.loads((base/'metrics.json').read_text());values=[v for f in face['frames'] for v in [f['eye_ratio'],f['face_width_ratio']] if v is not None]
 margin=m['summary']['margin4_ok'] if 'margin4_ok' in m['summary'] else all(f.get('margin4_ok',True) for f in m['frames'])
 err=max(max(.95-v,v-1.06,0) for v in values)
 e={'factor':factor,'face_values':values,'max_outside_tolerance':round(err,4),'normaliser_stdout':p.stdout,'face_stdout':q.stdout};entries.append(e);print(json.dumps(e),flush=True)
 if err==0:break
out=root/f'{stem}-{row}-factor-probes.json';out.write_text(json.dumps(entries,indent=2),encoding='utf-8')
print('PROBE_COMPLETE',stem,row,'last factor',factor,flush=True)
