"""Normalize built-in imagegen masters; derive exact periodic sprite strips.

Only source-image sampling, cropping, colour scaling, hard alpha, and tiling
are used for effect art. Native hand-pixel UI lives in build_ui.py.
"""
from pathlib import Path
import json
import math
import argparse
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/raw/vfx-05'
OUT = ROOT / 'art/bakeoff/effects/nova'
REPORT = ROOT / 'reports/codex-vfx-05'
NEAREST = Image.Resampling.NEAREST
SPECS = {
    'root': ('nova_gravity_root', (96, 32), 6, 10, [48, 16], 'assets/art/effects/skill/nova_gravity_root.png', True),
    'orb': ('nova_orb', (64, 64), 4, 16, [32, 32], 'assets/art/effects/nova_orb.png', True),
    'field': ('nova_field', (640, 640), 6, 8, [320, 320], 'assets/art/effects/skill/nova_field.png', True),
    'head': ('nova_beam_head', (48, 48), 4, 16, [24, 24], 'assets/art/effects/nova_beam_head.png', True),
    'tile': ('nova_beam_tile', (64, 16), 1, 0, [32, 8], 'assets/art/effects/nova_beam_tile.png', True),
    'sphere': ('nova_sphere', (320, 320), 6, 12, [160, 160], 'assets/art/vfx/nova_sphere.png', False),
}
NOTES = {
    'root': ['발밑에 납작한 세 겹 궤도와 안쪽 걸쇠가 도는 고정 고리.', '발밑에 연결된 보라 사슬과 청록 잠금점이 도는 고정 고리.'],
    'orb': ['어두운 핵으로 세 갈래 나선이 감겨 드는 작은 중력 구체.', '각진 파편과 분절 궤도가 안으로 감기는 작은 중력 구체.'],
    'field': ['반경 300의 얇은 궤도 경계. 작은 궤도 눈금이 초당 40도로 공전하고 내부는 매우 옅다.', '반경 300의 분절 괄호 경계. 청록 호와 괄호가 초당 40도로 공전한다.'],
    'head': ['오른쪽으로 뻗은 화살촉과 뒤로 휘는 갈고리 끝. 네 장 밝기 호흡 반복.', '오른쪽이 긴 작은 별과 뒤로 굽은 집게 끝. 네 장 밝기 호흡 반복.'],
    'tile': ['밝은 심선에 얇은 보라 실이 감긴 광선 줄. 가로 양끝 동일, 반복 타일.', '밝은 심선에 청록 마디가 이어진 광선 줄. 가로 양끝 동일, 반복 타일.'],
    'sphere': ['검은 핵과 청록·보라 나선 강착 원반. 캐릭터 뒤에 일반 합성으로 표시.', '검은 핵을 감싸는 분절 강착 고리와 각진 파편. 캐릭터 뒤에 일반 합성으로 표시.'],
}


def clean(arr, border=True, tile=False):
    arr = arr.copy().astype(np.uint8)
    arr[:, :, 3] = np.where(arr[:, :, 3] >= 128, 255, 0)
    if border:
        arr[[0, -1], :, :] = 0
        if not tile:
            arr[:, [0, -1], :] = 0
    arr[arr[:, :, 3] == 0] = 0
    return arr


def master(path):
    arr = clean(np.array(Image.open(path).convert('RGBA')), border=False)
    box = Image.fromarray(arr[:, :, 3]).getbbox()
    if box is None:
        raise ValueError(f'Empty master: {path}')
    return arr, box


def sample(arr, size, centre, scale_xy, angle=0):
    """Inverse nearest sample. scale_xy is source pixels per output pixel."""
    w, h = size
    sx, sy = scale_xy
    if min(sx, sy) < 1:
        raise ValueError(f'Upscale forbidden: {scale_xy}')
    yy, xx = np.mgrid[:h, :w].astype(float)
    dx = (xx - w / 2) * sx
    dy = (yy - h / 2) * sy
    a = math.radians(angle)
    ix = np.rint(centre[0] + dx * math.cos(a) + dy * math.sin(a)).astype(int)
    iy = np.rint(centre[1] - dx * math.sin(a) + dy * math.cos(a)).astype(int)
    valid = (ix >= 0) & (ix < arr.shape[1]) & (iy >= 0) & (iy < arr.shape[0])
    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[valid] = arr[iy[valid], ix[valid]]
    return out


def source_centre(arr, box):
    return ((box[0] + box[2] - 1) / 2, (box[1] + box[3] - 1) / 2)


def field_geometry(arr, box):
    # Fit near-circular main rim from bright pixels, then use the radial mode.
    c = source_centre(arr, box)
    yy, xx = np.mgrid[:arr.shape[0], :arr.shape[1]]
    rr = np.hypot(xx-c[0], yy-c[1])
    lum = arr[:, :, :3].max(axis=2)
    mask = (arr[:, :, 3] > 0) & (lum > 95) & (rr > min(arr.shape[:2]) * .30)
    hist = np.bincount(np.rint(rr[mask]).astype(int), weights=lum[mask], minlength=max(arr.shape[:2]))
    hist = np.convolve(hist, np.ones(9), mode='same')
    radius = int(hist.argmax())
    # Generated circles are slightly hand-drawn; fit their main luminous rim,
    # rather than letting sparse outer ornaments move the gameplay anchor.
    angles = np.linspace(-math.pi, math.pi, 720, endpoint=False)

    def scan(centre, nominal):
        distances = np.arange(nominal-30, nominal+31, .5)
        xs = np.rint(centre[0]+np.cos(angles[:,None])*distances).astype(int)
        ys = np.rint(centre[1]+np.sin(angles[:,None])*distances).astype(int)
        pixels = arr[np.clip(ys,0,arr.shape[0]-1),np.clip(xs,0,arr.shape[1]-1)]
        brightness = pixels[:,:,:3].max(axis=2).astype(float) * (pixels[:,:,3]>0)
        # Prefer the continuous main ring, not an outer cyan ornament.
        score = brightness * np.exp(-.5*((distances-nominal)/17)**2)
        picked = distances[score.argmax(axis=1)]
        return picked

    for _ in range(3):
        radii = scan(c, radius)
        px = c[0]+np.cos(angles)*radii
        py = c[1]+np.sin(angles)*radii
        mat = np.stack((2*px,2*py,np.ones_like(px)),axis=1)
        solution = np.linalg.lstsq(mat,px*px+py*py,rcond=None)[0]
        c = (float(solution[0]),float(solution[1]))
        radius = float(math.sqrt(solution[2]+c[0]**2+c[1]**2))
    radii = scan(c,radius)
    # Circular median suppresses isolated glitter without destroying the thin line.
    radii = np.median(np.stack([np.roll(radii,k) for k in range(-3,4)]),axis=0)
    return c, radius, radii


def normalized_field(arr, box, phase=0):
    c, r, profile = field_geometry(arr, box)
    yy, xx = np.mgrid[:640,:640]
    rr = np.hypot(xx-320, yy-320)
    theta = np.arctan2(yy-320,xx-320)
    # A 15-degree source arc is mirrored into a 30-degree sector, then tiled
    # twelve times. Rotating five degrees/frame closes after six frames while
    # the actual generated glyphs move at a restrained 40 degrees/second.
    period=2*math.pi/12
    folded=np.abs((theta+math.pi/2-phase/12+period/2)%period-period/2)
    source_angle=-math.pi/2+folded
    bin_index = ((source_angle+math.pi)/(2*math.pi)*len(profile)).astype(int)%len(profile)
    scales = profile[bin_index]/300
    if scales.min()<1:
        raise ValueError('Field normalization would upscale')
    ix=np.rint(c[0]+rr*np.cos(source_angle)*scales).astype(int)
    iy=np.rint(c[1]+rr*np.sin(source_angle)*scales).astype(int)
    valid=(ix>=0)&(ix<arr.shape[1])&(iy>=0)&(iy<arr.shape[0])
    out=np.zeros((640,640,4),dtype=np.uint8)
    out[valid]=arr[iy[valid],ix[valid]]
    return out,c,r,[float(scales.min()),float(scales.max())]


def sphere_geometry(arr, box):
    c = source_centre(arr,box)
    outer = max(box[2]-box[0],box[3]-box[1])/2
    angles = np.linspace(0,2*math.pi,360,endpoint=False)
    distances = np.arange(outer*.12,outer*.72,.5)
    for _ in range(3):
        xs=np.rint(c[0]+np.cos(angles[:,None])*distances).astype(int)
        ys=np.rint(c[1]+np.sin(angles[:,None])*distances).astype(int)
        pixels=arr[ys,xs]
        luminous=(pixels[:,:,:3].max(axis=2)>60)&(pixels[:,:,3]>0)
        radii=distances[luminous.argmax(axis=1)]
        px=c[0]+np.cos(angles)*radii;py=c[1]+np.sin(angles)*radii
        solution=np.linalg.lstsq(np.stack((2*px,2*py,np.ones_like(px)),axis=1),px*px+py*py,rcond=None)[0]
        c=(float(solution[0]),float(solution[1]))
        core_radius=float(np.median(radii))
    yy,xx=np.mgrid[:arr.shape[0],:arr.shape[1]]
    outer_radius=float(np.hypot(xx-c[0],yy-c[1])[arr[:,:,3]>0].max())
    return c,core_radius,outer_radius


def sphere_frame(arr, geometry, n, count):
    c,core_radius,outer_radius=geometry
    yy,xx=np.mgrid[:320,:320]
    rr=np.hypot(xx-160,yy-160)
    angle=np.arctan2(yy-160,xx-160)-n*2*math.pi/count
    source_radius=np.where(rr<=55,rr*core_radius/55,core_radius+(rr-55)*(outer_radius-core_radius)/95)
    minimum_scale=min(core_radius/55,(outer_radius-core_radius)/95)
    if minimum_scale<1:raise ValueError('Sphere normalization would upscale')
    ix=np.rint(c[0]+source_radius*np.cos(angle)).astype(int)
    iy=np.rint(c[1]+source_radius*np.sin(angle)).astype(int)
    valid=(ix>=0)&(ix<arr.shape[1])&(iy>=0)&(iy<arr.shape[0])&(rr<=150)
    out=np.zeros((320,320,4),dtype=np.uint8)
    out[valid]=arr[iy[valid],ix[valid]]
    out[rr<=55]=[2,2,8,255]
    return out,minimum_scale


def make(kind, variant):
    src = RAW / f'{kind}-{variant}.png'
    if not src.exists():
        return None
    arr, box = master(src)
    stem, size, count, fps, anchor, replaces, additive = SPECS[kind]
    c = source_centre(arr, box)
    extent = max(box[2] - box[0], box[3] - box[1])
    # Measure radial extent, not square corner distance, to retain debris.
    yy, xx = np.mgrid[:arr.shape[0], :arr.shape[1]]
    radial = np.hypot(xx-c[0], yy-c[1])
    occupied = arr[:, :, 3] > 0
    max_radius = float(radial[occupied].max())
    frames = []
    evidence = dict(source=str(src.relative_to(ROOT)).replace('\\', '/'), source_size=[arr.shape[1], arr.shape[0]],
                    source_box=list(box), source_centre=list(c), method='', scale_source_per_output=None)
    if kind == 'field':
        field_base, field_centre, field_radius, field_scales = normalized_field(arr,box)
    if kind == 'sphere':
        sphere_shape = sphere_geometry(arr,box)
    for n in range(count):
        phase = 2 * math.pi * n / count
        if kind == 'root':
            # Rotate the circular drawing before flattening it to the ground plane.
            sx, sy = max_radius / 44, max_radius / 13
            im = sample(arr, size, c, (sx, sy), n * 360 / count)
            evidence.update(method='원형 원화 60도 간격 회전 후 88x26 지면 타원으로 축소', scale_source_per_output=[sx,sy])
        elif kind == 'orb':
            s = max_radius / 28
            im = sample(arr, size, c, (s, s), n * 360 / count)
            evidence.update(method='중심 고정, 원화 90도 간격 회전 축소', scale_source_per_output=[s,s])
        elif kind == 'sphere':
            im,s = sphere_frame(arr,sphere_shape,n,count)
            evidence.update(method='핵 중심/내측 발광 경계 측정 후 방사형 축소, 60도 회전, 외곽 반경150, 불투명 핵 지름110',
                            source_centre=list(sphere_shape[0]), source_core_radius=sphere_shape[1], source_outer_radius=sphere_shape[2],
                            scale_source_per_output=[s,s])
        elif kind == 'field':
            c, r = field_centre, field_radius
            s = r / 300
            im,_,_,_ = normalized_field(arr,box,phase)
            dy, dx = np.mgrid[:640, :640]
            radius = np.hypot(dx-320,dy-320)
            angle = np.arctan2(dy-320,dx-320)
            # Main radius stays on the true gameplay boundary while glyphs orbit.
            shade = np.full_like(radius,.82)
            rgb = im[:, :, :3].astype(float) * shade[:, :, None]
            rgb[radius < 282] *= .06
            # Keep faint generated haze visible but weak under additive compositing.
            im[:, :, :3] = np.clip(rgb, 0, 255).astype(np.uint8)
            im[radius > 315] = 0
            evidence.update(method='원화 상단15도 호를 거울접합·12주기 배치, 반경300 정규화, 매 프레임5도 실제 회전(40도/초), 내부 명도6%',
                            source_centre=list(c), source_rim_radius=r, scale_source_per_output=[s,s], radial_scale_range=field_scales)
        elif kind == 'head':
            factor = [.90, 1, .90, .80][n]
            s = extent / (38 + (2 if n == 1 else -2 if n == 3 else 0))
            im = sample(arr, size, c, (s, s))
            im[:, :, :3] = (im[:, :, :3].astype(float) * factor).astype(np.uint8)
            evidence.update(method='오른쪽 방향 유지, 원화 축소 크기·밝기의 4위상 호흡', scale_source_per_output=[s,s])
        else:
            # Downsample an image-generated half-period and mirror it. This makes
            # the left/right texels exactly equal, with continuous core and alpha.
            crop = Image.fromarray(arr).crop(box)
            # Retain a short readable motif, not the whole very long generated band.
            segment = min(crop.width,512 if variant=='a' else 256)
            left=(crop.width-segment)//2
            crop=crop.crop((left,0,left+segment,crop.height))
            if crop.width < 32 or crop.height < 12:
                raise ValueError('Tile source smaller than output')
            half = np.array(crop.resize((32, 12), NEAREST))
            im = np.zeros((16, 64, 4), dtype=np.uint8)
            im[2:14, :32] = half
            im[2:14, 32:] = half[:, ::-1]
            evidence.update(method='생성 줄 원화 32x12 축소 후 거울 주기64, 좌우 경계 RGBA 동일',
                            scale_source_per_output=[crop.width/32,crop.height/12])
        im = clean(im, tile=kind == 'tile')
        frames.append(Image.fromarray(im))
    strip = Image.new('RGBA', (size[0] * count, size[1]))
    for i, f in enumerate(frames):
        strip.paste(f, (i * size[0], 0))
    dst = OUT / f'{stem}-{variant}-v1.png'
    strip.save(dst)
    metadata = dict(note=NOTES[kind]['ab'.index(variant)], replaces=replaces, frames=count, fps=fps, anchor=anchor, loop=count>1)
    dst.with_suffix('.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    evidence['output'] = str(dst.relative_to(ROOT)).replace('\\', '/')
    return evidence


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--kind', choices=list(SPECS))
    args = parser.parse_args()
    measurements = {}
    ledger = REPORT / 'processing.json'
    if ledger.exists():
        measurements = json.loads(ledger.read_text(encoding='utf-8'))
    for kind in ([args.kind] if args.kind else SPECS):
        for variant in 'ab':
            info = make(kind, variant)
            if info:
                measurements[f'{kind}-{variant}'] = info
                print(f'{kind}-{variant}: saved')
    ledger.write_text(json.dumps(measurements, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')


if __name__ == '__main__':
    main()
