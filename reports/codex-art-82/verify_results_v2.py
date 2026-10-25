"""Read-only asset and scope verification; writes a new audit file once."""
import ast, json, hashlib, subprocess, sys
from pathlib import Path
from PIL import Image
import numpy as np
sys.path.insert(0,str(Path('tools/sprite_pipeline').resolve()))
import normalize as n

ROOT=Path('reports/codex-art-82')
rows=json.loads((ROOT/'results.json').read_text(encoding='utf-8'))
checks=[]
def check(name,value,detail=None):
    checks.append({'check':name,'passed':bool(value),'detail':detail})

for r in rows:
    key=f'{r["stem"]}-{r["row"]}';cell=r['cell'];count=r['frames']
    best=Path(r['best']);face=json.loads((best/'face-measured.json').read_text(encoding='utf-8'))
    m=json.loads((best/'metrics.json').read_text(encoding='utf-8'));s=m['summary']
    check(key+': ART-72 normalization settings',s['resample']=='lanczos' and s['sharpen_percent']==60 and s['despill']=='auto' and s['palette']=='none' and s['common_scale']==r['factor'])
    check(key+': generations <= 3',r['generations']<=3)
    board=Image.open(ROOT/f'{key}.png')
    check(key+': comparison is true 4x',board.size==(512+cell*8,(48+cell*4)*count))
    check(key+': all comparison frames present',all((ROOT/'comparisons'/key/f'F{i+1:02}.png').exists() for i in range(count)))
    if not r['deliver']:continue
    p=Path(r['candidate']);meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'))
    check(key+': candidate bytes match normalized result',p.read_bytes()==(best/'best-attempt.png').read_bytes())
    check(key+': next version metadata',meta['replaces']==Path(r['old_file']).name and meta['frames']==count and meta['cell']==cell and meta['factor']==r['factor'] and meta['fps']==(10 if r['row']=='jump' else 8) and meta['loop']==(r['row']=='fall'))
    im=Image.open(p).convert('RGBA');a=np.array(im)
    check(key+': normalizer column count and empty padding',im.size==(s['output_columns']*cell,cell) and not a[:,count*cell:,3].any())
    check(key+': binary alpha',set(np.unique(a[:,:,3]).tolist())<={0,255})
    old=Image.open(r['old_file']).convert('RGBA')
    details=[]
    for i in range(count):
        f=im.crop((i*cell,0,(i+1)*cell,cell));fa=np.array(f)
        yy,xx=np.where(fa[:,:,3]>0)
        margin=min(xx.min(),yy.min(),cell-1-xx.max(),cell-1-yy.max())
        metric=n.frame_metrics(f);details.append(metric['interior_detail'])
        check(f'{key} F{i+1}: 4px margin, spill0, detail>=79',margin>=4 and metric['remaining_spill_pixels']==0 and metric['interior_detail']>=79)
        if i+1 not in r['redone']:
            check(f'{key} F{i+1}: unchanged pixels',np.array_equal(fa,np.array(old.crop((i*cell,0,(i+1)*cell,cell)))))
        if r['row']=='victory':check(f'{key} F{i+1}: grounded extent at152',int(yy.max())==152)
    vals=[f[k] for f in face['frames'] if f['frame'] not in face.get('excluded_frames',[]) for k in ['eye_ratio','face_width_ratio'] if f.get(k) is not None]
    check(key+': every measurable face ratio in strict interval',bool(vals) and all(.96<=v<=1.04 for v in vals),vals)
    check(key+': measured detail matches delivered PNG',np.allclose(details,[f['interior_detail'] for f in m['frames']]))

assemblies=list(Path('art/raw/motions-82').glob('*.assembly.json'))
for p in assemblies:
    d=json.loads(p.read_text(encoding='utf-8'));a=np.array(Image.open(d['base']).convert('RGB'));b=np.array(Image.open(d['out']).convert('RGB'))
    mask=np.ones(a.shape[:2],dtype=bool)
    for x0,y0,x1,y1 in d['boxes']:mask[y0:y1,x0:x1]=False
    check(p.name+': complete-cell replacement preserves other cells',a.shape==b.shape and np.array_equal(a[mask],b[mask]))

tracked=subprocess.run(['git','diff','--name-only'],capture_output=True,text=True,check=True).stdout.splitlines()
staged=subprocess.run(['git','diff','--cached','--name-only'],capture_output=True,text=True,check=True).stdout.splitlines()
branch=subprocess.run(['git','branch','--show-current'],capture_output=True,text=True,check=True).stdout.strip()
check('branch codex/art-82',branch=='codex/art-82')
check('no existing tracked file modified',not tracked,tracked)
check('no staging or commit executed',not staged,staged)
for p in ROOT.glob('*.py'):
    try:ast.parse(p.read_text(encoding='utf-8'));ok=True
    except SyntaxError:ok=False
    check(p.name+': Python AST',ok)

manifest=json.loads((ROOT/'commit-files-v2.json').read_text(encoding='utf-8'))
allowed_candidates={Path(r['candidate']).as_posix() for r in rows if r['deliver']}
allowed_candidates|={str(Path(p).with_suffix('.json')).replace('\\','/') for p in list(allowed_candidates)}
cards={'design/tasks/CODEX-ART-82.md','design/tasks/CODEX-ART-82.prompt.md'}
check('commit manifest cards and prompt',cards.issubset(set(manifest)))
check('commit manifest candidates',allowed_candidates.issubset(set(manifest)))
check('commit manifest scope',all(p.startswith('reports/codex-art-82/') or p in cards or p in allowed_candidates for p in manifest))
check('commit excludes raw caches run.log',all(not p.startswith('art/raw/') and '__pycache__' not in p and Path(p).name!='run.log' for p in manifest))
check('manifest no duplicate paths',len(manifest)==len(set(manifest)))
check('manifest files exist except audit being written',all(Path(p).is_file() or p=='reports/codex-art-82/audit-v2.json' for p in manifest))
ignored=subprocess.run(['git','check-ignore','--stdin'],input='\n'.join(manifest)+'\n',capture_output=True,text=True)
check('no force-add required',ignored.returncode==1 and not ignored.stdout.strip(),ignored.stdout.strip())
script=(ROOT/'commit-v2.ps1').read_text(encoding='utf-8')
check('commit script no forced add', 'git add -f' not in script and ' add -f ' not in script)
check('commit author trailer', 'Co-Authored-By: Codex <noreply@openai.com>' in script)
ps="$tok=$null; $err=$null; [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path 'reports/codex-art-82/commit-v2.ps1'),[ref]$tok,[ref]$err) | Out-Null; if($err.Count){$err | ForEach-Object {$_.Message}; exit 1}; Write-Output 'PS_AST_OK'"
parsed=subprocess.run(['powershell','-NoProfile','-Command',ps],capture_output=True,text=True)
check('commit PowerShell AST only, not executed',parsed.returncode==0 and 'PS_AST_OK' in parsed.stdout,parsed.stdout.strip())
out=ROOT/'audit-v2.json';assert not out.exists(),out
report={'passed':all(c['passed'] for c in checks),'check_count':len(checks),'candidate_rows':sum(r['deliver'] for r in rows),'partial_rows':sum(bool(r.get('partial')) for r in rows),'candidate_frames':sum(r['frames'] for r in rows if r['deliver']),'new_candidate_frames':sum(len(r['redone']) for r in rows if r['deliver']),'selected_frames_reviewed_4x':sum(r['frames'] for r in rows),'generations':sum(r['generations'] for r in rows),'godot_run':False,'commit_run':False,'checks':checks}
out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='checks'},ensure_ascii=False))
for c in checks:
    if not c['passed']:print(json.dumps(c,ensure_ascii=False))
sys.exit(0 if report['passed'] else 1)
