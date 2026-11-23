"""Package reviewed candidate images and measured metadata, never game files."""
from pathlib import Path
import hashlib
import json
import shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-art-97a-fix'
RAW = ROOT / 'art/raw/xion-97a'
OUT = ROOT / 'art/bakeoff/xion/b'


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


notes = {
    'victory': '승리 6프레임. 기존 채택 원본을 공통 가로 기준 x=178.5, factor 0.230으로 재정규화. 부츠 인접 이동 최대 13→0.5px. 마지막 프레임 유지용. 후보이며 게임 미연결.',
    'defeat': '패배 6프레임: 반동→뒤로 비틀거림→무릎 꺾임→뒤로 넘어짐→바닥 충돌→누워 정지. 3포즈씩 두 장, 공통 factor 0.205와 가로 기준 x=256. 머리 중앙값 0.96(앞 3프레임 유효), 뒤 3프레임은 4배 육안 확인. 마지막 프레임 유지용. 후보이며 게임 미연결.',
}
data = {'tool': 'builtin image_gen.imagegen', 'generation_count_this_fix': 3, 'rows': {}}
for row, factor, fps in [('victory', 0.230, 8), ('defeat', 0.205, 10)]:
    folder = REPORT / f'{row}-normalized'
    shutil.copyfile(folder / f'{row}.png', OUT / f'xion-{row}-b2.png')
    dump(OUT / f'xion-{row}-b2.json', {'note': notes[row], 'fps': fps, 'frames': 6, 'loop': False})
    m = json.loads((folder / 'metrics.json').read_text(encoding='utf-8'))
    head = json.loads((folder / 'heads.json').read_text(encoding='utf-8'))[0]
    data['rows'][row] = {
        'delivered': True, 'frames': 6, 'fps': fps, 'cell': 192, 'feet_y': 152,
        'factor': factor, 'shared_source_anchor_x': m['normalization']['fixed_source_anchor_x'],
        'head_scale': head, 'detail': {
            'range': m['summary']['interior_detail_range'],
            'mean': m['summary']['interior_detail_mean'],
            'anchor_mean': m['summary']['reference_interior_detail_mean'],
            'ratio_to_anchor': m['summary']['interior_detail_ratio'],
            'per_frame': [f['interior_detail'] for f in m['frames']],
        },
        'border_clear': m['summary']['borders_clear'],
        'margin_min_px': min(f['margin']['minimum'] for f in m['frames']),
        'spill_pixels': sum(m['summary']['remaining_spill_pixels']),
        'body_height_range': m['summary']['body_height_range'],
        'alpha_binary': m['summary']['alpha_binary'],
        'source_cell_boundaries_clear': True,
        'visual_review': '앵커와 같은 픽셀 배율로 최근접 4배 확대, 전체 6프레임 직접 확인. 수치 검사를 대신하는 미술 점수는 아님.',
    }
feet = json.loads((REPORT / 'feet.json').read_text(encoding='utf-8'))
data['rows']['victory']['feet'] = {
    'before_max_neighbour_dx_px': feet['before_max_abs_dx'],
    'after_max_neighbour_dx_px': feet['after_max_abs_dx'],
    'subject_rgba_unchanged_all_frames': all(feet['unchanged_cropped_rgba']),
}
data['rows']['victory']['limitations'] = [
    'F5 자동 머리 배율 1.06이지만 수정 전후 피사체 RGBA는 동일. 머리 변화가 아닌 위치에 따른 자동 매칭 변화. 중앙값은 1.00.',
]
data['rows']['defeat']['feet'] = {
    'method': 'F1-F3만 y148..152 불투명 부츠 구간. F4 이후 총/스카프/겹친 부츠가 같은 줄에 있으므로 전체 알파 구간을 발로 오인하지 않음.',
    'standing_boot_centres_x': [[82.5, 122.5], [75.0, 104.0], [78.0, 104.0]],
    'standing_max_neighbour_dx_px': 18.5,
    'standing_movement_is_intentional_stagger': True,
    'frame4_boot_centres_x': [112.0, 125.0],
    'frame5_6_individual_boot_measurement': None,
    'bottom_all_frames': [152] * 6,
    'body_contact_frame5_6': '4배/좌표판에서 팔·손과 총이 바닥에 나란히 닿고 몸은 옆으로 누움. 부츠 자체가 유일한 최저점인 것은 아님.',
}
data['rows']['defeat']['limitations'] = [
    'F1 반동은 작다. F4는 낮게 주저앉으며 뒤로 기우는 자세로, 큰 공중 회전이 아니다.',
    'F4-F6은 기울거나 누운 얼굴로 자동 머리 매칭 점수 0.6 미만. 중앙값에서 제외하고 4배 비교로 확인.',
    '한쪽 눈과 얼굴 왼쪽 윤곽이 앞머리에 가려 양 눈 거리/눈높이 전체 얼굴 너비의 독립 정밀 측정은 불가.',
    'F5-F6 스카프 일부가 머리/팔 뒤로 접혀 ±10% 실제 천 길이를 정확히 계측할 수 없음. 두 꼬리 존재와 의상 연속성은 육안 확인.',
]
dump(REPORT / 'metrics.json', data)
feet['defeat'] = data['rows']['defeat']['feet']
dump(REPORT / 'feet.json', feet)

sources = ['anchor-f1-4x.png', 'xion-idle-b2.png', 'victory-2.png', 'defeat-fix-123.png', 'defeat-fix-456.png', 'defeat-fix-123-r2.png']
provenance = {'tool': 'builtin image_gen.imagegen', 'generations_this_fix': 3, 'victory_regenerated': False,
    'selected_defeat': ['defeat-fix-123-r2.png', 'defeat-fix-456.png'],
    'discarded_defeat': {'defeat-fix-123.png': '앵커보다 긴 몸 비례와 낮은 얼굴 매칭. 마지막 허용 생성으로 F1-F3 재작성.'},
    'sources': []}
for filename in sources:
    path = RAW / filename
    provenance['sources'].append({'path': str(path.relative_to(ROOT)).replace('\\', '/'), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'size': list(Image.open(path).size)})
dump(REPORT / 'provenance.json', provenance)

# Compact visual summary: genuine final candidate pixels, not a generated mockup.
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 20)
preview = Image.new('RGB', (1536, 2 * 482), '#242c3c')
d = ImageDraw.Draw(preview)
for rownum, row in enumerate(('victory', 'defeat')):
    sheet = Image.open(OUT / f'xion-{row}-b2.png').convert('RGBA')
    for col, index in enumerate((0, 3, 5)):
        cell = sheet.crop((index * 192, 0, (index + 1) * 192, 192))
        # Identical viewport for every pose: no per-frame resizing or placement.
        crop = cell.crop((32, 48, 160, 160)).resize((512, 448), Image.Resampling.NEAREST)
        x, y = col * 512, rownum * 482
        preview.paste(crop, (x, y + 34), crop)
        d.text((x + 16, y + 5), f'{row.upper()} F{index + 1} | 4X', font=font, fill='white')
        d.line((x, y + 34 + 105 * 4, x + 511, y + 34 + 105 * 4), fill='#5abdeb', width=2)
preview.save(REPORT / 'delivery-preview.png')
print(json.dumps({k: {'factor': v['factor'], 'head': v['head_scale']['median'], 'margin': v['margin_min_px'], 'detail': v['detail']['range']} for k, v in data['rows'].items()}, ensure_ascii=False))
