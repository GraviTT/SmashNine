"""Small static QA boards; no product files changed."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
R = ROOT/'reports/codex-art-96a'
A = ROOT/'art/bakeoff/xion/b'
F = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',20)

def background(im, bg):
    out = Image.new('RGBA',im.size,bg); out.alpha_composite(im)
    return out.convert('RGB')

main = Image.open(A/'xion_illustration-b.png').convert('RGBA')
double = Image.open(A/'xion_double-b2-colour.png').convert('RGBA')
final = Image.open(A/'xion_illustration-b2.png').convert('RGBA')

board = Image.new('RGB',(1520,1600),'#2a2d34')
d = ImageDraw.Draw(board)
d.text((16,10),'B original: both arms / hands / matching shotguns, 2x crop',font=F,fill='white')
crop = background(main.crop((210,450,970,800)),'#2a2d34').resize((1520,700),Image.Resampling.NEAREST)
board.paste(crop,(0,45))
d.text((16,770),'Double colour: bent upper arm / two hands / matching pump shotguns, 2x crop',font=F,fill='white')
crop = background(double.crop((170,320,675,715)),'#c8c4b8').resize((1010,790),Image.Resampling.NEAREST)
board.paste(crop,(0,810))
face = Image.open(A/'xion_face-b.png').convert('RGBA')
board.paste(background(face,'#2a2d34').resize((480,480),Image.Resampling.NEAREST),(1030,920))
d.text((1040,845),'Existing B face / unchanged',font=F,fill='white')
board.save(R/'anatomy-checks.png')

# FrontendMenu.gd: hero_art Rect2(370,118,366,460), keep-aspect-centered.
# This is a static scale simulation, NOT a Godot screenshot.
preview = Image.new('RGB',(732,506),'#202329')
d = ImageDraw.Draw(preview)
for x,bg in [(0,'#2a2d34'),(366,'#c8c4b8')]:
    tile = Image.new('RGBA',(366,460),bg)
    thumb = final.resize((307,460),Image.Resampling.BILINEAR)
    tile.alpha_composite(thumb,((366-307)//2,0))
    preview.paste(tile.convert('RGB'),(x,46))
d.text((12,9),'Select-size simulation / 366 x 460 panel (not a game capture)',font=F,fill='white')
preview.save(R/'select-size-check.png')

sources = []
for filename,chosen in [('double-v1.png',False),('double-v2.png',True)]:
    p = ROOT/'art/raw/xion-96a'/filename
    sources.append({'file':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),
        'selected':chosen,'inspection':'Full-size raw/tool preview and opaque-background check',
        'reason':'Compact arm pose improves separation from unchanged B' if chosen else 'Valid standalone drawing; extended arm limited placement and caused excessive face overlap'})
provenance = {'tool':'built-in image_gen.imagegen','generation_count':2,
    'reference':'art/raw/xion-96a/reference-b.png',
    'prompts':['reports/codex-art-96a/prompt-double.txt','reports/codex-art-96a/prompt-double-v2.txt'],
    'second_generation_reference':'art/raw/xion-96a/double-v1.png',
    'sources':sources,'main_original_redrawn':False,'packages_installed':False,
    'manual_landmarks':{'double_crown_y':122,'double_chin_y':328,'double_sole_y':1454,
       'heads_tall_estimate':round((1454-122)/(328-122),3),
       'note':'Manually picked full-size landmarks; approximately +/-3px. Not automatic anatomy detection.'},
    'visual_review':{'full_size_final_dark_and_light':True,'full_size_colour_dark_and_light':True,
       'main_two_arms_hands_guns_boots':'Unchanged accepted original; checked full-size and 2x crops',
       'double_anatomy':'Two hands and two feet; far upper arm partly behind torso in a bent-elbow guard. No detached or extra limb seen.',
       'double_guns':'Two matching short pump shotguns, open thick bores, lower tubes, ribbed pumps and crimson receiver marks',
       'final_overlap':'Face and head clear. B scarf overlaps parts of double lower arm/grip; both gun muzzles readable.',
       'fringe':'No distracting light/green halo seen on either requested background; numerical test is narrower than visual judgment.'}}
(R/'provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Created anatomy-checks.png, select-size-check.png, provenance.json')
