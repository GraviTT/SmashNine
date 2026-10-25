"""ART-72 4x landmark review: explicit human-selected exposed face boundaries.
No invented second eye: Rio's far eye is covered by hair in the anchor.
Coordinates are cell pixel boundary coordinates, inspected using grid-F*.png.
"""
import sys,json
from pathlib import Path
from PIL import Image,ImageDraw
stem,row,attempt=sys.argv[1:4]
root=Path(f'reports/codex-art-82/{stem}/{row}/attempt-{attempt}')
data=json.loads(Path(sys.argv[4]).read_text(encoding='utf-8'))
anchor=Image.open(f'art/bakeoff/rio/{stem}-idle-v2.png').convert('RGBA').crop((0,0,128,128))
im=Image.open(root/f'{stem}-{row}.png').convert('RGBA');cell=im.height
marks=data['anchor'];aw=marks[1]-marks[0]
board=Image.new('RGB',(256*(len(data['frames'])+1),280),(31,38,55));d=ImageDraw.Draw(board)
results=[]
for i,points in enumerate([marks]+data['frames']):
 f=anchor if i==0 else im.crop(((i-1)*cell,0,i*cell,cell))
 if points is None:
  results.append({'frame':i,'eye_ratio':None,'face_width_ratio':None,'reason':'기울거나 가려진 얼굴. 수치 제외.'});continue
 left,right,y=points;ox=round((left+right)/2)-24;oy=round(y)-24
 cr=f.crop((ox,oy,ox+48,oy+48)).resize((192,192),Image.Resampling.NEAREST);bx=i*256+32;by=40;board.paste(cr,(bx,by),cr)
 for x in [left,right]:
  xx=bx+(x-ox)*4;yy=by+(y-oy)*4;d.line((xx-4,yy,xx+4,yy),fill='yellow');d.line((xx,yy-5,xx,yy+5),fill='yellow')
 ratio=(right-left)/aw;d.text((i*256+5,8),'ANCHOR' if i==0 else f'F{i} W={ratio:.3f} eyes=N/A',fill='white')
 if i:results.append({'frame':i,'eye_ratio':None,'face_width_ratio':round(ratio,4),'width':right-left,'points':points,'reason':'반대쪽 눈은 기준부터 앞머리에 가려져 눈 간 거리 측정 불가. 머리카락을 제외한 눈 아래 경계의 노출 얼굴 폭을 4배 판에서 측정.'})
board.save(root/'face-measured.png')
result={'method':'수동 검수 표식, ART-72의 eye-lower-edge exposed face width. 소수점은 좌표 출력 정밀도이며 오차 보증이 아님. 눈 간 거리 자동 제안은 폐기.','anchor':marks,'reference_face_width':aw,'frames':results}
(root/'face-measured.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(results,ensure_ascii=False))
