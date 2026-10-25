from PIL import Image, ImageDraw
from review_assets import ROOT, DIR, BG, PANEL, GOLD, DIM, drawtext, put, box, asset, frame

picked={'map_path_tile':1,'map_marker_next':2,'map_seal_clear':1,'map_seal_locked':1,'shadow_dissolve':1}

im=Image.new('RGB',(676,242),BG)
drawtext(im,(24,12),'추천 조합 · 실제 셀 간격 214px · 합성 모형',20,GOLD)
tile=asset('map_path_tile',1)
for x in range(122,550,32):put(im,tile,(x,123))
for j,(emblem,label,name,v) in enumerate([
    ('asgard','CLEAR','map_seal_clear',1),
    ('yggdrasil_heart','NEXT','map_marker_next',2),
    ('niflheim','LOCKED','map_seal_locked',1),
]):
    x=24+j*214;y=58
    box(im,(x,y,x+195,y+151),PANEL,(73,83,110))
    e=Image.open(ROOT/f'smash-nine-prototype/assets/art/ui/realm_emblems/{emblem}.png').convert('RGBA')
    e=e.resize((96,96),Image.Resampling.NEAREST)
    if j==2:e.putalpha(e.getchannel('A').point(lambda p:round(p*.3)))
    put(im,e,(x+50,y+4))
    a=asset(name,v)
    if name=='map_marker_next':a=frame(a,0,48)
    put(im,a,(x+150-(4 if name=='map_marker_next' else 0),y+101))
    drawtext(im,(x+16,y+117),label,15,DIM)
im.save(DIR/'mock-map-recommended.png')

cover=Image.new('RGB',(1448,1080),BG)
drawtext(cover,(24,16),'SART-04 · 추천 후보 5종',34,GOLD)
drawtext(cover,(24,66),'게임 미반영 · 자산마다 통과 후보 2개 · 최초안과 수정안 모두 보존',21,DIM)
cover.paste(im,(24,112))
drawtext(cover,(752,128),'자체 검수 결과',25,GOLD)
drawtext(cover,(752,178),'기술 규격 74 / 74 PASS',22)
drawtext(cover,(752,220),'의미 전달 10 PASS / 초기 2 FAIL',22)
drawtext(cover,(752,262),'소멸 최소 여백 11 / 12px (기준 4px)',22)
drawtext(cover,(752,304),'완료 v2와 잠금 v2 → v3 보완',22,DIM)

items=[('map_path_tile',1,'길 v1'),('map_marker_next',2,'다음 v2'),
       ('map_seal_clear',1,'완료 v1'),('map_seal_locked',1,'잠금 v1')]
for j,(name,v,label) in enumerate(items):
    x=24+j*276
    drawtext(cover,(x,388),label+' · 4×',22,GOLD)
    a=asset(name,v)
    if name=='map_marker_next':a=frame(a,0,48)
    put(cover,a,(x+20,436),4)
drawtext(cover,(1140,388),'대안 · v3',22,GOLD)
put(cover,asset('map_seal_clear',3),(1140,440),3)
put(cover,asset('map_seal_locked',3),(1280,440),3)
drawtext(cover,(1140,580),'완료 / 사슬',18,DIM)

drawtext(cover,(24,674),'그림자 소멸 v1 · 192×192 × 6 · 12fps 단발 · 아래는 1×',24,GOLD)
put(cover,asset('shadow_dissolve',1),(128,730))
drawtext(cover,(24,978),'사람 확인: 잎·잠금의 1× 가독성, 불꽃 루프, 0.5초 소멸의 자연스러움',22,DIM)
cover.save(DIR/'recommended.png',optimize=True)
print('recommended.png and mock-map-recommended.png saved')
