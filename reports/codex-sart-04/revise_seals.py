"""Preserve v1/v2; add v3 alternatives after visual inspection."""
from PIL import ImageDraw
from build_candidates import canvas, color, line, poly, dot, outline, save_asset

def clear_v3():
    im=canvas((40,40)); d=ImageDraw.Draw(im)
    d.ellipse((4,4,35,35),fill=color('ink'))
    d.ellipse((5,5,34,34),fill=color('ochre'))
    d.ellipse((6,5,33,32),fill=color('gold'))
    d.arc((6,6,33,33),20,162,fill=color('ink'),width=1)
    d.ellipse((9,9,30,30),fill=color('ochre'))
    d.ellipse((10,10,29,29),fill=color('gold'))
    for xy in [(13,6),(28,9),(33,20),(26,32),(8,27)]:dot(im,xy,'ochre')
    r=canvas((40,40))
    poly(r,[(20,12),(22,17),(23,18),(28,20),(23,22),(22,23),
            (20,28),(18,23),(17,22),(12,20),(17,18),(18,17)],'blue')
    r=outline(r)
    line(r,[(20,15),(20,18),(18,20),(15,20)],'ice')
    poly(r,[(20,18),(22,20),(20,22),(18,20)],'ink')
    dot(r,(20,20),'ice')
    im.alpha_composite(r)
    line(im,[(9,12),(11,10),(13,9)],'blush')
    return im

def chain_link(dx,dy):
    im=canvas((40,40));d=ImageDraw.Draw(im)
    p=[(5,12),(12,5),(17,5),(25,13),(25,18),(18,25),(13,25),(5,17)]
    p=[(x+dx,y+dy) for x,y in p]
    d.polygon(p,fill=color('ink'))
    rim=[(7,12),(12,7),(17,7),(23,13),(23,18),(18,23),(13,23),(7,17),(7,12)]
    line(im,[(x+dx,y+dy) for x,y in rim],'blue')
    inner=[(10,13),(13,10),(16,10),(20,14),(20,17),(17,20),(14,20),(10,16)]
    d.polygon([(x+dx,y+dy) for x,y in inner],fill=(0,0,0,0))
    line(im,[(11+dx,18+dy),(14+dx,21+dy),(17+dx,21+dy),(21+dx,17+dy)],'violet')
    line(im,[(8+dx,12+dy),(12+dx,8+dy)],'ice')
    return im

def locked_v3():
    im=canvas((40,40))
    a=chain_link(0,0);b=chain_link(9,9)
    im.alpha_composite(a);im.alpha_composite(b)
    # One crossover passes back in front: this is a linked chain rather than two rings.
    patch=a.crop((17,18,24,25))
    im.alpha_composite(patch,(17,18))
    return im

save_asset('map_seal_clear',3,clear_v3(),note='v2의 세 마름모가 A처럼 보일 수 있어 수정. 금색 원형 도장에 문자와 닮지 않은 네 방향 씨앗별 룬을 새로 그렸다.')
save_asset('map_seal_locked',3,locked_v3(),note='v2가 하나의 마름모 테두리로 보일 수 있어 수정. 두 개의 철제 사슬 고리와 각각의 빈 구멍, 앞뒤 교차를 명확히 분리했다.')
