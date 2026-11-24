"""Static contact sheet from delivered sprites; no generation or sprite edits."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
root=Path('reports/codex-skm-06')
rows=['tumble','barrage','dive']
board=Image.new('RGB',(1152,3*208),(26,32,45))
draw=ImageDraw.Draw(board)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
for i,row in enumerate(rows):
    y=i*208
    draw.rectangle((0,y,1151,y+23),fill=(43,54,70))
    draw.text((12,y+2),f'{row} / delivered candidate / F1 - F6',font=font,fill='white')
    sheet=Image.open(f'art/bakeoff/xion/b/xion-{row}-v1.png').convert('RGBA')
    # Empty outer cell margins trimmed for the report only; source sheet unchanged.
    sheet=sheet.crop((0,24,1152,184))
    board.paste(sheet,(0,y+32),sheet)
board.save(root/'continuation-preview.png')
