"""Explicit final-file allowlist. Never discovers files by a directory wildcard."""
from common import *
paths=['design/tasks/CODEX-ART-86.md','design/tasks/CODEX-ART-86.prompt.md']
for row in ['rio/rio_female-mana_combo-v2','nova/nova_male-walk-v3','rio/rio_female-walk-v4','rio/rio_male-walk-v2','nova/nova_female-gravity_brake-v2','frey/frey-attack-v5']:
 for ext in ['png','json']:paths.append(f'art/bakeoff/{row}.{ext}')
reports=['README.md','prompts.txt','commit.ps1','commit-paths.txt','commit-message.txt','common.py','rebuild.py','verify_delivery.py','face_audit_v3.py','proof_boards.py','create_commit_manifest.py','candidate-validation.json','rio-walk-validation.json','source-provenance.json','reproduction-check.json','verification-final.json','handoff-comparison.png','L14-raw-result.png','L37-raw-result.png','rio_female-mana_combo.png','nova_male-walk.png','rio_female-walk.png','rio_male-walk.png','nova_female-gravity_brake-delivery.png','frey-attack-delivery.png','L09-ready-4x.png','L10-ready-4x.png','L14-final-4x.png','L34-changed-4x.png','L37-selected-3-4.png','L37-selected-5-6.png','L11-delivery-1-2.png','L11-delivery-3-4.png','L11-delivery-5-6.png','L11-delivery-7-8.png','L09-bob.json','L10-bob.json','L11-bob-final.json','L11-bob-final.png','L11-feet-final.json','L11-onion-final.png','L09-delivery-feet.json','L09-delivery-onion.png','L10-delivery-feet.json','L10-delivery-onion.png','L34-measurements.json','L28-v2-checked.json','L28-v3-checked.json','nova_female-hurt-v2-check.png','L28-active-v3-4x.png','rio_female-attack-check-1.png','rio_female-attack-check-2.png','rio_male-attack-check-1.png','rio_male-attack-check-2.png','rio_female-attack-existing.json','rio_male-attack-existing.json']
for tag in ['L09-delivery','L10-delivery','L11-delivery','L14-delivery','L37-delivery','L34-final','L35-existing','L36-existing']:
 reports.extend([f'{tag}-face.json',f'{tag}-landmarks.png'])
reports.extend(['l14_position_review.py','L14-position-review.json'])
paths.extend(f'reports/codex-art-86/{x}' for x in reports)
assert len(paths)==len(set(paths))
for rel in paths:
 assert not any(x in rel for x in ['art/raw/','qa23/','__pycache__','run.log'])
 if not rel.endswith('/commit-paths.txt'):assert (ROOT/rel).is_file(),rel
manifest=OUT/'commit-paths.txt'
with manifest.open('x',encoding='utf8',newline='\n') as f:f.write('\n'.join(paths)+'\n')
print('Explicit commit allowlist:',len(paths),'files')
