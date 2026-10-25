"""Current game has four rows only: add an explicitly labelled idle reference for new states."""
from PIL import Image
import repair as r
for mid,row in [('vanaheim_vine_hound','windup'),('vanaheim_vine_hound','defeat'),('alfheim_moon_moth','windup')]:
 game=Image.open(r.RAW/'references'/f'{mid}_current.png').convert('RGBA')
 idle=[game.crop((i*96,0,(i+1)*96,96)) for i in range(4)]
 parts=[r.panel(idle,f'CURRENT GAME IDLE reference / no {row} row / 1x',1),r.panel(idle,f'CURRENT GAME IDLE reference / no {row} row / 4x',4),Image.open(r.REPORT/f'{mid}-{row}.png')]
 out=Image.new('RGB',(1200,sum(x.height for x in parts)),(24,29,40));y=0
 for p in parts:out.paste(p,(0,y));y+=p.height
 r.save(r.REPORT/f'{mid}-{row}-with-current.png',out)
