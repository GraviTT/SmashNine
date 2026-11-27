"""Check ART-99a delivered image files and recorded pixel metrics; no game run."""
from pathlib import Path
import hashlib, importlib.util, json, re, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
R=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools/sprite_pipeline'))
import normalize as norm

def main():
    m=json.loads((R/'metrics.json').read_text(encoding='utf-8'))
    checks=[];files=[]
    def check(name,condition):
        checks.append({'check':name,'pass':bool(condition)})
        if not condition:print('FAIL:',name)
    board=Image.new('RGB',(2112,610),'#2a2d34');draw=ImageDraw.Draw(board)
    f=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',19)
    for i,l in enumerate(m['looks']):
        c=l['id'][:-1];n=l['id'][-1];d=ROOT/f'art/bakeoff/newchar-2026-11-26/{c}/{n}'
        for kind,name,size in [('illustration',f'{c}_illustration-{n}.png',(1024,1536)),('face',f'{c}_face-{n}.png',(256,256)),('sprite',f'{c}-idle-{n}.png',(128,128))]:
            p=d/name;im=Image.open(p);a=np.asarray(im)
            check(f'{l["id"]}.{kind}.RGBA_size',im.mode=='RGBA' and im.size==size)
            check(f'{l["id"]}.{kind}.alpha_range',a[:,:,3].min()==0 and a[:,:,3].max()==255)
            files.append({'file':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':list(im.size)})
            if kind=='illustration':
                check(f'{l["id"]}.illustration.clear_border',not(a[0,:,3].any() or a[-1,:,3].any() or a[:,0,3].any() or a[:,-1,3].any()))
                check(f'{l["id"]}.illustration.zero_hidden_RGB',not np.any(a[a[:,:,3]==0,:3]))
        im=Image.open(d/f'{c}-idle-{n}.png').convert('RGBA');a=np.asarray(im);b=im.getbbox()
        check(f'{l["id"]}.sprite.binary_alpha',set(np.unique(a[:,:,3]))=={0,255})
        check(f'{l["id"]}.sprite.margin4',min(b[0],b[1],128-b[2],128-b[3])>=4)
        check(f'{l["id"]}.sprite.feet120',b[3]-1==120)
        check(f'{l["id"]}.sprite.zero_green_spill',norm.spill_pixel_count(im)==0)
        ref_id=l['sprite']['reference_first_idle']; ref_character=ref_id.split('_')[0]
        ref=Image.open(ROOT/f'smash-nine-prototype/assets/art/{ref_character}/{ref_id}_sheet.png').convert('RGBA').crop((0,0,128,128))
        ratio=norm.interior_detail(im)/norm.interior_detail(ref)
        check(f'{l["id"]}.sprite.detail90',ratio>=0.90)
        check(f'{l["id"]}.sprite.matches_pipeline_frame',np.array_equal(a,np.asarray(Image.open(R/'normalize'/l['id']/'frames'/f'{c}-idle-{n}-00.png'))))
        # Left-hand body ROI excludes Jupi's fork/staff; retains crown and both foot levels.
        body_box=im.crop((0,0,74,128)).getbbox() if c=='jupi' else b
        body_h=body_box[3]-body_box[1]
        check(f'{l["id"]}.body_height',88<=body_h<=92 if c=='jupi' else 105<=body_h<=112)
        check(f'{l["id"]}.recorded_body_height',body_h==l['sprite']['body_height_excluding_weapon'])
        if c=='jupi':check('jupi1.staff_taller_than_body',b[1]<body_box[1])
        note=json.loads((d/f'{c}-idle-{n}.json').read_text(encoding='utf-8'))
        check(f'{l["id"]}.note',note.get('frames')==1 and any('\uac00'<=ch<='\ud7a3' for ch in note.get('note','')))
        x=16+i*524;board.paste(im.resize((512,512),Image.Resampling.NEAREST),(x,64),im.resize((512,512),Image.Resampling.NEAREST).getchannel('A'))
        sk=l['sprite']['manual_head_box'][1];ch=l['sprite']['manual_head_box'][3]
        draw.text((x,12),f'{l["id"]} · 수동 약 {l["sprite"]["manual_head_count"]}등신 (±2px)',font=f,fill='white')
        draw.text((x,36),f'몸 {body_h}px / 머리 {ch-sk+1}px / 발 y120',font=f,fill='#cbd2da')
        for yy,col in [(sk,'#5ce0d0'),(ch,'#efc56b'),(120,'#c56e79')]:draw.line((x+4,64+yy*4,x+508,64+yy*4),fill=col,width=1)
    board.save(R/'heads-4x.png',optimize=True)
    tracked=subprocess.run(['git','diff','--name-only','--','smash-nine-prototype'],cwd=ROOT,capture_output=True,text=True)
    staged=subprocess.run(['git','diff','--cached','--name-only'],cwd=ROOT,capture_output=True,text=True)
    branch=subprocess.run(['git','branch','--show-current'],cwd=ROOT,capture_output=True,text=True)
    check('product_source_unchanged',tracked.returncode==0 and not tracked.stdout.strip())
    check('nothing_staged',staged.returncode==0 and not staged.stdout.strip())
    check('correct_branch',branch.stdout.strip()=='codex/newchar-99a')
    for p in [*R.glob('*.py'),*R.glob('*.ps1'),*R.glob('*.md'),*R.glob('*.txt'),R/'metrics.json']:
        p.read_text(encoding='utf-8')
    total=sum(p.stat().st_size for base in [R,ROOT/'art/raw/newchar-99a',ROOT/'art/bakeoff/newchar-2026-11-26/borok',ROOT/'art/bakeoff/newchar-2026-11-26/jupi/1'] for p in base.rglob('*') if p.is_file())
    commit=(R/'commit.ps1').read_text(encoding='utf-8')
    array=re.search(r'\$paths = @\((.*?)\n    \)',commit,re.S).group(1)
    paths=re.findall(r"'([^']+)'",array)
    allowed=['art/bakeoff/newchar-2026-11-26/borok/','art/bakeoff/newchar-2026-11-26/jupi/1/','reports/codex-art-99a/']
    missing=[p for p in paths if not (ROOT/p).is_file()]
    outside=[p for p in paths if p!='design/tasks/CODEX-ART-99.md' and not any(p.startswith(a) for a in allowed)]
    assert not missing and not outside and 'git add -f' not in commit
    assert commit.rstrip().endswith('Co-Authored-By: Codex <noreply@openai.com>')
    handoff={'literal_path_count':len(paths),'missing_paths':missing,'out_of_scope_paths':outside,'force_add':False,'coauthor_footer':True,'powershell_syntax':'commit.ps1 and rebuild.ps1 parsed separately with PowerShell Parser::ParseFile; not executed'}
    result={'checks':checks,'pass':all(c['pass'] for c in checks),'passed':sum(c['pass'] for c in checks),'total':len(checks),'files':files,'task_folder_bytes':total,'handoff':handoff,'game_run':False,'commit_script_executed':False}
    (R/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f"{result['passed']}/{result['total']} checks passed; task files {total/2**20:.2f} MiB; no game run / no commit")
    return 0 if result['pass'] else 1

if __name__=='__main__':raise SystemExit(main())
