import sys
from pathlib import Path
stem,row,old,new=sys.argv[1:5]
root=Path('art/raw/motions-92')/f'{stem}-{row}';dst=root/new;dst.mkdir(exist_ok=False)
for name in [f'{stem}-{row}.png','board.png','metrics.json','head-scale.json','variant.json']:
 with (dst/name).open('xb') as f:f.write((root/old/name).read_bytes())
