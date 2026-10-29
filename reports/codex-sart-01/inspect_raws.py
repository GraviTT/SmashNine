"""Read-only raster inspection using the standard library; creates a raw QA report.

This does not create processed candidates and is not a substitute for Pillow.
"""
import collections
import hashlib
import json
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-sart-01'
PALETTES = {
    'cg_forest': ['#0e3b2a','#3f7d3a','#e8c86a','#ff6a3d','#b77cff'],
    'cg_beast': ['#2a1410','#ff5a1f','#ffd27a','#4a2a2a'],
    'cg_heart': ['#3b1d5e','#1a0f2e','#9b5cff','#ff4fd8','#ffd6f5'],
}


def read_png(path):
    data = Path(path).read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    offset = 8
    compressed = bytearray()
    header = None
    while offset < len(data):
        size = struct.unpack('>I', data[offset:offset+4])[0]
        kind = data[offset+4:offset+8]
        payload = data[offset+8:offset+8+size]
        crc = struct.unpack('>I',data[offset+8+size:offset+12+size])[0]
        assert zlib.crc32(kind+payload) & 0xffffffff == crc
        if kind == b'IHDR':
            header = struct.unpack('>IIBBBBB',payload)
        elif kind == b'IDAT':
            compressed.extend(payload)
        offset += size+12
    width,height,depth,kind,compression,filter_method,interlace = header
    assert depth==8 and kind in (2,6) and compression==0 and filter_method==0 and interlace==0, header
    channels = 3 if kind==2 else 4
    stride = width*channels
    packed = zlib.decompress(compressed)
    assert len(packed) == (stride+1)*height
    decoded = bytearray(stride*height)
    prior = bytearray(stride)
    position = 0
    for y in range(height):
        filter_type = packed[position]
        position += 1
        row = bytearray(packed[position:position+stride])
        position += stride
        assert filter_type in range(5)
        if filter_type == 1:
            for x in range(channels,stride):
                row[x] = (row[x]+row[x-channels]) & 255
        elif filter_type == 2:
            for x in range(stride):
                row[x] = (row[x]+prior[x]) & 255
        elif filter_type == 3:
            for x in range(stride):
                a = row[x-channels] if x>=channels else 0
                row[x] = (row[x]+((a+prior[x])//2)) & 255
        elif filter_type == 4:
            for x in range(stride):
                a = row[x-channels] if x>=channels else 0
                b = prior[x]
                c = prior[x-channels] if x>=channels else 0
                p = a+b-c
                pa,pb,pc = abs(p-a),abs(p-b),abs(p-c)
                pred = a if pa<=pb and pa<=pc else b if pb<=pc else c
                row[x] = (row[x]+pred) & 255
        decoded[y*stride:(y+1)*stride] = row
        prior = row
    if channels == 4:
        alpha = decoded[3::4]
        assert min(alpha)==255 and max(alpha)==255, 'Unexpected transparency'
        rgb = bytearray(width*height*3)
        rgb[0::3],rgb[1::3],rgb[2::3] = decoded[0::4],decoded[1::4],decoded[2::4]
    else:
        rgb = decoded
    return width,height,rgb


LUT = [v/255/12.92 if v/255<=.04045 else ((v/255+.055)/1.055)**2.4 for v in range(256)]


def lab(rgb):
    r,g,b = (LUT[v] for v in rgb)
    xyz = ((.4124564*r+.3575761*g+.1804375*b)/.95047,
           .2126729*r+.7151522*g+.0721750*b,
           (.0193339*r+.1191920*g+.9503041*b)/1.08883)
    f = [t**(1/3) if t>216/24389 else (24389/27*t+16)/116 for t in xyz]
    return 116*f[1]-16,500*(f[0]-f[1]),200*(f[1]-f[2])


def counter(rgb):
    return collections.Counter(zip(rgb[0::3],rgb[1::3],rgb[2::3]))


def measure(width,height,rgb,colors):
    split = height*3//4
    cut = split*width*3
    upper,lower = counter(rgb[:cut]),counter(rgb[cut:])
    luma = lambda c: .2126*c[0]+.7152*c[1]+.0722*c[2]
    top = sum(n*luma(c) for c,n in upper.items())/(split*width)
    bottom = sum(n*luma(c) for c,n in lower.items())/((height-split)*width)
    targets = [lab(tuple(bytes.fromhex(c[1:]))) for c in colors]
    hist = upper+lower
    minimum = [float('inf')]*len(colors)
    close = [0]*len(colors)
    distances = []
    for color,count in hist.items():
        value = lab(color)
        delta = [math.sqrt(sum((a-b)**2 for a,b in zip(value,t))) for t in targets]
        distances.append((min(delta),count))
        for i,d in enumerate(delta):
            minimum[i] = min(minimum[i],d)
            if d<=10:
                close[i] += count
    total = width*height
    mean = sum(d*n for d,n in distances)/total
    cumulative = 0
    p90 = 0
    for distance,count in sorted(distances):
        cumulative += count
        if cumulative>=total*.9:
            p90 = distance
            break
    return {
        'size': [width,height], 'opaque': True,
        'brightness_method': "All-pixel mean encoded-sRGB luma Y'=0.2126R+0.7152G+0.0722B, range 0..255; bottom split=floor(height*3/4)",
        'top_mean_luma': round(top,4), 'bottom_mean_luma': round(bottom,4),
        'bottom_to_top_ratio': round(bottom/top,6),
        'palette_method': 'CIE76 DeltaE in CIELAB D65; all pixels weighted; no contract threshold',
        'nearest_palette_mean_delta_e76': round(mean,4), 'nearest_palette_p90_delta_e76': round(p90,4),
        'palette_swatches': [{'hex':c, 'minimum_delta_e76':round(minimum[i],4),'pixels_within_delta_e76_10_percent':round(close[i]/total*100,5)} for i,c in enumerate(colors)],
    }


def main():
    manifest = json.loads((REPORT/'generation-manifest-v2.json').read_text(encoding='utf-8'))
    items = []
    for item in manifest['candidates']:
        name = item['name']
        asset = name.rsplit('-v',1)[0]
        raw = ROOT/'art/raw/story'/(name+'_raw.png')
        source_hash = hashlib.sha256(Path(item['source_tool_path']).read_bytes()).hexdigest()
        raw_hash = hashlib.sha256(raw.read_bytes()).hexdigest()
        assert raw_hash == source_hash
        w,h,rgb = read_png(raw)
        data = {'name':name, 'raw_sha256':raw_hash, 'source_copy_exact':True,
                'measurements': measure(w,h,rgb,PALETTES[asset])}
        items.append(data)
        print(json.dumps(data,ensure_ascii=False),flush=True)
    report = {'scope':'RAW images only; these are not final processed-candidate measurements', 'items':items}
    output = REPORT/'raw-measurements-v1.json'
    with output.open('x',encoding='utf-8',newline='\n') as stream:
        json.dump(report,stream,ensure_ascii=False,indent=2)
        stream.write('\n')


if __name__=='__main__':
    main()
