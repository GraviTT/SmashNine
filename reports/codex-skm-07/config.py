from pathlib import Path
ROOT = Path('reports/codex-skm-07')
ANCHOR = 'art/bakeoff/xion/b/xion-idle-b2.png'
REFS = [str(Path(p).resolve()) for p in [ANCHOR, 'art/bakeoff/xion/b/xion_illustration-b2.png', '../skm-07-airpose-ref.png']]
ROWS = {
    'shot_air_down': (30, False, '공중 J 아래 사격'),
}
