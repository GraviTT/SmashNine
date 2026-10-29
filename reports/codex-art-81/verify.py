"""Independent audit coverage/integrity checks and numeric algorithm sanity tests."""
import json, math, sys
from pathlib import Path
import numpy as np
from PIL import Image
import audit as a

def main():
 tests=[]
 def test(name,ok,details=None):tests.append({'name':name,'pass':bool(ok),'details':details})
 result=json.loads((a.OUT/'audit.json').read_text(encoding='utf-8'));items=result['files']
 expected={'fighter':53,'monster':108,'monster_sheet':18,'projectile':8,'face':32}
 test('exact_card_inventory',len(items)==219 and len({i['path'] for i in items})==219 and {k:v['files'] for k,v in result['summary'].items()}==expected)
 discovery,_=a.discover();test('fresh_discovery_matches_audit',set(i['path'] for i in discovery)==set(i['path'] for i in items))
 for kind,n in expected.items():
  ls=[i for i in items if i['kind']==kind];count=sum(all(c['status'] in ['pass','na'] for c in i['checks'].values()) for i in ls)
  test(f'{kind}_pass_count_recomputed',count==result['summary'][kind]['all_checks_pass'],count)
 test('all_nine_checks_recorded',all(set(i['checks'])=={'format','slicing','feet','alpha','repeated','size','palette','assembly','faces'} for i in items))
 luna=next(i for i in items if i['path']=='art/bakeoff/luna/luna-victory-v1.png')['checks']['size']['measurement']['face_landmarks']
 test('wink_exclusion_is_not_a_size_defect',6 not in [f['frame'] for f in luna['frames']] and 6 in luna['excluded_frames'])
 seed=next(i for i in items if i['path']=='art/bakeoff/monsters/vanaheim_seed_sprite-attack-v1.png')['checks']['feet']
 test('leaf_tip_not_confused_with_supporting_foot',seed['status']=='pass' and all(m['measured_bottom_y']==72 for m in seed['measurement']['semantic_support_measurement']['frames']))
 issues=json.loads((a.OUT/'issues.json').read_text(encoding='utf-8'));by={i['path']:i for i in items};valid_flags=True
 for issue in issues:
  if issue['check']=='stable_colour_size':
   cm=by[issue['path']]['checks']['size']['measurement']['colour_component_size']['frames'][issue['frame']-1]
   valid_flags=valid_flags and cm['measurement_valid'] and cm['ratio'] is not None
 test('invalid_colour_components_not_reported_as_size_defects',valid_flags)
 changed=[p for p,h in result['input_sha256'].items() if not (a.ROOT/p).exists() or a.digest(a.ROOT/p)!=h]
 test('all_measured_inputs_unchanged',not changed,{'files':len(result['input_sha256']),'changed':changed})
 test('current_candidate_hashes',all(a.digest(a.ROOT/i['path'])==i['sha256'] for i in items))
 # This test specifically catches the former empty-canvas dilution problem in near-duplicate metrics.
 left=np.zeros((128,128,4),np.uint8);left[60:68,60:68]=[255,0,0,255];right=left.copy();right[60:68,60:68,:3]=[0,0,255]
 metrics=a.pair_metrics(left,right);test('small_sprite_change_not_diluted_by_padding',metrics['mae_union_0_255']>100 and metrics['fraction_changed_gt8']==1,metrics)
 hidden=left.copy();hidden[0,0,:3]=[100,200,50];metrics=a.pair_metrics(left,hidden);test('invisible_rgb_does_not_create_motion',metrics['changed_visible_pixels']==0,metrics)
 # FFT correlation versus direct sums, including rectangular template dimensions.
 rng=np.random.default_rng(81);f=rng.normal(size=(17,21));t=rng.normal(size=(5,7));actual=a.fftcorr(f,t)
 reference=np.array([[np.sum(f[y:y+5,x:x+7]*t) for x in range(15)] for y in range(13)])
 error=float(np.max(np.abs(actual-reference)));test('fft_correlation_equals_direct',error<1e-10,error)
 pixels=rng.integers(20,230,(20,16,4),dtype=np.uint8);pixels[...,3]=255;template=Image.fromarray(pixels);frame=Image.new('RGBA',(96,96));frame.alpha_composite(template,(39,27))
 matched=a.match_template(frame,template,[.8,1.,1.2]);test('masked_ncc_known_translation',matched['scale']==1 and matched['box']==[39,27,55,47] and matched['score']>.999,matched)
 larger=template.resize((20,25),Image.Resampling.LANCZOS);frame=Image.new('RGBA',(96,96));frame.alpha_composite(larger,(31,22));matched=a.match_template(frame,template,[1.,1.25,1.5]);test('masked_ncc_known_scale',matched['scale']==1.25 and matched['box']==[31,22,51,47],matched)
 # Compare a real head measurement with the project's unchanged implementation.
 sys.path.insert(0,str(a.ROOT/'tools/sprite_pipeline'));import head_scale as hs
 anchor=a.imread(a.BAKE/'frey/frey-idle-v2.png').crop((0,0,128,128));frame=a.imread(a.BAKE/'frey/frey-fall-v2.png').crop((0,0,128,128));template=hs.head_template(anchor)
 scale,score=hs.head_scale(frame,template);m=a.match_template(frame,template,hs.SCALES,hs.face_centre(np.asarray(frame)))
 test('fft_head_matches_project_method',abs(m['scale']-scale)<1e-8 and abs(m['score']-score)<2e-5,{'project_scale':scale,'project_score':score,'audit_scale':m['scale'],'audit_score':m['score']})
 # Alpha edge/foreground distinctions and thin component preservation.
 f=np.zeros((12,12,4),np.uint8);f[3:9,3:9]=[100,80,70,255];f[2,5]=[100,80,70,1];s=a.frame_stats(f)
 test('subopaque_margin_is_counted',s['margins_ltrb']==[3,2,3,3] and s['semi_transparent_pixels']==1,s)
 # Validate portrait preservation again with an independent byte-wise mask comparison.
 for i in items:
  if i['kind']!='face':continue
  x=np.array(Image.open(a.ROOT/i['path']).convert('RGBA'));y=np.array(Image.open(a.ROOT/i['metadata']['edited_from']).convert('RGBA'));ok=np.array_equal(x[...,3],y[...,3])
  if i['row']!='shadow':
   mask=np.array(Image.open(a.ROOT/f"reports/codex-art-73/{i['identity']}-{i['row']}-mask.png").convert('L'));ok=ok and np.array_equal(x[mask==0],y[mask==0])
  test('face_preservation_'+Path(i['path']).stem,ok)
 for i in items:
  if i['kind']!='monster_sheet':continue
  im=Image.open(a.ROOT/i['path']).convert('RGBA');ok=True
  for n,row in enumerate(a.ROWS):
   src=Image.open(a.BAKE/'monsters'/f"{i['identity']}-{row}-v1.png").convert('RGBA');ok=ok and im.crop((0,n*96,576,(n+1)*96)).tobytes()==src.tobytes()
  test('sheet_pixel_assembly_'+i['identity'],ok)
 bp=a.OUT/'boards/index.json'
 if bp.exists():
  boards=json.loads(bp.read_text(encoding='utf-8'));test('twenty_distinct_4x_boards',len(boards)==20 and len({b['source'] for b in boards})==20 and all(b['scale']==4 and (a.OUT/b['file']).is_file() for b in boards))
 else:test('twenty_distinct_4x_boards',False,'boards not yet generated')
 manifest=a.OUT/'delivery-files.txt'
 if manifest.exists():
  files=manifest.read_text(encoding='utf-8-sig').splitlines();bad=[p for p in files if not (p.startswith('reports/codex-art-81/') or p in ['design/tasks/CODEX-ART-81.md','design/tasks/CODEX-ART-81.prompt.md']) or '__pycache__' in p or p.endswith('run.log') or not (a.ROOT/p).is_file()]
  test('commit_file_scope',not bad and len(files)==len(set(files)) and 'design/tasks/CODEX-ART-81.md' in files and 'design/tasks/CODEX-ART-81.prompt.md' in files,{'files':len(files),'bad':bad})
 else:test('commit_file_scope',False,'manifest not yet generated')
 cv=json.loads((a.OUT/'commit-validation.json').read_text(encoding='utf-8'))
 test('commit_syntax_only_and_clean_original_files',cv['syntax_valid'] and not cv['script_executed'] and cv['branch']=='codex/art-81' and not cv['tracked_diff'] and not cv['staged_diff'],cv)
 result={'passed':sum(t['pass'] for t in tests),'failed':sum(not t['pass'] for t in tests),'tests':tests,'meaning':'Audit algorithm/coverage and immutable PNG validation, not Godot tests.'}
 a.savej(a.OUT/'verification.json',result);print(json.dumps({k:result[k] for k in ['passed','failed']}));return 0 if result['failed']==0 else 1
if __name__=='__main__':raise SystemExit(main())
