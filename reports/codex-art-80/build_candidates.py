"""ART-80: scale, integer-align and alpha-clean generated edits; draw review boards only.
No shadow features or colors are painted by this script.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
REPORT = Path(__file__).resolve().parent
RAW = ROOT / 'art/raw/faces-80'
CFG73 = json.loads((ROOT / 'reports/codex-art-73/composite-config.json').read_text(encoding='utf-8'))
FORMS = [
    ('frey', 'frey', '프레이', 2, '민트 녹색'),
    ('luna', 'luna', '루나', 1, '얼음 청록색'),
    ('luna', 'luna_brave', '브레이브 루나', 1, '라벤더 보라색'),
    ('yuki', 'yuki', '유키', 1, '얼음 파란색'),
    ('nova', 'nova_male', '노바 남', 2, '라일락 보라색'),
    ('nova', 'nova_female', '노바 여', 1, '페리윙클 청보라색'),
    ('rio', 'rio_male', '리오 남', 1, '민트 녹색'),
    ('rio', 'rio_female', '리오 여', 1, '옅은 에메랄드 녹색'),
]
TINT = np.array([.42, .24, .62])
FONT = 'C:/Windows/Fonts/malgun.ttf'


def dump(path, obj):
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')


def shift(im, dx, dy):
    result = Image.new('RGBA', im.size)
    result.paste(im, (dx, dy))
    return result


def roi_for(stem):
    cfg = CFG73[stem]
    roi = Image.new('L', (256, 256))
    d = ImageDraw.Draw(roi)
    for line in cfg['alignment']:
        d.line([tuple(p) for p in line], fill=255, width=5)
    excluded = Image.new('L', (256, 256))
    e = ImageDraw.Draw(excluded)
    for name, poly in cfg['features'].items():
        e.polygon([tuple(p) for p in poly], fill=255)
    excluded = excluded.filter(ImageFilter.MaxFilter(11))
    return (np.array(roi) > 0) & (np.array(excluded) == 0)


def gradient(im):
    a = np.array(im).astype(np.float64)
    # Palette changes are intentional: compare normalized luminance edge vectors.
    l = a[:, :, :3] @ np.array([.2126, .7152, .0722])
    gy, gx = np.gradient(l)
    return np.stack([gx, gy], axis=-1)


def align(neutral, edit, stem):
    roi = roi_for(stem)
    n = gradient(neutral)[roi].ravel()
    n = n - n.mean()
    na = np.array(neutral)[:, :, 3].astype(float) / 255
    scores = []
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            moved = shift(edit, dx, dy)
            g = gradient(moved)[roi].ravel()
            g = g - g.mean()
            corr = float(np.dot(n, g) / max(1e-8, np.linalg.norm(n) * np.linalg.norm(g)))
            alpha_mae = float(np.abs(na - np.array(moved)[:, :, 3] / 255).mean())
            score = 1 - corr + alpha_mae
            scores.append(dict(offset=[dx, dy], score=score, roi_gradient_correlation=corr, alpha_mae=alpha_mae))
    scores.sort(key=lambda s: (s['score'], abs(s['offset'][0]) + abs(s['offset'][1])))
    return scores[0], scores, roi


def clean_alpha(aligned, neutral):
    a = np.array(aligned)
    na = np.array(neutral)[:, :, 3]
    rgb = a[:, :, :3].astype(np.float64)
    valid = a[:, :, 3] > 16
    missing = (na > 0) & ~valid
    initial_missing = int(missing.sum())
    radius = 0
    # Edge padding only: extend existing generated RGB into alpha-only boundary gaps.
    while np.any((na > 0) & ~valid) and radius < 256:
        sums = np.zeros_like(rgb)
        counts = np.zeros((256, 256), dtype=float)
        for dy, dx in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]:
            ys, xs = slice(max(0,dy), min(256,256+dy)), slice(max(0,dx), min(256,256+dx))
            sy, sx = slice(max(0,-dy), min(256,256-dy)), slice(max(0,-dx), min(256,256-dx))
            mask = valid[sy,sx]
            sums[ys,xs] += rgb[sy,sx] * mask[:,:,None]
            counts[ys,xs] += mask
        fill = ~valid & (counts > 0)
        rgb[fill] = sums[fill] / counts[fill,None]
        valid[fill] = True
        radius += 1
    if np.any((na > 0) & ~valid):
        raise ValueError('Unfilled alpha gaps')
    out = np.zeros((256, 256, 4), dtype=np.uint8)
    out[:,:,:3] = np.rint(rgb).clip(0,255).astype(np.uint8)
    out[:,:,3] = na
    out[na == 0,:3] = 0
    return Image.fromarray(out), initial_missing, radius


def text(board, xy, label, size=18, fill='#e2dfed'):
    ImageDraw.Draw(board).text(xy, label, font=ImageFont.truetype(FONT, size), fill=fill)


def paste(board, im, xy):
    board.alpha_composite(im, xy)


def dialog_size(im):
    tile = Image.new('RGBA', (142,164))
    tile.alpha_composite(im.resize((142,142), Image.Resampling.BILINEAR), (0,11))
    return tile


def tint(im):
    a = np.array(im)
    a[:,:,:3] = np.rint(a[:,:,:3] * TINT).astype(np.uint8)
    return Image.fromarray(a)


def make_board(stem, label, neutral, out, best):
    tinted = tint(neutral)
    overlay = Image.blend(neutral, out, .5)
    board = Image.new('RGBA', (1100, 790), '#151621')
    text(board, (20,10), f'{label} — 그림자 후보 / 원본 1배', 22)
    for i, (title, im) in enumerate([('중립 원본',neutral),('현재 보라 틴트',tinted),('새 그림자 후보',out),('중립 + 후보 50%',overlay)]):
        x=20+i*270
        text(board,(x,49),title)
        paste(board,im,(x,78))
    text(board,(20,344),f'142×164 영역 (142×142 등비 축소 + 위아래 11px) / 정렬 offset {best["offset"]}',18)
    for i, im in enumerate([neutral,tinted,out,overlay]):
        paste(board,dialog_size(im),(20+i*170,377))
    # Light ground exposes halos; candidate pixels stay unchanged.
    ImageDraw.Draw(board).rectangle((754,372,1050,544),fill='#ececf0')
    paste(board,dialog_size(out),(760,377))
    paste(board,dialog_size(out),(908,377))
    text(board,(758,550),'밝은 배경에서 투명 경계 확인',15)
    text(board,(20,574),'대화 모사 — 실제 Godot 화면 아님 / 후보에 추가 틴트 없음',18)
    ImageDraw.Draw(board).rounded_rectangle((20,610,1080,783),radius=10,fill='#202033',outline='#63517b',width=2)
    paste(board,dialog_size(neutral),(30,615))
    paste(board,dialog_size(out),(926,615))
    text(board,(195,629),'그림자 '+label,19, '#c298f5')
    text(board,(195,674),'남은 그림자는 하나. 나와 똑같은 모습이다.',19)
    text(board,(195,716),'주인공 (왼쪽)                          그림자 (오른쪽)',16)
    board.convert('RGB').save(REPORT / f'{stem}-shadow.png')
    return dialog_size(out)


def main():
    measurements, allscores = {}, {}
    overview = Image.new('RGBA', (1100, 1060), '#151621')
    text(overview,(20,12),'ART-80 · 여덟 그림자 후보 / 중립 → 현재 틴트 → 새 그림자',23)
    text(overview,(20,48),'각 얼굴 142×164 영역 / 대화 크기 모사 · 실제 게임 화면 아님',17)
    for index,(folder,stem,label,attempt,eye) in enumerate(FORMS):
        source = ROOT / f'smash-nine-prototype/assets/art/{folder}/{stem}_face.png'
        neutral = Image.open(source).convert('RGBA')
        raw = RAW / f'{stem}-try{attempt}.png'
        edit = Image.open(raw).convert('RGBA').resize((256,256),Image.Resampling.LANCZOS)
        best,scores,roi = align(neutral,edit,stem)
        aligned = shift(edit,*best['offset'])
        out,padded,radius = clean_alpha(aligned,neutral)
        target = ROOT / f'art/bakeoff/{folder}/{stem}_face-shadow-v1.png'
        if target.exists():
            old = json.loads(target.with_suffix('.json').read_text(encoding='utf-8'))
            if old.get('edited_from') != source.relative_to(ROOT).as_posix() or old.get('expression') != 'shadow':
                raise FileExistsError('Different source already owns '+str(target))
        out.save(target)
        a,n = np.array(out),np.array(neutral)
        measure = dict(size=list(out.size), mode=out.mode, alpha_changed_pixels=int((a[:,:,3]!=n[:,:,3]).sum()),
            outside_neutral_alpha_nonzero=int(((a[:,:,3]>0)&(n[:,:,3]==0)).sum()),
            transparent_nonzero_rgb_pixels=int(((a[:,:,:3]!=0).any(axis=2)&(a[:,:,3]==0)).sum()),
            alpha_padding_pixels=padded,alpha_padding_radius=radius,
            alignment=best,alignment_roi_pixels=int(roi.sum()),
            original_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
            copied_neutral_sha256=hashlib.sha256((RAW/f'{stem}-neutral.png').read_bytes()).hexdigest(),
            candidate_sha256=hashlib.sha256(target.read_bytes()).hexdigest())
        metadata=dict(note='현재 중립 얼굴을 내장 이미지 도구로 직접 편집한 그림자 보스 후보. 생성 RGB를 256px로 축소·정수 정렬한 뒤 원본 알파에 맞췄다. 투명 경계의 빈 RGB만 주변 생성 픽셀로 연장했다. 그림자 색·눈·표정은 코드로 그리지 않았다. 후보 전용이며 게임에 연결하지 않았다.',
            expression='shadow',edited_from=source.relative_to(ROOT).as_posix(),source_raw=raw.relative_to(ROOT).as_posix(),
            selected_try=attempt,tries=2 if stem in ['frey','nova_male'] else 1,eye_colour=eye,review_status='candidate',delivered=True,candidate_only=True,
            offset=best['offset'],normalization='LANCZOS 256x256, integer translation, generated-edge RGB padding, original alpha',measurements=measure)
        dump(target.with_suffix('.json'),metadata)
        measurements[stem]=measure
        allscores[stem]=scores
        make_board(stem,label,neutral,out,best)
        roi_im=Image.fromarray((roi*255).astype(np.uint8));roi_im.save(REPORT/f'{stem}-alignment-roi.png')
        x=20+(index%2)*540; y=90+(index//2)*240
        text(overview,(x,y),f'{label} · {eye} · offset {best["offset"]}',17)
        for j,im in enumerate([neutral,tint(neutral),out]):
            text(overview,(x+j*165,y+30),['중립','현재 틴트','후보'][j],15)
            paste(overview,dialog_size(im),(x+j*165,y+53))
        print(stem,best['offset'],'corr',round(best['roi_gradient_correlation'],4),'padding',padded,radius)
    overview.convert('RGB').save(REPORT/'overview.png')
    dump(REPORT/'measurements.json',measurements)
    dump(REPORT/'alignment-scores.json',allscores)
    for stem,label in [('frey','프레이'),('nova_male','노바 남')]:
        neutral=Image.open(RAW/f'{stem}-neutral.png').convert('RGBA')
        board=Image.new('RGBA',(850,540),'#151621')
        text(board,(15,10),f'{label} 시도 비교 / 256px 및 142×164',21)
        for i in [1,2]:
            edit=Image.open(RAW/f'{stem}-try{i}.png').convert('RGBA').resize((256,256),Image.Resampling.LANCZOS)
            best,_,_=align(neutral,edit,stem)
            out,_,_=clean_alpha(shift(edit,*best['offset']),neutral)
            text(board,(20+i*270,47),f'{i}차 / offset {best["offset"]}',17)
            paste(board,out,(20+i*270,80));paste(board,dialog_size(out),(20+i*270,360))
        text(board,(20,47),'중립 원본',17);paste(board,neutral,(20,80));paste(board,dialog_size(neutral),(20,360))
        board.convert('RGB').save(REPORT/f'{stem}-attempts.png')


if __name__=='__main__':
    main()
