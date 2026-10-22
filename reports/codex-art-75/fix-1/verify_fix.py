"""Static delivered-asset checks only. Never runs Godot or the commit script."""
import ast
import datetime
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path('tools/sprite_pipeline').resolve()))
import normalize as n

ROOT = Path('reports/codex-art-75')
FIX = ROOT / 'fix-1'
p = Path('art/bakeoff/yuki/yuki-fall-v2.png')
meta = json.loads(p.with_suffix('.json').read_text(encoding='utf-8'))
metrics = json.loads((FIX / 'final/metrics.json').read_text(encoding='utf-8'))
measured = json.loads((FIX / 'measurements.json').read_text(encoding='utf-8'))
face = json.loads((FIX / 'final/face-measured.json').read_text(encoding='utf-8'))
ledger = json.loads((FIX / 'generation-ledger.json').read_text(encoding='utf-8'))
checks = []

def check(condition, label):
	if not condition: raise AssertionError(label)
	checks.append(label)

def sha(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()

im = Image.open(p).convert('RGBA')
check(im.size == (768, 128), 'six 128px cells')
check(meta['frames'] == 2 and meta['fps'] == 8 and meta['cell'] == 128 and meta['feet'] == 120, 'row metadata')
check(meta['factor'] == metrics['summary']['common_scale'] == .137, 'one shared scale')
check(set(im.getchannel('A').tobytes()) <= {0, 255}, 'binary alpha')
check(sha(p) == ledger['candidate_sha256'], 'candidate hash recorded')
check(sha(ledger['source']) == ledger['raw_sha256'], 'generated raw preserved')
check(ledger['generations'] == measured['generation_count_this_pass'] == 1, 'one generation within three-try limit')
check(ledger['reference_image_1'] == 'art/raw/motions-75/yuki-anchor-4x.png', 'idle is first reference')
check(metrics['summary']['resample'] == 'lanczos' and metrics['summary']['sharpen_percent'] == 60 and metrics['summary']['despill'] == 'auto' and metrics['summary']['palette'] == 'none', 'ART-72 normalization settings')
for i in range(6):
	f = im.crop((i * 128, 0, (i + 1) * 128, 128))
	box = f.getbbox()
	if i >= 2:
		check(box is None, f'padding F{i + 1} empty')
		continue
	check(box is not None and min(box[0], box[1], 128 - box[2], 128 - box[3]) >= 4, f'F{i + 1} margin and clear border')
	check(box[3] - box[1] == 86 and box[3] - 1 == 112, f'F{i + 1} height and airborne lift')
	check(n.spill_pixel_count(f) == 0, f'F{i + 1} spill 0')
	check(n.interior_detail(f) >= 79, f'F{i + 1} detail >=79')
	check(round(n.interior_detail(f), 2) == metrics['frames'][i]['interior_detail'], f'F{i + 1} independent detail matches metrics')
	q = measured['after'][i]
	check(q['head_height'] == q['chin_bottom'][1] - q['head_top'][1], f'F{i + 1} head endpoint arithmetic')
	check(q['shoulder_width'] == q['shoulder_right'][0] - q['shoulder_left'][0], f'F{i + 1} shoulder endpoint arithmetic')
	check(.96 <= q['head_height'] / measured['anchor']['head_height'] <= 1.04, f'F{i + 1} measured head within 4%')
	check(.96 <= q['shoulder_width'] / measured['anchor']['shoulder_width'] <= 1.04, f'F{i + 1} measured shoulders within 4%')
	check(.96 <= face['frames'][i]['eye_ratio'] <= 1.04 and .96 <= face['frames'][i]['face_width_ratio'] <= 1.04, f'F{i + 1} reviewed face within 4%')
check(measured['old_relative_scale_intervals']['head'][0] > measured['old_relative_scale_intervals']['shoulder'][1], 'old head and shoulder scale intervals disjoint')
check(all(measured['visual_review'][k] for k in ['costume_matches_idle', 'hands_props_boots_intact', 'one_face_each', 'no_effects_text']), 'manual costume/identity/props review recorded')
check(Image.open(ROOT / 'yuki-fall.png').size == (1632, 624), 'updated exact 4x board')
for script in FIX.glob('*.py'):
	ast.parse(script.read_text(encoding='utf-8'))
	check(True, 'Python syntax ' + script.name)
files = json.loads((FIX / 'files-to-stage.json').read_text(encoding='utf-8'))
for item in files:
	check(item.startswith(('art/bakeoff/yuki/', 'reports/codex-art-75/')) and not any(s in item for s in ['art/raw/', '__pycache__', 'run.log']), 'stage scope ' + item)
	if not item.endswith('audit.json'): check(Path(item).is_file(), 'stage file exists ' + item)
commit = ROOT / 'commit-fix-1.ps1'
script = commit.read_text(encoding='utf-8')
check(re.findall(r"^    '([^']+)'$", script, re.M) == files, 'commit exact manifest')
check('reports/codex-art-75/fix-1.prompt.md' in files, 'user prompt included')
check(not re.search(r'\badd\s+(?:-f|--force)\b', script), 'no force-add')
check('Unrelated staged file' in script, 'unrelated staged paths guarded')
pspath = str(commit.resolve()).replace("'", "''")
parse = "$pt=$null; $pe=$null; [System.Management.Automation.Language.Parser]::ParseFile('" + pspath + "',[ref]$pt,[ref]$pe) > $null; if($pe.Count){$pe | ForEach-Object {$_.Message}; exit 1}"
parsed = subprocess.run(['powershell', '-NoProfile', '-NonInteractive', '-Command', parse], text=True, capture_output=True)
check(parsed.returncode == 0, 'PowerShell syntax only; commit script not executed')
protected = subprocess.run(['git', 'diff', '--name-only', '--', 'smash-nine-prototype', 'tools'], text=True, capture_output=True, check=True).stdout.strip()
check(not protected, 'no tracked product/tool changes')
check(not list(FIX.rglob('__pycache__')), 'no bytecode cache in this pass')
audit = {'passed': True, 'checks_count': len(checks), 'checks': checks, 'candidate': str(p).replace('\\', '/'), 'godot_run': False, 'motion_viewer_run': False, 'commit_script_executed': False, 'verified_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'manual_measurement_limit': '4x boundary reading uncertainty approximately one original pixel; automated checks validate arithmetic, not anatomy.'}
(FIX / 'audit.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'{len(checks)} static checks passed; Godot and commit script were not run.')
