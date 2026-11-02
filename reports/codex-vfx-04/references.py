from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
paths = [
    'smash-nine-prototype/assets/art/effects/skill/luna_comet_burst.png',
    'smash-nine-prototype/assets/art/effects/skill/luna_brave_aura.png',
    'smash-nine-prototype/assets/art/effects/luna_star.png',
    'smash-nine-prototype/assets/art/vfx/luna_ult_transform.png',
    'smash-nine-prototype/assets/art/ui/status/stun.png',
    'smash-nine-prototype/assets/art/ui/status/super_armor.png',
    'smash-nine-prototype/assets/art/ui/status/luna_star_charge.png',
]
paths += [str(p.relative_to(ROOT)).replace('\\', '/') for p in sorted((ROOT/'smash-nine-prototype/assets/art/skill_icons').glob('*.png')) if '_source' not in p.name]
board = Image.new('RGB', (1200, 1260), '#151c2e')
d = ImageDraw.Draw(board)
for i, p in enumerate(paths):
    im = Image.open(ROOT/p).convert('RGBA')
    if i < 4:
        n = [6,6,1,8][i]
        w = im.width//n
        im = im.crop((min(2,n-1)*w,0,(min(2,n-1)+1)*w,im.height))
    im.thumbnail((160,160), Image.Resampling.NEAREST)
    if i >= 4:
        im = im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST)
    x,y = (i%6)*200, (i//6)*210
    d.text((x+5,y+3),Path(p).stem,fill='white')
    board.paste(im,(x+15,y+30),im)
board.save(ROOT/'reports/codex-vfx-04/reference-contact.png')
