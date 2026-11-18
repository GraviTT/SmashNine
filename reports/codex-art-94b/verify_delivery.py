from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib
r=Path('reports/codex-art-94b'); out=Path('art/bakeoff/xion/b')
def check(p):
    im=Image.open(p).convert('RGBA'); a=np.array(im); al=a[:,:,3]; m=al>0
    b=im.getbbox(); edge=np.zeros_like(m);edge[0]=edge[-1]=True;edge[:,0]=edge[:,-1]=True
    rgb=a[:,:,:3].astype(int)
    green=m&(rgb[:,:,1]>rgb[:,:,0]+20)&(rgb[:,:,1]>rgb[:,:,2]+20)&(rgb[:,:,1]>80)
    return {'size':list(im.size),'mode':im.mode,'alpha_range':[int(al.min()),int(al.max())],'bbox':list(b),'margins_ltrb':[b[0],b[1],im.width-b[2],im.height-b[3]],'border_nontransparent_pixels':int((m&edge).sum()),'transparent_rgb_residue_pixels':int(((al==0)&np.any(rgb!=0,axis=2)).sum()),'green_key_fringe_pixels':int(green.sum()),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
main=check(out/'xion_illustration-b.png');face=check(out/'xion_face-b.png')
main.update({'body_height_px':1352,'height_percent':round(1352/1536*100,3),'manual_head_y_top_chin':[92,288],'manual_head_height_px':196,'manual_heads_tall':round(1352/196,3),'manual_measurement_note':'Crown and chin landmarks visually selected at full size; not automatic anatomy detection.','source_alpha_cleanup':'Raw alpha <=4 cleared before proportional LANCZOS resize; resized alpha <=1 cleared. Original soft alpha otherwise preserved.'})
main['fringe_definition']='Visible RGB green exceeds both red and blue by more than 20 and green >80; transparent RGB residue counted separately. This is a numeric colour-artifact test, not an automatic universal halo detector.'
main['rgb_cleanup']='After resizing, clamp unintended green-dominant RGB to max(red,blue), preserving alpha: 51 illustration pixels, 8 face pixels; zero RGB under alpha=0.'
face.update({'crop_xyxy_from_illustration':[278,14,790,526],'resample':'LANCZOS','manual_eye_points_illustration':[[541,216],[577,225]],'manual_mean_eye_height_percent':round(((216+225)/2-14)/512*100,3)})
gif=Image.open(r/'idle-4x.gif'); durations=[]
for i in range(gif.n_frames):
    gif.seek(i); durations.append(gif.info['duration'])
met=json.loads((r/'metrics.json').read_text(encoding='utf-8'))
met['head_scale']=json.loads((r/'head-scale.json').read_text(encoding='utf-8'))
met['illustration']=main;met['face']=face
met['gif']={'size':list(gif.size),'frames':gif.n_frames,'durations_ms':durations,'total_duration_ms':sum(durations),'effective_fps':round(gif.n_frames*1000/sum(durations),6),'note':'GIF has 10ms time units. 5x160+1x150ms approximates the exact metadata 6.3fps loop.'}
met['feet']=json.loads((r/'feet-check.json').read_text(encoding='utf-8'))
met['feet_note']='Bottom five rows x-run centres: rear foot 39.0..40.5 (spread 1.5px), front foot 80.0..81.0 (spread 1.0px). Ground y=120 fixed. Not perfectly pixel-locked.'
met['manual_review']={'illustration_full_size':True,'face_2x':True,'every_sprite_frame_4x':True,'illustration_checks':['two connected arms','two hands wrapped around grips; index fingers visible at trigger guards','two complete matching pump shotgun silhouettes with hollow muzzles','two complete boots','clear face; no effects'],'sprite_checks':['one face each','both hands and both matching guns visible each','below-shoulder guns pointed forward/down','short bob and silver streak; black silver crimson palette','head visually similar to Rio female; Xion bob has broader side silhouette'],'limitations':['sprite scarf tails are shorter/more horizontal than illustration','small boot contour/position variation remains','subtle breath and cloth lag judged from six frames; real-time/game playback not verified'],'generation_count':{'illustration':1,'idle':2},'idle_v1_rejected_reason':'Normalization torso centre changed as scarf crossed torso rows; frames 3-4 shifted about 7px sideways.'}
(r/'metrics.json').write_text(json.dumps(met,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
checks={'illustration_dimensions':main['size']==[1024,1536],'face_dimensions':face['size']==[256,256],'idle_dimensions':Image.open(out/'xion-idle-b.png').size==(768,128),'height_95_100':all(95<=f['body_height']<=100 for f in met['frames']),'detail_at_least_90_percent':met['summary']['interior_detail_ratio']>=.9,'green_spill_zero':sum(met['summary']['remaining_spill_pixels'])==0,'clear_border':met['summary']['borders_clear'],'margin4':met['summary']['all_have_4px_margin'],'illustration_border_clear':main['border_nontransparent_pixels']==0,'illustration_green_key_fringe_zero':main['green_key_fringe_pixels']==0,'gif_six_frames':gif.n_frames==6}
head=met['head_scale'][0]
checks['head_scale_median_096_104']=head['used']>=2 and .96<=head['median']<=1.04
checks['face_fringe_and_hidden_rgb_zero']=face['green_key_fringe_pixels']==0 and face['transparent_rgb_residue_pixels']==0
checks['all_sprite_frame_head_scales_096_104']=all(.96<=f['scale']<=1.04 and f['score']>=.6 for f in head['frames'])
(r/'delivery-checks.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'illustration':main,'face':face,'gif':met['gif'],'detail_ratio':met['summary']['interior_detail_ratio'],'heights':[f['body_height'] for f in met['frames']],'checks':checks},ensure_ascii=False,indent=2))
