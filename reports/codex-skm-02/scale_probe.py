"""Probe ONE common factor per full row; no frame-specific scaling or edits."""
import os,sys,json,subprocess
from pathlib import Path
os.environ['PYTHONDONTWRITEBYTECODE']='1'
stem,row,att,values=sys.argv[1:5];base=Path(f'reports/codex-skm-02/{stem}/{row}/attempt-{att}')
script='face_check_rio.py' if stem.startswith('rio') else 'face_check_ny.py';results=[]
for factor in [float(x) for x in values.split(',')]:
 cmd=[sys.executable,'tools/sprite_pipeline/normalize.py','--frames',f'art/raw/skm-02/{stem}-{row}-{att}/frames','--bg','#00ff00','--cell','192','--scale-by',f'fixed:{factor}','--resample','lanczos','--sharpen','60','--despill','auto','--palette','none','--reference',f'art/bakeoff/{stem.split("_")[0]}/{stem}-idle-v2.png:0:1','--compare-scale','4','--out-dir',str(base),'--name',f'{stem}-{row}']
 cmd+=['--lift-all','8','--lift-scale','0.8'] if row=='pogo_bounce' else ['--ground-all']
 subprocess.run(cmd,check=True,stdout=subprocess.DEVNULL);subprocess.run([sys.executable,f'reports/codex-skm-02/{script}',stem,row,att],check=True,stdout=subprocess.DEVNULL)
 d=json.loads((base/'face-proposed.json').read_text(encoding='utf-8'));ratios=[f['face_width_ratio'] for f in d['frames']];r={'factor':factor,'ratios':ratios,'max_error':max(abs(x-1) for x in ratios)};results.append(r);print(json.dumps(r),flush=True)
 (base/'scale-probe.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
print('best',min(results,key=lambda r:r['max_error']))
