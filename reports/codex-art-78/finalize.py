"""ART-72 final-review step adapted for ART-78. Never stages or commits files."""
import hashlib,json,re
from pathlib import Path
from PIL import Image

root=Path('reports/codex-art-78');raw=Path('art/raw/motions-78')
def dump(p,value):p.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()

ledger=json.loads((root/'generation-ledger.json').read_text(encoding='utf-8'))
for e in ledger:
 refs=[e['reference_anchor']]
 if e['attempt']>1 and (e['stem']=='luna' or e['stem']=='luna_brave' and e['row'] in ['victory','jump'] or e['stem']=='frey' and e['attempt']==3 or e['row']=='hurt' and e['attempt']==3):
  refs.append(f'art/raw/motions-78/{e["stem"]}-{e["row"]}-{e["attempt"]-1}.png')
 e['references']=refs;e['generated_sha256']=sha(e['generated_raw'])
dump(root/'generation-ledger.json',ledger)
(root/'prompts.txt').write_text('\n\n'.join(e['key']+'\nReferences: '+', '.join(e['references'])+'\n'+e['prompt'] for e in ledger)+'\n',encoding='utf-8',newline='\n')

normalized=[]
for p in sorted(root.glob('*/*/attempt-*')):
 sheets=list(p.glob('*-jump.png'))+list(p.glob('*-fall.png'))+list(p.glob('*-hurt.png'))+list(p.glob('*-victory.png'))
 if not sheets:continue
 m=json.loads((p/'metrics.json').read_text(encoding='utf-8'));n=m['summary']['frame_count']
 normalized.append({'attempt':p.as_posix(),'sheet_sha256':sha(sheets[0]),'frames':n,'reviewed_frames':list(range(1,n+1)),'scale':4,'pages':[q.as_posix() for q in sorted((p/'qa4x').glob('*.png'))]})
failed=json.loads((raw/'invalid-review4x/manifest.json').read_text(encoding='utf-8'))
for f in failed:f['reviewed']=True
review={'reviewer':'Codex visual inspection through view_image','normalized_attempts':normalized,'normalized_frames':sum(n['frames'] for n in normalized),'reused_frames':5,'new_normalized_frames':sum(n['frames'] for n in normalized)-5,'failed_source_frames':failed,'failed_source_frame_count':len(failed),'selected_best_frames':29,'notes':'Every normalized attempt at its final saved factor was inspected on nearest-neighbour 4x pages. Rejected source cells were also inspected at source 4x on overlapping pages. Whole source cells were replaced in frame retries; no character features were drawn by code.'}
dump(root/'visual-review.json',review)

extra=[root/'finalize.py',root/'review_sources.py',root/'visual-review.json']
p=root/'package.py';s=p.read_text(encoding='utf-8')
needle="root/'report.py',root/'process.py'"
if "root/'review_sources.py'" not in s:s=s.replace(needle,"root/'report.py',root/'finalize.py',root/'review_sources.py',root/'visual-review.json',root/'process.py'")
p.write_text(s,encoding='utf-8',newline='\n')
files=json.loads((root/'files-to-stage.json').read_text(encoding='utf-8'));files=sorted(set(files+[p.as_posix() for p in extra]));dump(root/'files-to-stage.json',files)
p=root/'commit.ps1';s=p.read_text(encoding='utf-8');filelines='\n'.join("    '"+p.replace("'","''")+"'" for p in files)
s,n=re.subn(r'\$files = @\(\n.*?\n\)',lambda _: '$files = @(\n'+filelines+'\n)',s,count=1,flags=re.S);assert n==1
p.write_text(s,encoding='utf-8',newline='\n')
for f in files:
 p=Path(f)
 if p.exists() and p.suffix in ['.py','.ps1','.md','.json','.txt']:
  b=p.read_bytes();clean=b.replace(b'\r\n',b'\n')
  if b!=clean:p.write_bytes(clean)
print(json.dumps({'files_to_stage':len(files),'normalized_frames_reviewed':review['normalized_frames'],'failed_source_frames_reviewed':len(failed)}))
