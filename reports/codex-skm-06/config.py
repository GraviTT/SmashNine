from pathlib import Path
ROOT = Path('reports/codex-skm-06')
ANCHOR = 'art/bakeoff/xion/b/xion-idle-b2.png'
REFS = [str(Path(p).resolve()) for p in [ANCHOR, 'art/bakeoff/xion/b/xion-shot-v1.png']]
ROWS = {
    'shot': (18, False, 'J 옆 사격(오른손)'),
    'shot_alt': (16, False, 'J 옆 사격(왼손)'),
    'double_float': (10, True, 'U 도플갱어 부유'),
    'tumble': (21, True, 'K 장전 구르기·강한 날림'),
    'recoil_jump': (33, False, 'L 반동 도약'),
    'barrage': (14, True, 'I 이퀄리브리엄 사방 난사'),
    'dive': (27, False, 'U 재입력 도플갱어로 날아들기'),
    'double_cast': (14, False, 'U 도플갱어 호출'),
    'shot_up': (13, False, 'J 위 사격'),
    'shot_down': (26, False, '지상 J 아래 사격'),
    'shot_air_down': (30, False, '공중 J 아래 사격'),
}
