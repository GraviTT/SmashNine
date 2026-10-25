"""Run the repository's D34 estimator read-only on QA-23 live fighter frames.
Estimator is tuned to Frey; score and exclusions must be read with the estimate.
No cached bytecode is written into tools/sprite_pipeline.
"""
import sys
sys.dont_write_bytecode=True
import argparse,importlib.util,json,time,os
os.environ['OPENBLAS_NUM_THREADS']='1'
os.environ['OMP_NUM_THREADS']='1'
from pathlib import Path
import numpy as np
from PIL import Image
from audit import ROOT,OUT,ART,STEMS,dump

def fast_scale(frame,template,mod):
    """Same masks, scales, search and normalized correlation as repository estimator.
    Vectorizes the 17x17 translation search. Float64 keeps reference precision.
    """
    a=np.asarray(frame);centre=mod.face_centre(a)
    if centre is None:return None,0.0
    rgb=np.where(a[:,:,3,None]>0,a[:,:,:3],0).astype(float)
    padded=np.pad(rgb,((mod.PAD,mod.PAD),(mod.PAD,mod.PAD),(0,0)))
    best=(None,-2.0)
    for scale in mod.SCALES:
        w,h=max(4,round(template.width*scale)),max(4,round(template.height*scale))
        t=np.asarray(template.resize((w,h),Image.Resampling.LANCZOS)).astype(float)
        mask=np.asarray(template.getchannel('A').resize((w,h),Image.Resampling.NEAREST))>0
        tv=t[:,:,:3][mask];tv=tv-tv.mean();tn=np.sqrt((tv**2).sum())+1e-6
        ey,ex=centre[0]+mod.BOX[1]*scale,centre[1]+mod.BOX[0]*scale
        ys=np.array([int(round(ey+dy))+mod.PAD for dy in range(-8,9)])
        xs=np.array([int(round(ex+dx))+mod.PAD for dx in range(-8,9)])
        yy,xx=np.meshgrid(ys,xs,indexing='ij');yy=yy.ravel();xx=xx.ravel()
        valid=(yy>=0)&(xx>=0)&(yy+h<=padded.shape[0])&(xx+w<=padded.shape[1]);yy=yy[valid];xx=xx[valid]
        if not len(yy):continue
        windows=np.lib.stride_tricks.sliding_window_view(padded,(h,w),axis=(0,1))
        pv=windows[yy,xx].transpose(0,2,3,1)[:,mask,:]
        pv-=pv.mean(axis=(1,2),keepdims=True)
        scores=np.sum(pv*tv,axis=(1,2))/(tn*(np.sqrt(np.sum(pv**2,axis=(1,2)))+1e-6))
        idx=int(np.argmax(scores));score=float(scores[idx])
        if score>best[1]+1e-12:best=(float(scale),score)
    return best

def fft_scale(frame,template,mod):
    """Equivalent masked NCC using real FFT convolutions (one CPU process).
    The searched 17x17 offsets, template and scale grid are unchanged.
    """
    a=np.asarray(frame);centre=mod.face_centre(a)
    if centre is None:return None,0.0
    rgb=np.where(a[:,:,3,None]>0,a[:,:,:3],0).astype(float)
    padded=np.pad(rgb,((mod.PAD,mod.PAD),(mod.PAD,mod.PAD),(0,0)))
    best=(None,-2.0)
    for scale in mod.SCALES:
        w,h=max(4,round(template.width*scale)),max(4,round(template.height*scale))
        t=np.asarray(template.resize((w,h),Image.Resampling.LANCZOS)).astype(float)
        mask=np.asarray(template.getchannel('A').resize((w,h),Image.Resampling.NEAREST))>0
        tv=t[:,:,:3][mask];tv=tv-tv.mean();tn=np.sqrt((tv**2).sum())+1e-6
        centred=np.zeros((h,w,3));centred[mask]=tv
        ey,ex=centre[0]+mod.BOX[1]*scale,centre[1]+mod.BOX[0]*scale
        ys=np.array([int(round(ey+dy))+mod.PAD for dy in range(-8,9)])
        xs=np.array([int(round(ex+dx))+mod.PAD for dx in range(-8,9)])
        yy,xx=np.meshgrid(ys,xs,indexing='ij');yy=yy.ravel();xx=xx.ravel()
        valid=(yy>=0)&(xx>=0)&(yy+h<=padded.shape[0])&(xx+w<=padded.shape[1]);yy=yy[valid];xx=xx[valid]
        if not len(yy):continue
        y0,x0=yy.min(),xx.min();src=padded[y0:yy.max()+h,x0:xx.max()+w]
        shape=tuple(1<<(int(n)-1).bit_length() for n in (src.shape[0]+h-1,src.shape[1]+w-1))
        fi=np.fft.rfft2(src,s=shape,axes=(0,1));ft=np.fft.rfft2(centred[::-1,::-1],s=shape,axes=(0,1))
        numer=np.fft.irfft2(np.sum(fi*ft,axis=2),s=shape)
        fm=np.fft.rfft2(mask[::-1,::-1].astype(float),s=shape)
        sums=np.fft.irfft2(np.sum(fi,axis=2)*fm,s=shape)
        squares=np.fft.irfft2(np.fft.rfft2(np.sum(src*src,axis=2),s=shape)*fm,s=shape)
        iy=yy-y0+h-1;ix=xx-x0+w-1
        den=np.sqrt(np.maximum(0,squares[iy,ix]-sums[iy,ix]**2/(int(mask.sum())*3)))+1e-6
        scores=numer[iy,ix]/(tn*den);idx=int(np.argmax(scores));score=float(scores[idx])
        if score>best[1]+1e-12:best=(float(scale),score)
    return best

def main():
    p=argparse.ArgumentParser();p.add_argument('--limit',type=int,default=0);p.add_argument('--stem');p.add_argument('--validate',action='store_true');p.add_argument('--force',action='store_true');args=p.parse_args()
    spec=importlib.util.spec_from_file_location('qa23_head_scale',ROOT/'tools/sprite_pipeline/head_scale.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
    started=time.monotonic();n=0
    for stem in STEMS:
        if args.stem and stem!=args.stem:continue
        ref=Image.open(ART/stem.split('_')[0]/f'{stem}_sheet.png').convert('RGBA').crop((0,0,128,128))
        try:template=mod.head_template(ref)
        except ValueError:dump(OUT/'metrics/heads'/f'{stem}.json',{'error':'No face detected in idle anchor'});continue
        rp=OUT/'metrics/heads'/f'{stem}.json'
        result=json.loads(rp.read_text(encoding='utf-8')) if rp.exists() and not args.limit and not args.force else {'stem':stem,'rows':[]}
        result['method']='masked NCC using FFT, same template/scales/17x17 offsets as tools/sprite_pipeline/head_scale.py; min_score 0.6; Frey-tuned template; score ties within 1e-12 choose smaller scale'
        for suffix in ['sheet','moves_sheet']:
            d=json.loads((OUT/'metrics'/f'{stem}_{suffix}.json').read_text(encoding='utf-8'));sheet=Image.open(ROOT/d['path']).convert('RGBA');cw,ch=d['cell']
            for row in d['rows']:
                if any(v['sheet']==stem+'_'+suffix and v['row']==row['name'] for v in result['rows']):continue
                frames=[]
                for f in row['frames']:
                    x=(f['sheet_column']-1)*cw;y=(f['sheet_row']-1)*ch;im=sheet.crop((x,y,x+cw,y+ch));scale,score=fft_scale(im,template,mod)
                    if args.validate:
                        old=mod.head_scale(im,template)
                        assert old[0]==scale and abs(old[1]-score)<1e-9,(old,(scale,score))
                    frames.append({'frame':f['frame'],'scale':scale,'score':round(score,4),'accepted':scale is not None and score>=.6});n+=1
                    if args.limit and n>=args.limit:print(json.dumps({'sample':frames,'seconds':time.monotonic()-started}),flush=True);return
                valid=[f['scale'] for f in frames if f['accepted']]
                result['rows'].append({'sheet':stem+'_'+suffix,'row':row['name'],'frames':frames,'median':float(np.median(valid)) if valid else None,'accepted':len(valid),'total':len(frames)})
                dump(OUT/'metrics/heads'/f'{stem}.json',result)
                print(stem,row['name'],result['rows'][-1]['median'],f'{len(valid)}/{len(frames)}',round(time.monotonic()-started,1),flush=True)

if __name__=='__main__':main()
