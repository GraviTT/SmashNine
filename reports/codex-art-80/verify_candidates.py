"""Read saved ART-80 outputs back and verify format, provenance, alpha and replay."""
from pathlib import Path
import hashlib
import json
import importlib.util
import numpy as np
from PIL import Image

REPORT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('art80_build', REPORT / 'build_candidates.py')
b = importlib.util.module_from_spec(spec)
spec.loader.exec_module(b)
results = {}
for folder, stem, label, attempt, eye in b.FORMS:
    p = b.ROOT / f'art/bakeoff/{folder}/{stem}_face-shadow-v1.png'
    meta = json.loads(p.with_suffix('.json').read_text(encoding='utf-8'))
    source = b.ROOT / meta['edited_from']
    raw = b.ROOT / meta['source_raw']
    neutral = Image.open(source).convert('RGBA')
    candidate = Image.open(p)
    n, a = np.array(neutral), np.array(candidate)
    edit = Image.open(raw).convert('RGBA').resize((256,256), Image.Resampling.LANCZOS)
    best, scores, roi = b.align(neutral, edit, stem)
    replay, padded, radius = b.clean_alpha(b.shift(edit,*best['offset']), neutral)
    measures = meta['measurements']
    checks = {
        'rgba_256': candidate.mode == 'RGBA' and candidate.size == (256,256),
        'alpha_exact': np.array_equal(n[:,:,3], a[:,:,3]),
        'neutral_transparency_respected': not np.any(a[:,:,3][n[:,:,3]==0]),
        'transparent_rgb_zero': not np.any(a[:,:,:3][a[:,:,3]==0]),
        'replay_exact': np.array_equal(a, np.array(replay)),
        'offset_recalculated': best['offset'] == meta['offset'],
        'source_copy_hash_equal': hashlib.sha256(source.read_bytes()).hexdigest() == hashlib.sha256((b.RAW/f'{stem}-neutral.png').read_bytes()).hexdigest() == measures['original_sha256'],
        'candidate_hash_equal': hashlib.sha256(p.read_bytes()).hexdigest() == measures['candidate_sha256'],
        'candidate_metadata': meta['expression']=='shadow' and meta['review_status']=='candidate' and meta['delivered'] is True and meta['candidate_only'] is True,
        'korean_note': any(0xAC00 <= ord(c) <= 0xD7A3 for c in meta['note']),
        'selected_try_and_limit': meta['selected_try']==attempt and 1<=meta['tries']<=3,
        'board_present': (REPORT/f'{stem}-shadow.png').is_file(),
        'padding_measurements_equal': padded==measures['alpha_padding_pixels'] and radius==measures['alpha_padding_radius'],
    }
    results[stem] = checks
    assert all(checks.values()), (stem, checks)
result = {'passed': True, 'forms': len(results), 'checks_per_form': len(checks), 'results': results,
    'scope': 'Saved candidate PNG/JSON and source files only. No Godot or runtime test.'}
b.dump(REPORT/'verification.json', result)
print('PASS:',len(results),'forms;',len(checks),'checks each')
