from common import *
from rebuild import l14_sources
# Source/result evidence, kept as boards rather than raw image dumps.
raw=Image.open(RAW/'L14-source.png').convert('RGB');raw=raw.resize((768,512),Image.Resampling.LANCZOS)
im=Image.new('RGB',(1726,1400),(24,30,43));d=ImageDraw.Draw(im)
d.text((10,10),'L14 raw: rio-61b/mana_combo/source.png | crop (515,515)-(1533,1021)',fill='white',font=n.font(20));im.paste(raw,(20,50))
d.rectangle((20+515//2,50+515//2,20+1533//2,50+1021//2),outline='yellow',width=2)
d.text((820,100),'Blade crosses the F5/F6 divider.',fill='white',font=n.font(22));d.text((820,140),'Keep blade y776:802 across x1020:1028.',fill='white',font=n.font(19))
d.text((820,180),'F5 body +8px; original factor 0.260 preserved.',fill='white',font=n.font(19));d.text((820,220),'Only blade width 56 > 48px; source tip retained.',fill='white',font=n.font(19))
result=n.render_row(cells(ROOT/'art/bakeoff/rio/rio_female-mana_combo-v2.png')[4:],'F5 / F6 at 4x',152,4);im.paste(result,(0,600));save(im,OUT/'L14-raw-result.png')
im=Image.new('RGB',(1536,1100),(24,30,43));d=ImageDraw.Draw(im);d.text((10,10),'L37 ART37 raw crops F3 F4 F5 / final 4x | common factor 0.253',fill='white',font=n.font(20))
raw=Image.open(RAW/'L37-source.png').convert('RGBA');final=cells(ROOT/'art/bakeoff/frey/frey-attack-v5.png')
for k,i in enumerate([2,3,4]):
 x=i%3*512;y=i//3*512;im.paste(raw.crop((x,y,x+512,y+512)).convert('RGB'),(k*512,50))
 tile=n.checker((512,512));f=final[i].resize((512,512),Image.Resampling.NEAREST);tile.paste(f,(0,0),f);im.paste(tile,(k*512,580))
save(im,OUT/'L37-raw-result.png')
# Lead follow-up: neighboring F4/F6 must accompany F5, with measured positions.
from l14_position_review import previous_frames,handoff_board
handoff_board(previous_frames(),cells(ROOT/'art/bakeoff/rio/rio_female-mana_combo-v2.png'))
