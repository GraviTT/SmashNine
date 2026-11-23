from pathlib import Path
import json, shutil, subprocess, sys, os
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'reports/codex-art-97b'
RAW = ROOT / 'art/raw/xion-97b'
RAW.mkdir(parents=True, exist_ok=True)
(RAW / 'references').mkdir(exist_ok=True)
anchor = ROOT / 'art/bakeoff/xion/b/xion-idle-b2.png'
shutil.copy2(anchor, RAW / 'references/anchor.png')
Image.open(anchor).crop((0,0,128,128)).resize((512,512),Image.Resampling.NEAREST).save(RAW / 'references/anchor-f1-4x.png')
source = (ROOT / 'reports/codex-art-57/frey/make_walk_reference.py').read_text(encoding='utf-8')
source = source.replace('grey Frey', 'grey Xion').replace('walk_reference_frey', 'walk_reference_xion').replace('frey_pose_', 'xion_pose_')
source = source.replace('TORSO = (128, 136, 148, 255)', 'TORSO = (136, 136, 136, 255)').replace('TORSO_RIM = (76, 82, 92, 255)', 'TORSO_RIM = (82, 82, 82, 255)')
source = source.replace('head_r, torso_len, leg_len, stride = 51, 72, 104, 91', 'head_r, torso_len, leg_len, stride = 51, 90, 114, 64')
source = source.replace('vertical = (0, 15, 0, -14, 0, 15, 0, -14)[index]', 'vertical = (0, 8, -4, -8, 0, 8, -4, -8)[index]')
start = source.index('\t# Frey\'s far shield arm')
end = source.index('\n\tdraw.rectangle', start)
source = source[:start] + '''\t# Both low-held guns stay steady, as in the Xion idle.
\tshoulder = (hip_x + 2, shoulder_y + 14)
\tnear_arm = [shoulder, (hip_x + 27, shoulder_y + 60), (hip_x + 52, shoulder_y + 91)]
\tfar_arm = [(hip_x - 25, shoulder_y + 18), (hip_x - 43, shoulder_y + 57), (hip_x - 48, shoulder_y + 83)]
\t# ART-58 passing: support vertically under hip; swing beside ankle.
\tif index in (2, 6):
\t\tsupport = [(hip_x, hip_y), (hip_x, ground_y - 58), (hip_x, ground_y - 7), (hip_x + 22, ground_y)]
\t\tswing = [(hip_x - 4, hip_y + 4), (hip_x + 25, ground_y - 70), (hip_x + 1, ground_y - 45), (hip_x + 20, ground_y - 38)]
\t\tnear_leg, far_leg = (support, swing) if index == 2 else (swing, support)
''' + source[end:]
source = source.replace('\n\n\ndef main()', '''
\tfor arm, shade, rim in ((far_arm, FAR, FAR_RIM), (near_arm, NEAR, NEAR_RIM)):
\t\tx, y = arm[-1]
\t\tlimb(draw, [(x-3,y-5),(x+32,y+25),(x+53,y+42)],shade,rim,19)


def main()''')
(OUT / 'make_walk_reference.py').write_text(source, encoding='utf-8')
subprocess.run([sys.executable, str(OUT / 'make_walk_reference.py'), '--out', str(OUT / 'walk-reference.png'), '--panels-dir', str(RAW / 'references')],check=True)
(OUT / 'start.json').write_text(json.dumps({'start_utc':'2026-11-23T15:08:18Z','deadline_utc':'2026-11-23T17:08:18Z','disk_free_bytes':shutil.disk_usage(ROOT).free,'expected_new_bytes':'under 150 MB','branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()},indent=2),encoding='utf-8')
print('Prepared references; free GiB:',round(shutil.disk_usage(ROOT).free/2**30,2))
