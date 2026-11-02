"""Prepared fallback. DO NOT RUN without user approval to replace Pillow.

Uses existing Python stdlib for PNG/Lanczos3 and Windows System.Drawing for
contact-sheet labels, band compositing and JPEG quality 90 only. No installation.
"""
import argparse
import ast
import hashlib
import json
import math
import struct
import subprocess
import zlib
from pathlib import Path

from inspect_raws import ROOT, REPORT, PALETTES, read_png, measure


def write_once(path, data):
    path = Path(path)
    assert any(path.resolve().is_relative_to((ROOT/p).resolve()) for p in ('art/raw/story','art/bakeoff/story','reports/codex-sart-01'))
    path.parent.mkdir(parents=True,exist_ok=True)
    if path.exists():
        if path.read_bytes()!=data:
            raise RuntimeError('Refusing overwrite: '+str(path))
        return
    with path.open('xb') as out:
        out.write(data)


def write_json(path, data):
    write_once(path,(json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))


def encode_png(w,h,rgb):
    def chunk(kind,data):
        return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    rows = b''.join(b'\0'+rgb[y*w*3:(y+1)*w*3] for y in range(h))
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(rows,9))+chunk(b'IEND',b'')


def crop(w,h,rgb,box):
    left,top,right,bottom = box
    assert 0<=left<right<=w and 0<=top<bottom<=h
    result = bytearray().join(rgb[(y*w+left)*3:(y*w+right)*3] for y in range(top,bottom))
    return right-left,bottom-top,result


def coefficients(source,dest):
    assert dest<=source
    scale = source/dest
    radius = 3*scale
    result = []
    for x in range(dest):
        center = (x+.5)*scale
        start = max(0,math.ceil(center-radius-.5))
        end = min(source,math.floor(center+radius-.5)+1)
        weights = []
        for i in range(start,end):
            t = (i+.5-center)/scale
            if abs(t)<1e-12:
                weight = 1.0
            elif abs(t)>=3:
                weight = 0.0
            else:
                weight = math.sin(math.pi*t)*math.sin(math.pi*t/3)/(math.pi*math.pi*t*t/3)
            weights.append((i,weight))
        norm = sum(w for _,w in weights)
        result.append([(i,w/norm) for i,w in weights if w])
    return result


def resize(w,h,rgb,ow,oh):
    assert ow<=w and oh<=h
    xweights,yweights = coefficients(w,ow),coefficients(h,oh)
    intermediate = bytearray(ow*h*3)
    for y in range(h):
        srcbase = y*w*3
        outbase = y*ow*3
        for x,weights in enumerate(xweights):
            r=g=b=0.0
            for i,weight in weights:
                pos = srcbase+i*3
                r+=rgb[pos]*weight
                g+=rgb[pos+1]*weight
                b+=rgb[pos+2]*weight
            pos = outbase+x*3
            intermediate[pos] = min(255,max(0,int(r+.5)))
            intermediate[pos+1] = min(255,max(0,int(g+.5)))
            intermediate[pos+2] = min(255,max(0,int(b+.5)))
    output = bytearray(ow*oh*3)
    for y,weights in enumerate(yweights):
        outbase = y*ow*3
        offsets = [(i*ow*3,weight) for i,weight in weights]
        for x in range(ow):
            r=g=b=0.0
            xbase=x*3
            for rowbase,weight in offsets:
                pos=rowbase+xbase
                r+=intermediate[pos]*weight
                g+=intermediate[pos+1]*weight
                b+=intermediate[pos+2]*weight
            pos=outbase+xbase
            output[pos]=min(255,max(0,int(r+.5)))
            output[pos+1]=min(255,max(0,int(g+.5)))
            output[pos+2]=min(255,max(0,int(b+.5)))
    return ow,oh,output


def load_constant_data():
    tree = ast.parse((REPORT/'build_candidates.py').read_text(encoding='utf-8'))
    result={}
    for node in tree.body:
        if isinstance(node,ast.Assign) and len(node.targets)==1 and isinstance(node.targets[0],ast.Name):
            name=node.targets[0].id
            if name in ('NOTES','FINAL_PAIRS','STAGES','RECOMMENDED'):
                result[name]=ast.literal_eval(node.value)
    return result


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--approved-alternative',action='store_true')
    args=parser.parse_args()
    if not args.approved_alternative:
        raise SystemExit('Pillow replacement requires the user\'s explicit approval. No output written.')
    constants=load_constant_data()
    manifest=json.loads((REPORT/'generation-manifest-v2.json').read_text(encoding='utf-8'))
    results=[]
    tile_paths={}
    for item in manifest['candidates']:
        name=item['name']
        asset=name.rsplit('-v',1)[0]
        raw=ROOT/'art/raw/story'/(name+'_raw.png')
        rawdata=raw.read_bytes()
        assert rawdata==Path(item['source_tool_path']).read_bytes()
        w,h,rgb=read_png(raw)
        k=min(w//16,h//9)
        cw,ch=16*k,9*k
        x,y=(w-cw)//2,(h-ch)//2
        box=(x,y,x+cw,y+ch)
        target=(1600,900) if w>=1600 else (1280,720)
        cropped=crop(w,h,rgb,box)
        ow,oh,processed=resize(*cropped,*target)
        data=encode_png(ow,oh,processed)
        path=ROOT/'art/bakeoff/story'/(name+'.png')
        write_once(path,data)
        assert read_png(path)==(ow,oh,processed)
        stats=measure(ow,oh,processed,PALETTES[asset])
        info={
            'name':name,'note':constants['NOTES'][name],
            'for_lines':[f"story.s{constants['STAGES'][asset]}.pre.1",f"story.s{constants['STAGES'][asset]}.pre.2"],
            'size':[ow,oh],'mode':'RGB','opaque':True,'adopted':False,
            'candidate_status':'superseded_failed_bottom_quarter' if name in ('cg_beast-v1','cg_beast-v2') else 'review_candidate',
            'recommended_by_unit':name in constants['RECOMMENDED'],'parent_variant':item.get('parent'),
            'raw':raw.relative_to(ROOT).as_posix(),'source_tool_path':item['source_tool_path'],
            'raw_sha256':hashlib.sha256(rawdata).hexdigest(),'candidate_sha256':hashlib.sha256(data).hexdigest(),
            'reference_images_in_order':item['refs'],'prompt_manifest':'reports/codex-sart-01/generation-manifest-v2.json',
            'processing':{'tool':'Python standard library, separable Lanczos3; user-approved Pillow replacement',
                'raw_size':[w,h],'crop_box':list(box),'cropped_size':[cw,ch],
                'crop_convention':'[left, top, right, bottom), exclusive right/bottom',
                'resize':{'from':[cw,ch],'to':[ow,oh],'filter':'Lanczos3','scale':ow/cw},
                'upscaled':False,'rounding':'round half up and clamp 0..255 after each separable pass; encoded sRGB',
                'other_operations':'No paint, compositing, palette mapping, sharpening, darkening or text removal'},
            'measurements':stats,
        }
        write_json(path.with_suffix('.json'),info)
        results.append(info)
        tw,th,tile=resize(ow,oh,processed,1280,720)
        tilepath=REPORT/'preview-tiles'/(name+'.png')
        write_once(tilepath,encode_png(tw,th,tile))
        tile_paths[name]=str(tilepath)
        print(json.dumps({'name':name,'size':[ow,oh],'top':stats['top_mean_luma'],'bottom':stats['bottom_mean_luma'],'ratio':stats['bottom_to_top_ratio']},ensure_ascii=False),flush=True)
    pw,ph,prologue=read_png(ROOT/'smash-nine-prototype/assets/art/story/cg_prologue.png')
    tw,th,tile=resize(pw,ph,prologue,1280,720)
    pp=REPORT/'preview-tiles/cg_prologue.png'
    write_once(pp,encode_png(tw,th,tile))
    sheets=[]
    for asset,names in constants['FINAL_PAIRS'].items():
        sheets.append({'asset':asset,'names':list(names),'tiles':[tile_paths[n] for n in names]+[str(pp)],'path':str(REPORT/(asset+'-contact.jpg'))})
    sheets.append({'asset':'cg_beast_before','names':['cg_beast-v1','cg_beast-v2'],'tiles':[tile_paths['cg_beast-v1'],tile_paths['cg_beast-v2'],str(pp)],'path':str(REPORT/'cg_beast-before-contact.jpg')})
    write_json(REPORT/'contact-sheet-inputs.json',sheets)
    script=REPORT/'make_contacts_native.ps1'
    subprocess.run(['C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(script)],check=True)
    for sheet in sheets:
        path=Path(sheet['path'])
        assert path.stat().st_size<=2_000_000
        sheet['path']=path.relative_to(ROOT).as_posix()
        sheet['bytes']=path.stat().st_size
        sheet['size']=[3840,828]
        sheet['tile_size']=[1280,720]
        sheet['jpeg_quality']=90
        sheet['band']={'y_in_tile':540,'height':180,'rgba':[8,12,25,200]}
        sheet['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
    write_json(REPORT/'measurements-alternative-v1.json',{'candidates':results,'contact_sheets':sheets})


if __name__=='__main__':
    main()
