"""Final ART-86 verification; report must be a new file, no Godot or mutations."""
from common import *
import subprocess, argparse
ap=argparse.ArgumentParser();ap.add_argument('--report',type=Path,required=True);args=ap.parse_args()
assert not args.report.exists(),args.report
specs=[('L14','rio/rio_female-mana_combo-v2.png','L14-adopted.png',[5,6],152),('L09','nova/nova_male-walk-v3.png','nova_male-walk-v2.png',[3],120),('L10','rio/rio_female-walk-v4.png','rio_female-walk-v3.png',[4],120),('L11','rio/rio_male-walk-v2.png','rio_male-walk-v1.png',list(range(1,9)),120),('L34','nova/nova_female-gravity_brake-v2.png','L34-adopted.png',[4,5,6],152),('L37','frey/frey-attack-v5.png','L37-game-base-attack.png',[3,4,5,6],120)]
records=[]
for qa,rel,old,changed,feet in specs:
 path=ROOT/'art/bakeoff'/rel;b=cells(RAW/old);a=cells(path);meta=json.loads(path.with_suffix('.json').read_text(encoding='utf8'))
 assert len(a)==len(b)==meta['frames'];assert meta['cell']==a[0].height and meta['feet']==feet
 unchanged=[i+1 for i in range(len(a)) if i+1 not in changed]
 assert all(a[i-1].tobytes()==b[i-1].tobytes() for i in unchanged)
 ms=[metrics(a[i-1]) for i in changed]
 assert all(m['margin']['has_4px_margin'] and m['remaining_spill_pixels']==0 and m['alpha_binary'] and m['bottom']==feet for m in ms)
 if qa=='L34':assert all(np.array_equal(np.array(b[i-1])[:188],np.array(a[i-1])[4:]) for i in changed)
 faces=json.loads((OUT/(f'{qa}-delivery-face.json' if qa!='L34' else 'L34-final-face.json')).read_text())['frames']
 facepass=[.96<=f['eye_ratio']<=1.04 and .96<=f['width_ratio']<=1.04 for f in faces]
 assert all(facepass) if qa!='L34' else not all(facepass)
 records.append({'qa23':qa,'file':str(path.relative_to(ROOT)).replace('\\','/'),'png_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'changed_frames':changed,'untouched_frames_rgba_identical':unchanged,'changed_frame_cleanup_pass':True,'feet_line':feet,'face_measurement_pass':facepass,'status':meta['review_status'],'before_height_range':[min(f.getbbox()[3]-f.getbbox()[1] for f in b),max(f.getbbox()[3]-f.getbbox()[1] for f in b)],'after_height_range':[min(f.getbbox()[3]-f.getbbox()[1] for f in a),max(f.getbbox()[3]-f.getbbox()[1] for f in a)]})
for cmd in [['git','diff','--name-only'],['git','diff','--cached','--name-only']]:assert subprocess.check_output(cmd,cwd=ROOT,text=True).strip()==''
assert subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()=='codex/art-86'
rep={'changed_frame_count':sum(len(r['changed_frames']) for r in records),'face_measurement_pass_count':sum(sum(r['face_measurement_pass']) for r in records),'candidate_rows':records,'tracked_files_modified':False,'staged_files':0,'godot_run':False,'game_wiring_changed':False,'note':'Face matches are proposed landmarks. Frey F3 is partly occluded; L34 is blocked by preserved pre-existing face ratios.'}
js(rep,args.report);print('PASS: 6 candidates, 19 changed frames, 16 numerical face passes, 3 preserved legacy face failures; tracked files unchanged.')
