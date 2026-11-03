"""Hand-pixelled UI permitted by CODEX-VFX-05. No antialiasing."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
NAVY = '#0b1024'
DEEP = '#302356'
VIOLET = '#7955d9'
LILAC = '#b997fa'
CYAN = '#38d5e4'
WHITE = '#d5fcff'


def save(im, path, replaces, note):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)
    meta = dict(note=note, replaces=replaces, frames=1, fps=0,
                anchor=[im.width // 2, im.height // 2], loop=False)
    path.with_suffix('.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def stages():
    for variant in 'ab':
        for stage in (1, 2, 3):
            im = Image.new('RGBA', (24, 24))
            d = ImageDraw.Draw(im)
            if variant == 'a':
                d.ellipse((2, 2, 21, 21), outline=NAVY, width=3)
                d.ellipse((3, 3, 20, 20), outline=VIOLET, width=1)
                d.ellipse((7, 7, 16, 16), fill=NAVY, outline=LILAC if stage == 3 else VIOLET)
                d.rectangle((10, 10, 13, 13), fill=DEEP)
                for index, (x, y) in enumerate(((12, 3), (20, 16), (4, 16))):
                    d.rectangle((x-3, y-3, x+2, y+2), fill=NAVY)
                    d.rectangle((x-2, y-2, x+1, y+1), fill=CYAN if index < stage else DEEP)
                    if index < stage:
                        d.rectangle((x-1, y-2, x, y-1), fill=WHITE)
                if stage == 3:
                    d.rectangle((10, 15, 13, 16), fill=CYAN)
                    d.rectangle((10, 6, 13, 7), fill=CYAN)
            else:
                # The same three-tier gravity well fills from top to bottom.
                for index, (y, width) in enumerate(((5, 18), (11, 14), (17, 8))):
                    x = 12 - width // 2
                    d.ellipse((x-1, y-2, x+width, y+4), fill=NAVY)
                    d.ellipse((x, y-1, x+width-1, y+3), fill=VIOLET if index < stage else DEEP)
                    d.line((x+2, y+2, x+width-3, y+2), fill=CYAN if index < stage else '#4b3875', width=2)
                    d.line((x+3, y, x+width-4, y), fill=NAVY)
                if stage == 3:
                    d.rectangle((10, 19, 13, 20), fill=WHITE)
                    d.rectangle((11, 21, 12, 21), fill=CYAN)
            # Art contract: empty outermost row/column.
            d.rectangle((0, 0, 23, 0), fill=(0, 0, 0, 0))
            d.rectangle((0, 23, 23, 23), fill=(0, 0, 0, 0))
            d.rectangle((0, 0, 0, 23), fill=(0, 0, 0, 0))
            d.rectangle((23, 0, 23, 23), fill=(0, 0, 0, 0))
            save(im, f'art/bakeoff/ui/status/nova_gravity_{stage}-{variant}-v1.png',
                 f'assets/art/ui/status/nova_gravity_{stage}.png',
                 f'중력 중첩 {stage}단계. ' + ('궤도 위 위성이 하나씩 밝아지는 A형.' if variant == 'a' else '중력 우물의 층이 위에서 아래로 채워지는 B형.'))


def fist(d, x, y, colour):
    pts = [(x,y+2),(x+2,y),(x+8,y),(x+10,y+2),(x+10,y+8),
           (x+7,y+10),(x+1,y+10),(x-1,y+7),(x-1,y+4)]
    d.polygon(pts, fill=colour, outline=NAVY)
    d.rectangle((x+2,y+2,x+7,y+4), fill=WHITE)
    d.line((x+4,y+1,x+4,y+4), fill=colour)
    d.line((x+7,y+1,x+7,y+4), fill=colour)
    d.line((x,y+6,x+3,y+6,x+3,y+8), fill=NAVY)


def icons():
    for key in 'jklui':
        im = Image.new('RGBA', (40, 40))
        d = ImageDraw.Draw(im)
        if key == 'j':
            d.line((3, 11, 11, 11), fill=DEEP, width=3)
            d.line((4, 20, 17, 20), fill=VIOLET, width=3)
            d.line((9, 29, 24, 29), fill=CYAN, width=3)
            fist(d, 9, 5, VIOLET)
            fist(d, 18, 14, LILAC)
            fist(d, 26, 24, CYAN)
        elif key == 'k':
            d.ellipse((7, 7, 33, 33), fill=NAVY, outline=DEEP, width=2)
            d.arc((8, 8, 32, 32), 30, 222, fill=VIOLET, width=3)
            d.arc((10, 10, 30, 30), 205, 355, fill=CYAN, width=3)
            d.line([(30,17),(28,24),(22,28),(16,25),(14,20),(17,16),(22,16),(24,19)], fill=LILAC, width=2)
            d.polygon([(22,18),(25,18),(25,22),(21,21)], fill=CYAN)
            d.line((3, 15, 7, 13), fill=VIOLET, width=2)
            d.rectangle((29, 4, 31, 6), fill=CYAN)
            d.rectangle((5, 29, 7, 31), fill=LILAC)
        elif key == 'l':
            d.ellipse((3, 3, 36, 36), outline=NAVY, width=4)
            d.ellipse((4, 4, 35, 35), outline=VIOLET, width=2)
            d.arc((5, 5, 34, 34), 195, 320, fill=CYAN, width=2)
            d.ellipse((9, 27, 30, 32), outline=DEEP, width=2)
            d.rectangle((18, 11, 21, 14), fill=WHITE)
            d.polygon([(18,16),(21,16),(23,21),(27,19),(28,21),(23,24),(21,21),(21,26),(24,29),(22,31),(19,27),(16,30),(14,28),(17,24),(17,20),(13,23),(11,21),(16,17)], fill=CYAN)
            d.rectangle((8, 17, 9, 20), fill=LILAC)
            d.rectangle((30, 17, 31, 20), fill=LILAC)
        elif key == 'u':
            d.line((5, 15, 28, 15), fill=NAVY, width=6)
            d.line((6, 15, 28, 15), fill=VIOLET, width=4)
            d.line((6, 14, 29, 14), fill=WHITE, width=2)
            d.polygon([(26,5),(34,9),(37,15),(34,22),(28,25),(24,20),(27,20),(31,18),(32,14),(29,11),(26,11)], fill=NAVY)
            d.line([(28,7),(33,11),(35,15),(32,20),(28,22),(26,20)], fill=CYAN, width=3)
            d.polygon([(5,30),(12,24),(12,28),(27,28),(27,32),(12,32),(12,36)], fill=NAVY)
            d.polygon([(7,30),(12,26),(12,29),(26,29),(26,31),(12,31),(12,34)], fill=LILAC)
        else:
            d.ellipse((7, 7, 32, 32), fill=NAVY, outline=VIOLET, width=2)
            d.ellipse((10, 10, 29, 29), fill='#03040d')
            d.arc((3, 10, 36, 29), 5, 180, fill=CYAN, width=2)
            d.arc((4, 6, 35, 33), 180, 325, fill=LILAC, width=2)
            for x, y, c in ((5,14,CYAN),(30,7,LILAC),(32,28,CYAN)):
                d.rectangle((x-2,y-2,x+2,y+2), fill=NAVY)
                d.rectangle((x-1,y-1,x+1,y+1), fill=c)
            d.line((14, 31, 20, 33), fill=VIOLET, width=2)
        descriptions = {'j':'짧은 궤적을 가진 세 주먹: 벡터 연타.', 'k':'안쪽 나선이 감기는 중력 구체.',
                        'l':'원형 필드 속 떠 있는 작은 사람.', 'u':'갈고리 광선과 시전자 쪽으로 돌아오는 화살표.',
                        'i':'검은 중심 구체와 공전하는 세 점: 사건의 지평선.'}
        save(im, f'art/bakeoff/skill_icons/nova/nova_{key}-v1.png',
             f'assets/art/skill_icons/nova_{key}.png', descriptions[key])


if __name__ == '__main__':
    stages()
    icons()
    print('UI: 6 marks + 5 icons written (binary alpha, native pixel drawing).')
