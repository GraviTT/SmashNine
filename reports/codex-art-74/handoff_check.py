import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,re,subprocess,datetime,hashlib
from pathlib import Path
import process as p

def git(*args):return subprocess.run(['git',*args],cwd=p.ROOT,check=True,text=True,encoding='utf-8',capture_output=True).stdout.strip()

if __name__=='__main__':
    assert git('branch','--show-current')=='codex/art-74'
    assert not git('diff','--name-only'),'Tracked changes outside new candidate delivery'
    assert not git('diff','--cached','--name-only'),'The unit must leave the index untouched'
    v=json.loads((p.REPORT/'verification.json').read_text('utf-8'));assert v['failures']==[] and v['rows']==36 and v['frames']==168
    bake=[]
    for mid in p.WINDUP:
        for row in p.ROWS:
            bake += [p.BAKE/f'{mid}-{row}-v1.png',p.BAKE/f'{mid}-{row}-v1.json']
        bake += [p.BAKE/f'{mid}_sheet-v1.png']
    assert len(bake)==78 and all(x.is_file() for x in bake)
    for file in bake:assert not git('ls-files','--',file.relative_to(p.ROOT).as_posix()),f'Not a new file: {file}'
    for file in p.REPORT.rglob('*'):
        assert '__pycache__' not in file.parts,'Unexpected bytecode cache'
        if file.is_file() and file.name!='run.log' and file.suffix in ['.py','.ps1','.mjs','.txt','.json','.md','.log']:
            data=file.read_bytes();encoding='utf-16' if data.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig'
            file.write_text(data.decode(encoding).replace('\r\n','\n'),'utf-8',newline='\n')
    manifest=p.REPORT/'delivery-files.txt';manifest.write_text('','utf-8')
    check=p.REPORT/'handoff-check.json';check.write_text('{}','utf-8')
    files=sorted(bake+[f for f in p.REPORT.rglob('*') if f.is_file() and f.name!='run.log' and not f.is_relative_to(p.REPORT/'fix-1/work')])
    relative=[f.relative_to(p.ROOT).as_posix() for f in files]
    assert len(relative)==len(set(relative))
    for path in relative:
        assert path.startswith('reports/codex-art-74/') or path.startswith('art/bakeoff/monsters/')
        assert not any(s in path for s in ['art/raw/','__pycache__','/run.log'])
    manifest.write_text('\n'.join(relative)+'\n','utf-8',newline='\n')
    assert 'reports/codex-art-74/fix-1.prompt.md' in relative
    script=(p.REPORT/'commit.ps1').read_text('utf-8');assert 'git add -f' not in script
    assert script.split("$message = @'\n",1)[1].split("\n'@",1)[0].endswith('Co-Authored-By: Codex <noreply@openai.com>')
    prompts=list(p.REPORT.glob('*/*/prompt*.txt'));assert len(prompts)==55
    counts={}
    for f in prompts:counts.setdefault((f.parent.parent.name,f.parent.name),0);counts[f.parent.parent.name,f.parent.name]+=1
    assert max(counts.values())<=3
    end=datetime.datetime.now(datetime.timezone.utc);start=datetime.datetime(2026,10,22,17,24,55,tzinfo=datetime.timezone.utc)
    sizes=json.loads((p.REPORT/'fix-1/sizes.json').read_text('utf-8'));assert len(sizes)==36 and all(s['within_5_percent'] for s in sizes)
    raws=json.loads((p.REPORT/'accepted-raws.json').read_text('utf-8'));assert len(raws)==36
    for source in raws:assert hashlib.sha256((p.ROOT/source['file']).read_bytes()).hexdigest()==source['sha256'],source['file']
    result=dict(branch='codex/art-74',candidate_files=78,report_files=len(files)-78,manifest_files=len(files),raw_in_manifest=False,working_canvas_files_in_manifest=False,review_prompt_in_manifest=True,tracked_diff=[],staged_diff=[],accepted_raw_hashes_unchanged=len(raws),generation_prompts=55,review_generations=0,max_generations_per_row=max(counts.values()),image_contract_failures=v['failures'],rows_within_5_percent=len(sizes),godot_run=False,commit_script_executed=False,finished_utc=end.isoformat(timespec='seconds'))
    check.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
    print(json.dumps(result,ensure_ascii=False))
