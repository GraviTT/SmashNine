"""Record exactly the nine built-in generations used for SKM-04."""
import json,hashlib
from pathlib import Path
from PIL import Image
root=Path('reports/codex-skm-04');generated=Path('C:/Users/TH/.codex/generated_images/01a19d32-540f-7d63-bf78-ae4ed24752e7')
originals={
 'brave_cyclone':['exec-e3404ee6-48eb-4886-b98b-7f4f54062384.png','exec-f04606cc-e87c-4967-8c74-e05d8df228f7.png','exec-5e4e9bd0-6cc1-47f3-9bf3-f9012f7c97d1.png'],
 'brave_grab':['exec-2c50db05-a446-4478-98de-5f83c9c3eedb.png','exec-d3d2e60f-84cc-49fe-9b7d-b923fb112877.png','exec-d586b9dc-c577-4224-803d-6a9ff62aa7b7.png'],
 'star_warp':['exec-28041eba-e11b-4748-a835-9de1a13482bf.png','exec-b4b5e4d8-ed81-4ebd-a230-166e2f75602d.png','exec-40eff04d-4b80-42ee-a70b-e2b5db4d3f4e.png']}
ledger=[]
for row,names in originals.items():
 stem='luna' if row=='star_warp' else 'luna_brave'
 refs=[f'art/bakeoff/luna/{stem}-idle-v{3 if stem=="luna" else 4}.png',f'smash-nine-prototype/assets/art/luna/{stem}_moves_sheet.png']
 for i,name in enumerate(names,1):
  raw=Path(f'art/raw/skm-04/{stem}-{row}-{i}.png');original=generated/name
  assert raw.read_bytes()==original.read_bytes()
  ledger.append({'row':row,'attempt':i,'tool':'built-in image_gen','raw':raw.as_posix(),'original':str(original),'size':Image.open(raw).size,'sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'references':refs})
(root/'generation-ledger.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Preserved originals:',len(ledger))
