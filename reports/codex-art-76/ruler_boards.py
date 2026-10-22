"""Evidence-only pixel grids; generated art is never edited here."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
from PIL import Image, ImageDraw
import process as p
IDS=['muspelheim_magma_boar','niflheim_glacier_wolf','niflheim_frost_owl','jotunheim_storm_wisp','yggdrasil_root_guardian','yggdrasil_root_oracle']
for mid in IDS:
    board=Image.new('RGB',(4*432,3*440+32),(24,29,40));d=ImageDraw.Draw(board)
    d.text((8,4),mid+' | representative first / last frames, pixel coordinates',font=p.n.font(16),fill='white')
    for ri,row in enumerate(p.ROWS):
        frames=p.frames(p.BAKE/f'{mid}-{row}-v1.png',p.COUNTS[row])
        for j,fi in enumerate([0,len(frames)-1]):
            col=(ri%2)*2+j;line=ri//2;x=col*432+40;y=32+line*440+36
            tile=p.n.checker((96,96)).convert('RGB');tile.paste(frames[fi],(0,0),frames[fi]);tile=tile.resize((384,384),Image.Resampling.NEAREST)
            board.paste(tile,(x,y));d.text((x,y-32),f'{row} F{fi+1}',font=p.n.font(18),fill='white')
            for k in range(0,97,8):
                d.line((x+4*k,y,x+4*k,y+384),fill=(75,78,95),width=1);d.line((x,y+4*k,x+384,y+4*k),fill=(75,78,95),width=1)
                if k<96:d.text((x+4*k,y-14),str(k),font=p.n.font(10),fill='white');d.text((x-26,y+4*k),str(k),font=p.n.font(10),fill='white')
    board.save(p.REPORT/f'{mid}-rulers.png')
