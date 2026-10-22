from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[4]
A=ROOT/'smash-nine-prototype/assets/art/story';R=ROOT/'reports/codex-art-70'
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',18)
small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',15)
out=Image.new('RGB',(1280,1100),(16,20,36));d=ImageDraw.Draw(out)
def nine(im,size,m):
 w,h=im.size;W,H=size;canvas=Image.new('RGBA',size)
 sx=[0,m,w-m,w];sy=[0,m,h-m,h];dx=[0,m,W-m,W];dy=[0,m,H-m,H]
 for yy in range(3):
  for xx in range(3):
   tile=im.crop((sx[xx],sy[yy],sx[xx+1],sy[yy+1])).resize((dx[xx+1]-dx[xx],dy[yy+1]-dy[yy]),Image.Resampling.NEAREST)
   canvas.alpha_composite(tile,(dx[xx],dy[yy]))
 return canvas
for key,pos,title in [('cg_prologue',(0,40),'프롤로그 1안 · 심장 파열'),('cg_root',(640,40),'뿌리 3안 · 봉인 개방'),('cg_epilogue',(0,455),'에필로그 1안 · 진정된 심장')]:
 im=Image.open(A/f'{key}.png').resize((640,360),Image.Resampling.LANCZOS)
 out.paste(im,pos);d.text((pos[0]+15,pos[1]-30),title,font=font,fill='#f3cd7c')
 # actual dialogue bottom-quarter mask is visible in all three previews
 overlay=Image.new('RGBA',(640,90),(7,12,28,230))
 target=out.crop((pos[0],pos[1]+270,pos[0]+640,pos[1]+360)).convert('RGBA');target.alpha_composite(overlay)
 ImageDraw.Draw(target).text((24,26),'하단 25% 대화 가림 영역',font=small,fill='#e5eaf5')
 out.paste(target.convert('RGB'),(pos[0],pos[1]+270))
d.text((665,440),'대화 틀 1안 / 이름판 1안',font=font,fill='#f3cd7c')
pane=Image.new('RGBA',(600,220),(7,12,28,235));pane.alpha_composite(nine(Image.open(A/'dialogue_frame.png').convert('RGBA'),(600,220),24))
pd=ImageDraw.Draw(pane);pd.text((34,76),'세계수의 심장이 고요해졌다.',font=font,fill='#e5eaf5');pd.text((34,112),'검토용 합성 · 실제 게임 화면은 아님',font=small,fill='#c8d0e0')
out.paste(pane.convert('RGB'),(660,515))
plate=nine(Image.open(A/'name_plate.png').convert('RGBA'),(220,40),12)
ImageDraw.Draw(plate).text((32,8),'그림자 프레이',font=small,fill='#e5eaf5')
temp=Image.new('RGBA',out.size);temp.alpha_composite(plate,(680,485));out=Image.alpha_composite(out.convert('RGBA'),temp).convert('RGB');d=ImageDraw.Draw(out)
d.text((665,760),'24px / 12px 9-slice · 중앙 투명 / alpha235',font=small,fill='#c8d0e0')
d.text((20,850),'그림자 오라 2안 · 6프레임 / 10fps / pivot(64,160)',font=font,fill='#f3cd7c')
strip=Image.open(A/'shadow_aura.png').convert('RGBA')
for i in range(6):
 tile=Image.new('RGBA',(128,176),(16,20,36,255));tile.alpha_composite(strip.crop((128*i,0,128*(i+1),176)))
 td=ImageDraw.Draw(tile);td.rectangle((43,64,84,159),fill='#8c919e');td.line((4,160,123,160),fill='#58d6a8')
 out.paste(tile.convert('RGB'),(20+i*165,890));d.text((155+i*165,945),str(i+1),font=small,fill='#b4bfd4')
d.text((1035,930),'회색 몸 상자',font=small,fill='#e5eaf5');d.text((1035,960),'42×96px',font=small,fill='#e5eaf5');d.text((1035,990),'초록선: 발 y160',font=small,fill='#58d6a8')
out.save(R/'selected_overview.png')
print('selected_overview.png created, review composite only')

