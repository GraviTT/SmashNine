"""Size-normalize image-tool drafts for review; never composite or redraw faces."""
from pathlib import Path
import json
from PIL import Image
from check_faces import ROOT, REPORT, FORMS, EXPRESSIONS

config=json.loads((REPORT/'review.json').read_text(encoding='utf-8'))
for folder,stem in FORMS:
    for expr in EXPRESSIONS:
        drafts=sorted((ROOT/'art/raw/faces-73').glob(f'{stem}-{expr}-try[123].png'))
        if not drafts:
            raise FileNotFoundError(f'No generated draft: {stem}/{expr}')
        selected=config[stem].get('selected_tries',{}).get(expr,int(drafts[-1].stem[-1]))
        raw=ROOT/'art/raw/faces-73'/f'{stem}-{expr}-try{selected}.png'
        out=ROOT/'art/bakeoff'/folder/f'{stem}_face-{expr}-v1.png'
        meta=out.with_suffix('.json')
        if out.exists() or meta.exists():
            raise FileExistsError(f'New files only: {out}')
        out.parent.mkdir(parents=True,exist_ok=True)
        Image.open(raw).convert('RGBA').resize((256,256),Image.Resampling.LANCZOS).save(out)
        note={
            'note':'내장 이미지 도구가 현재 무표정 초상화를 편집한 표정 시안. 크기만 256×256으로 정규화했다. 얼굴 밖 픽셀과 원본 투명 영역에 차이가 남아 검수 미달·납품 보류이며 게임에 채택하면 안 된다. 원본 보존 합성은 수행하지 않았다.',
            'expression':expr,
            'edited_from':f'smash-nine-prototype/assets/art/{folder}/{stem}_face.png',
            'source_raw':str(raw.relative_to(ROOT)).replace('\\','/'),
            'selected_try':selected,
            'tries':len(drafts),
            'review_status':'rejected',
            'delivered':False,
            'candidate_only':True,
            'size_normalization':'Pillow LANCZOS; RGBA; no compositing, no alpha restoration, no redrawing'
        }
        meta.write_text(json.dumps(note,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print(out.relative_to(ROOT))
