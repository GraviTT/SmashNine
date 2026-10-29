"""Copy immutable inputs with exclusive creation; never overwrite a file."""
from pathlib import Path
import hashlib, json, subprocess

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/raw/faces-84'
REPORT = Path(__file__).resolve().parent
CFG = json.loads((ROOT/'reports/codex-art-73/composite-config.json').read_text(encoding='utf-8'))
GENERATED = {
 'yuki': 'C:/Users/TH/.codex/generated_images/01a172a6-2741-7742-9613-eeca78f7635a/exec-5169a8ef-703b-441d-84c4-bc6498d99219.png',
 'rio_male': 'C:/Users/TH/.codex/generated_images/01a172a6-2741-7742-9613-eeca78f7635a/exec-ab8466de-8f50-4cad-a32e-f5bc3958a907.png'
}

def copy(src, dest, records):
    data=Path(src).read_bytes()
    dest.parent.mkdir(parents=True,exist_ok=True)
    with dest.open('xb') as f: f.write(data)
    records.append({'source':str(src),'copy':dest.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(data).hexdigest()})

if __name__ == '__main__':
    records=[]
    for stem,cfg in CFG.items():
        copy(ROOT/f'smash-nine-prototype/assets/art/{cfg["folder"]}/{stem}_face.png',RAW/f'{stem}-neutral.png',records)
        base=ROOT/f'art/bakeoff/{cfg["folder"]}/{stem}_face-shadow-v1'
        copy(base.with_suffix('.png'),RAW/f'{stem}-shadow-v1.png',records)
        copy(base.with_suffix('.json'),RAW/f'{stem}-shadow-v1.json',records)
    for stem,src in GENERATED.items():
        copy(src,RAW/f'{stem}-hurt-generated-1.png',records)
        copy(ROOT/f'art/bakeoff/{CFG[stem]["folder"]}/{stem}_face-hurt-v1.png',RAW/f'{stem}-hurt-v1.png',records)
    with (REPORT/'input-manifest.json').open('x',encoding='utf-8') as f: json.dump(records,f,ensure_ascii=False,indent=2)
    print('Copied',len(records),'inputs, without overwrite.')
