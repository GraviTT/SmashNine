"""Read-only independent pixel audit. Does not import the lead's apply implementation.
Run with the card's Python from the repository root. Only the JSON report is written.
"""
from pathlib import Path
import io
import json
import re
import subprocess
import sys
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / 'smash-nine-prototype'
ART = GAME / 'assets/art'
BASE = 'c51a417f'
OUT = Path(__file__).with_name('apply-audit.json')
docs = json.loads((ROOT / 'reports/apply-2026-10-29/picks-snapshot.json').read_text('utf-8'))['docs']
by_id = {d['doc']: d for d in docs}
checks, rows, monsters, preservation = [], [], [], []
expected_files = set()
old_cache = {}

def rel(p):
    return p.relative_to(ROOT).as_posix()

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def old_bytes(p):
    key = rel(p)
    if key not in old_cache:
        result = subprocess.run(['git', 'show', f'{BASE}:{key}'], cwd=ROOT, capture_output=True)
        old_cache[key] = result.stdout if result.returncode == 0 else None
    return old_cache[key]

def pixels(p):
    return np.array(Image.open(p).convert('RGBA'))

def previous(p):
    data = old_bytes(p)
    return None if data is None else pixels(io.BytesIO(data))

def check(label, actual, expected):
    same_shape = actual.shape == expected.shape
    n = int(np.count_nonzero(np.any(actual != expected, axis=2))) if same_shape else None
    result = {'check': label, 'ok': same_shape and n == 0,
              'actual_size': list(actual.shape[1::-1]), 'expected_size': list(expected.shape[1::-1]),
              'different_rgba_pixels': n}
    checks.append(result)
    return result

def truth(label, ok, **details):
    result = {'check': label, 'ok': bool(ok), **details}
    checks.append(result)
    return result

def unchanged(p, label):
    before = previous(p)
    if before is None:
        return truth(label, not p.exists(), checkpoint_absent=True, current_absent=not p.exists())
    return check(label, pixels(p), before)

def table(script, name):
    text = (GAME / script).read_text('utf-8')
    pos = text.index('[', text.index('const ' + name + ' :='))
    depth, end = 0, pos
    for end in range(pos, len(text)):
        depth += (text[end] == '[') - (text[end] == ']')
        if depth == 0:
            break
    return [(m[0], int(m[1])) for m in re.findall(r'\["([a-z_]+)",\s*(\d+),', text[pos:end+1])]

optional = dict(table('characters/common/PlayerBase.gd', 'OPTIONAL_MOTION_ROWS'))
sheet_masks = {}

def sheet_row(form, row):
    folder = form.split('_')[0]
    script = f'characters/{folder}/{folder.title()}.gd'
    for name, suffix in [('SHEET_ROWS', '_sheet.png'), ('MOVE_SHEET_ROWS', '_moves_sheet.png')]:
        try:
            specs = table(script, name)
        except ValueError:
            continue
        cursor = 0
        for key, count in specs:
            if key == row:
                p = ART / folder / (form + suffix)
                a = pixels(p)
                cell = a.shape[1] // 6
                coords = [(i % 6 * cell, (cursor + i // 6) * cell) for i in range(count)]
                return p, cell, coords
            cursor += (count + 5) // 6
    return None

def gather(a, coords, cell):
    return np.concatenate([a[y:y+cell, x:x+cell] for x,y in coords], axis=1)

for d in docs:
    start = len(checks)
    kind, form, row, choice = (d[k] for k in ['kind','form','row','choice'])
    label = d['doc']
    folder = form.split('_')[0]
    source = ROOT / d['file'] if d.get('file') else None
    target = None
    if kind == 'fighter':
        if row in optional:
            target = ART / folder / f'{form}_{row}.png'
            if choice == 'none':
                unchanged(target, label + ': optional strip preservation')
                fallback = sheet_row(form, row)
                if fallback:
                    p, cell, coords = fallback
                    check(label + ': fallback sheet cells', gather(pixels(p), coords, cell), gather(previous(p), coords, cell))
            else:
                cell, count = (192 if row in ['victory','defeat'] else 128), optional[row]
                candidate = pixels(source)
                truth(label + ': candidate canvas', candidate.shape[0] == cell and candidate.shape[1] >= count*cell and candidate.shape[1] % cell == 0)
                truth(label + ': unused candidate pixels invisible', not np.any(candidate[:,count*cell:,3]))
                check(label, pixels(target), candidate[:,:count*cell])
                expected_files.add(rel(target))
        else:
            target, cell, coords = sheet_row(form,row)
            current = pixels(target)
            selected = gather(current, coords, cell)
            check(label, selected, gather(previous(target), coords, cell) if choice == 'none' else pixels(source))
            if choice != 'none':
                expected_files.add(rel(target))
                mask = sheet_masks.setdefault(target, np.zeros(current.shape[:2], dtype=bool))
                for x,y in coords:
                    mask[y:y+cell,x:x+cell] = True
    elif kind == 'face':
        target = ART / folder / f'{form}_face_{row}.png'
        if choice == 'none':
            unchanged(target,label + ': expression preservation')
            unchanged(ART / folder / f'{form}_face.png',label + ': neutral fallback preservation')
        else:
            check(label,pixels(target),pixels(source))
            expected_files.add(rel(target))
    elif kind == 'projectile':
        name = ('slam_shockwave' if form == 'slam_shockwave' else form + '_shockwave') if row == 'shockwave' else ('ember_fireball' if form == 'ember_imp' else form + '_projectile')
        target = ART / 'monsters' / (name + '.png')
        if choice == 'none':
            unchanged(target,label)
        else:
            check(label,pixels(target),pixels(source))
            expected_files.add(rel(target))
    elif kind in ['monster','legacy_sheet']:
        # Evaluated from the selected legacy sheet and inserted rows below.
        continue
    else:
        truth(label + ': supported kind', False)
    rows.append({'doc': label,'kind':kind,'choice':choice,'target':rel(target) if target else None,
                 'ok': all(c['ok'] for c in checks[start:]),'checks':checks[start:]})

for p, mask in sheet_masks.items():
    a,b = pixels(p),previous(p)
    changed = np.any(a != b,axis=2)
    preservation.append(truth(rel(p) + ': all cells outside selected regions unchanged', not np.any(changed & ~mask),
                              unexpected_changed_pixels=int(np.count_nonzero(changed & ~mask))))

layout = [('idle',0,4,0),('walk',1,6,1),('windup',2,4,None),('attack',3,4,2),('hurt',4,1,3),('defeat',5,4,None)]
for mid in sorted({d['form'] for d in docs if d['kind'] == 'monster'}):
    p = ART / 'monsters' / (mid + '_sheet.png')
    expected_files.add(rel(p))
    current, checkpoint = pixels(p), previous(p)
    legacy_doc = by_id.get(f'legacy_sheet~{mid}~sheet')
    legacy = pixels(ROOT / legacy_doc['file']) if legacy_doc and legacy_doc['choice'] != 'none' else checkpoint
    lift = 7 if mid == 'jotunheim_rune_golem' else 0
    structural = [truth(mid + ': sheet dimensions', current.shape == (576,576,4)),
                  truth(mid + ': legacy dimensions',legacy.shape == (384,576,4))]
    bottom_rows, literal_changes, legacy_checks = {},{},[]
    for name,index,count,old_index in layout:
        start = len(checks)
        doc = by_id[f'monster~{mid}~{name}']
        actual = current[index*96:(index+1)*96,:count*96]
        if old_index is None:
            src = pixels(ROOT / doc['file'])
            truth(doc['doc'] + ': candidate canvas',src.shape[0] == 96 and src.shape[1] >= count*96 and src.shape[1] % 96 == 0)
            truth(doc['doc'] + ': unused candidate cells invisible',not np.any(src[:,count*96:,3]))
            expected = src[:,:count*96]
        else:
            src = legacy[old_index*96:(old_index+1)*96,:count*96]
            expected = np.zeros_like(src)
            expected[:96-lift] = src[lift:]
            truth(doc['doc'] + ': lift does not clip',not np.any(src[:lift,:,3]))
            prev = checkpoint[old_index*96:(old_index+1)*96,:count*96]
            literal_changes[name] = int(np.count_nonzero(np.any(actual != prev,axis=2)))
        result = check(doc['doc'],actual,expected)
        if old_index is not None:
            legacy_checks.append(result)
        truth(doc['doc'] + ': unused game cells invisible',not np.any(current[index*96:(index+1)*96,count*96:,3]))
        bottoms = []
        for f in range(count):
            ys = np.nonzero(actual[:,f*96:(f+1)*96,3])[0]
            bottoms.append(int(ys.max()) if len(ys) else None)
        bottom_rows[name] = {'per_frame':bottoms,'max':max(v for v in bottoms if v is not None)}
        rows.append({'doc':doc['doc'],'kind':'monster','choice':doc['choice'],'target':rel(p),
                     'ok':all(c['ok'] for c in checks[start:]),'checks':checks[start:],
                     'checkpoint_rgba_difference_pixels':literal_changes.get(name)})
    if legacy_doc:
        rows.append({'doc':legacy_doc['doc'],'kind':'legacy_sheet','choice':legacy_doc['choice'],'target':rel(p),
                     'ok':all(c['ok'] for c in legacy_checks),'checks':legacy_checks})
    monsters.append({'id':mid,'size':list(current.shape[1::-1]),'kept_source':legacy_doc['file'] if legacy_doc else f'{BASE}:{rel(p)}',
                     'legacy_lift_px':lift,'lowest_drawn_pixel_0based':bottom_rows,
                     'literal_checkpoint_changed_pixels_by_kept_row':literal_changes,'structure':structural})

diff = [line.split('\t') for line in git('diff','--name-status',BASE,'HEAD','--','smash-nine-prototype/assets').decode().splitlines()]
unexpected = [entry for entry in diff if entry[1] not in expected_files and not (entry[1].endswith('.png.import') and entry[1][:-7] in expected_files)]
actual_pngs = {p for _,p in diff if p.endswith('.png')}
truth('asset git diff contains only selected images and their import metadata',not unexpected, unexpected=unexpected)
truth('every expected adopted image appears in checkpoint diff',not (expected_files-actual_pngs),missing=sorted(expected_files-actual_pngs))
working = git('diff','HEAD','--name-only','--','smash-nine-prototype/assets','smash-nine-prototype/scripts','smash-nine-prototype/characters','smash-nine-prototype/scenes','smash-nine-prototype/project.godot').decode().splitlines()
truth('tracked product working tree remains unchanged',not working,paths=working)
truth('222 unique snapshot rows audited',len(rows)==222 and len({r['doc'] for r in rows})==222)
truth('every snapshot row is explicitly picked',all(d.get('picked') is True for d in docs))
totals = {}
for kind in sorted({r['kind'] for r in rows}):
    selected = [r for r in rows if r['kind']==kind]
    totals[kind] = {'checked':len(selected),'picked':sum(r['choice']!='none' for r in selected),
                    'none':sum(r['choice']=='none' for r in selected),'mismatches':sum(not r['ok'] for r in selected)}
out = {'checkpoint':BASE,'head':git('rev-parse','HEAD').decode().strip(),
       'method':'Independent RGBA array comparison against snapshot candidates and git-show checkpoint; no applied.json assertions used.',
       'summary':totals,'rows_checked':len(rows),'row_mismatches':sum(not r['ok'] for r in rows),
       'failed_checks':[c for c in checks if not c['ok']],'checks_count':len(checks),
       'literal_monster_none_rows_different_from_checkpoint':sum(v>0 for m in monsters for v in m['literal_checkpoint_changed_pixels_by_kept_row'].values()),
       'asset_diff':diff,'unexpected_asset_diff':unexpected,'expected_changed_images':sorted(expected_files),
       'sheet_preservation':preservation,'monsters':monsters,'rows':sorted(rows,key=lambda x:x['doc'])}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n','utf-8')
print(json.dumps({k:out[k] for k in ['summary','rows_checked','row_mismatches','checks_count','failed_checks','literal_monster_none_rows_different_from_checkpoint']},ensure_ascii=False,indent=2))
sys.exit(1 if out['row_mismatches'] or out['failed_checks'] else 0)
