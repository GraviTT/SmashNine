"""Read-only candidate checks; the result is written once to a new JSON file."""
import hashlib, json, sys
from build_hurt import *
from build_shadows_final import final_transform
from build_shadows import contrast
from publish_candidates import broad_edges

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

if __name__=='__main__':
    results=[]; failures=[]
    measurements=json.loads((REPORT/'measurements.json').read_text(encoding='utf-8'))
    cfgs=json.loads((REPORT/'hurt-mask-config.json').read_text(encoding='utf-8'))
    for r in measurements:
        stem,e=r['stem'],r['expression']; folder=old.FORMS[stem]['folder']
        p=ROOT/f'art/bakeoff/{folder}/{stem}_face-{e}-v2.png'
        im=Image.open(p); out=np.array(im); neutral=Image.open(ROOT/f'smash-nine-prototype/assets/art/{folder}/{stem}_face.png').convert('RGBA'); n=np.array(neutral)
        meta=json.loads(p.with_suffix('.json').read_text(encoding='utf-8'))
        checks={'size':im.size==(256,256),'mode':im.mode=='RGBA','alpha_equal':bool(np.array_equal(out[:,:,3],n[:,:,3])),
                'no_new_opaque_pixels':bool(np.all(out[n[:,:,3]==0,3]==0)),
                'candidate_hash':sha(p)==r['candidate_sha256'],
                'metadata_required':all(k in meta for k in ['note','expression','edited_from','replaces']),
                'korean_note':any('\uac00'<=c<='\ud7a3' for c in meta['note']),
                'candidate_state':meta['delivered'] and meta['candidate_only'] and meta['review_status']=='candidate',
                'expression':meta['expression']==e,'replaces_exists':(ROOT/meta['replaces']).is_file(),
                'metadata_measurements':meta['measurements']==r,
                'board':(REPORT/f'{stem}-{e}.png').is_file(),
                'neutral_copy':sha(ROOT/meta['edited_from'])==sha(RAW/f'{stem}-neutral.png')}
        if e=='hurt':
            mask=Image.open(REPORT/f'{stem}-hurt-mask.png'); m=np.array(mask)
            donor=Image.open(RAW/f'{stem}-hurt-generated-{r["selected_attempt"]}.png').convert('RGBA').resize((256,256),Image.Resampling.LANCZOS)
            aligned=old.shift(donor,r['offset'])
            rebuilt=Image.composite(aligned,neutral,mask); rebuilt.putalpha(neutral.getchannel('A'))
            band=(m>0)&(m<255); delta=np.abs(np.array(aligned)[:,:,:3].astype(float)-n[:,:,:3])
            checks.update(outside_mask_equal=bool(np.array_equal(out[m==0],n[m==0])),
                          reproduction=bool(np.array_equal(out,np.array(rebuilt))),
                          mask_reproduction=bool(np.array_equal(m,np.array(old.mask_for(cfgs[stem],'hurt')))),
                          seam_mae=abs(float(delta[band].mean())-r['seam_edit_neutral_rgb_mae'])<.0001,
                          offset_not_search_boundary=max(abs(x) for x in r['offset'])<4)
        else:
            before=Image.open(ROOT/meta['replaces']).convert('RGBA')
            rebuilt,protect,eye,face=final_transform(stem,before)
            prior=json.loads((ROOT/meta['replaces']).with_suffix('.json').read_text(encoding='utf-8'))
            checks.update(reproduction=bool(np.array_equal(out,np.array(rebuilt))),
                          transparent_rgb_zero=bool(np.all(out[n[:,:,3]==0,:3]==0)),
                          inherited_offset=meta['offset']==prior['offset'],
                          additional_offset=meta['additional_offset']==[0,0],
                          contrast_before=contrast(before,eye,face)==r['before'],
                          contrast_after=contrast(im,eye,face)==r['after'],
                          contrast_improved=r['after']['eye_face_ratio']>r['before']['eye_face_ratio'],
                          dialogue_contrast_improved=r['after']['dialogue_eye_face_ratio']>r['before']['dialogue_eye_face_ratio'],
                          face_darker=r['after']['face_luma']<r['before']['face_luma'],
                          broad_detail_measure=broad_edges(before,im,protect)==r['detail_check_alpha_ge240'],
                          strong_edges_retained=r['detail_check_alpha_ge240']['retention_percent']==100.)
        bad=[k for k,v in checks.items() if not v]
        results.append({'file':p.relative_to(ROOT).as_posix(),'passed':not bad,'checks':checks})
        failures.extend([f'{stem}/{e}: {b}' for b in bad])
    inputs=json.loads((REPORT/'input-manifest.json').read_text(encoding='utf-8'))
    integrity=all(sha(Path(i['source']))==i['sha256']==sha(ROOT/i['copy']) for i in inputs)
    if not integrity: failures.append('input manifest integrity')
    summary={'candidate_count':len(results),'checks_passed':sum(sum(x['checks'].values()) for x in results),
             'all_original_inputs_unchanged':integrity,'failures':failures,'results':results}
    dump(REPORT/(sys.argv[1] if len(sys.argv)>1 else 'verification.json'),summary)
    print(json.dumps({k:v for k,v in summary.items() if k!='results'},indent=2))
    if failures: raise SystemExit(1)
