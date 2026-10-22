// No dependencies/network. All audio is lazy-loaded sidecars.
import {readFileSync,writeFileSync,mkdirSync,copyFileSync,readdirSync,existsSync} from 'node:fs';
import {dirname,join,basename,resolve} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
const here=dirname(fileURLToPath(import.meta.url));
export const ROOT=join(here,'../..');
export const GROUPS=['Fighters','Skills','Monsters','Realms','Progress','Menus/story'];
const fallbackGroups={swing:'Fighters',skill_cast:'Skills',ult_start:'Skills',monster_attack:'Monsters'};
function listeningNote(r,source){
    const events={
        swing_light:'정면·옆·공중 옆 기본 공격을 시작할 때 재생합니다.',
        swing_heavy:'위·아래 방향의 지상·공중 기본 공격을 시작할 때 재생합니다.',
        hit_launch:'강제 발사 또는 큰 넉백이 가드에 막히지 않고 적중했을 때 재생합니다.',
        hurt:'가드에 막히지 않은 공격이나 환경 피해를 받았을 때 재생합니다.',
        land:'0.12초 이상 공중에 있던 선수가 착지할 때 재생합니다.',
        dash:'프레이·노바·리오의 돌진 기술 준비 동작부터 재생합니다.',
        tumble:'강한 넉백으로 몸이 회전하며 날아가기 시작할 때 재생합니다.',
        ko:'체력이 0이 되어 영구 탈락할 때 재생합니다. 링아웃만으로는 울리지 않습니다.',
        respawn:'링아웃 뒤 복귀하거나 연습용 선수가 부활할 때 재생합니다.',
        collapse_warning:'현재 보고 있는 렐름의 붕괴 경고가 처음 나타날 때 재생합니다.',
        bush_rustle:'수풀 은신 상태가 바뀔 때만 재생합니다. 이동 중 계속 울리지 않습니다.',
        soul_pickup:'사람 플레이어의 소울이 실제로 늘어날 때 재생합니다.',
        card_offer:'사람 플레이어에게 성장 카드 선택창이 처음 열릴 때 재생합니다.',
        card_pick:'사람 플레이어가 고른 성장 카드가 실제 적용될 때 재생합니다.',
        ui_move:'키보드·마우스로 메뉴의 선택 항목을 옮길 때 재생합니다.',
        story_text:'대사 한 줄이 나타날 때 한 번 재생합니다. 글자마다 반복하지 않습니다.',
        story_advance:'다음·건너뛰기 입력을 받아 대사를 넘기거나 즉시 표시할 때 재생합니다.',
        swing:'전용 휘두름 음원이 없을 때 사용하는 공용 소리입니다.',
        skill_cast:'전용 기술 음원이 없을 때 사용하는 공용 시전 소리입니다.',
        ult_start:'전용 궁극기 음원이 없을 때 사용하는 공용 시작 소리입니다.',
        monster_attack:'전용 몬스터 공격 음원이 없을 때 사용하는 공용 소리입니다.',
    };
    if(events[r.sound])return events[r.sound];
    if(r.sound==='ult_luna_brave')return 'Brave 변신 중 Heart Laser 후속 시전이 성공했을 때 재생합니다.';
    if(r.sound.startsWith('skill_'))return `${r.label} 사용이 성공했을 때 재생합니다.`;
    if(r.sound.startsWith('ult_'))return `${r.label} 시전을 시작할 때 한 번 재생합니다.`;
    if(/^monster_(bite|charge|leap|slam|shell|bolt|lob|swoop|blink|homing)$/.test(r.sound))return `${r.label.replace('몬스터 · ','')} 공격을 실제 실행할 때 재생합니다.`;
    return source;
}

export function partitionFiles(files,htmlBytes,{maxFiles=250,maxBytes=60_000_000}={}){
    // Every publish carries index.html too: reserve its slot and bytes.
    if(maxFiles<2||htmlBytes>=maxBytes)throw new Error('HTML cannot fit publish limits');
    const parts=[];let part=[],bytes=htmlBytes;
    for(const file of files){
        if(file.bytes+htmlBytes>maxBytes)throw new Error(`Single audio exceeds publish limit: ${file.path}`);
        if(part.length+2>maxFiles||bytes+file.bytes>maxBytes){parts.push(part);part=[];bytes=htmlBytes;}
        part.push(file);bytes+=file.bytes;
    }
    if(part.length)parts.push(part);
    return parts;
}

export function loadMusic(root=ROOT){
    // Trial first; full AUD-02 supersedes duplicate trial IDs. Read other AUD-02* too.
    const folders=readdirSync(join(root,'reports'),{withFileTypes:true})
        .filter(d=>d.isDirectory()&&/^codex-aud-02/.test(d.name)).map(d=>d.name)
        .sort((a,b)=>a===b?0:a==='codex-aud-02'?1:b==='codex-aud-02'?-1:a.localeCompare(b));
    const rows=new Map(),sources=[];
    for(const folder of folders){
        const path=join(root,'reports',folder,'measurements.json');
        if(!existsSync(path))continue;
        sources.push(`reports/${folder}/measurements.json`);
        for(const r of JSON.parse(readFileSync(path,'utf8')).records||[]){
            if(!r.sound?.startsWith('music_'))continue;
            rows.set(`${r.sound}/${r.style}`,{...r,track:r.track||r.sound.slice(6),source_report:sources.at(-1)});
        }
    }
    return {rows:[...rows.values()],sources};
}

export function build(out=join(here,'dist')){
    const full=join(ROOT,'reports/codex-aud-01/measurements.json');
    const measurements=JSON.parse(readFileSync(existsSync(full)?full:join(ROOT,'reports/codex-aud-01a/measurements.json'),'utf8'));
    const catalog=new Map();
    const catalogText=readFileSync(join(ROOT,'smash-nine-prototype/scripts/audio/AudioCatalog.gd'),'utf8');
    for(const [,id,body] of catalogText.matchAll(/"([a-z_0-9]+)":\s*\{([^}]+)\}/g)){
        const group=body.match(/"group":\s*"([^"]+)"/)[1];
        if(group!=='Music')catalog.set(id,{catalog_group:group,group:fallbackGroups[id]||group});
    }
    const notes=new Map();
    for(const line of readFileSync(join(ROOT,'design/AUDIO.md'),'utf8').split('\n')){
        const cells=line.split('|').slice(1,-1).map(c=>c.trim());
        if(cells.length>=3)notes.set(cells[1].replaceAll('`',''),cells[2]);
    }
    const musicInput=loadMusic(),sounds=[],music=[],files=[];
    mkdirSync(join(out,'audio'),{recursive:true});
    for(const r of [...measurements.records,...musicInput.rows]){
        if(!/^art\/audio_bakeoff\/[a-z_0-9]+-[abc]\.wav$/.test(r.file))throw new Error('Unexpected audio path: '+r.file);
        if(!['a','b','c'].includes(r.style)||basename(r.file)!==`${r.sound}-${r.style}.wav`)throw new Error('Audio ID/style mismatch');
        const bytes=readFileSync(join(ROOT,r.file));
        if(bytes.toString('ascii',0,4)!=='RIFF'||bytes.toString('ascii',8,12)!=='WAVE')throw new Error('Not WAV');
        if(r.sha256&&createHash('sha256').update(bytes).digest('hex')!==r.sha256)throw new Error('Stale measurement: '+r.file);
        const isMusic=r.sound.startsWith('music_'),group=isMusic?music:sounds;
        let sound=group.find(s=>s.id===r.sound);
        if(!sound){
            const meta=isMusic?{group:'Music'}:catalog.get(r.sound);
            if(!meta)throw new Error('Unknown SFX ID');
            const sourceNote=notes.get(r.sound)||r.when_ko||'음악 후보';
            sound={id:r.sound,label:r.label,...meta,when_ko:isMusic?sourceNote:listeningNote(r,sourceNote),candidates:[]};group.push(sound);
        }
        if(sound.candidates.some(c=>c.style===r.style))throw new Error('Duplicate candidate');
        const file=`audio/${basename(r.file)}`;
        copyFileSync(join(ROOT,r.file),join(out,file));
        const {data,...external}=r;
        sound.candidates.push({...external,file});files.push({path:file,bytes:bytes.length});
    }
    if(!sounds.length||[...sounds,...music].some(s=>s.candidates.length!==3||s.candidates.map(c=>c.style).sort().join('')!=='abc'))throw new Error('Expected complete A/B/C trios');
    if(existsSync(full)&&sounds.length!==catalog.size)throw new Error('Incomplete catalog');
    sounds.sort((a,b)=>GROUPS.indexOf(a.group)-GROUPS.indexOf(b.group));
    for(const sound of [...sounds,...music])sound.candidates.sort((a,b)=>a.style.localeCompare(b.style));
    const source=readFileSync(join(here,'index.html'),'utf8');
    if(!source.includes('/*MANIFEST*/null'))throw new Error('Manifest placeholder missing');
    const manifest=JSON.stringify({sounds,music,groups:GROUPS,music_sources:musicInput.sources}).replaceAll('<','\\u003c');
    const html=source.replace('/*MANIFEST*/null',manifest),htmlBytes=Buffer.byteLength(html);
    const parts=partitionFiles(files,htmlBytes);
    writeFileSync(join(out,'index.html'),html);
    writeFileSync(join(out,'files.json'),JSON.stringify(files.map(({path})=>({path})),null,2)+'\n');
    if(parts.length>1)parts.forEach((part,i)=>writeFileSync(join(out,`files-${i+1}.json`),JSON.stringify(part.map(({path})=>({path})),null,2)+'\n'));
    const plan={limits:{max_files_including_html:250,max_bytes_including_html:60_000_000},html_bytes:htmlBytes,
        audio_files:files.length,audio_bytes:files.reduce((sum,f)=>sum+f.bytes,0),music_sources:musicInput.sources,
        parts:parts.map((p,i)=>({manifest:parts.length>1?`files-${i+1}.json`:'files.json',files_including_html:p.length+1,bytes_including_html:htmlBytes+p.reduce((sum,f)=>sum+f.bytes,0)}))};
    writeFileSync(join(out,'publish-plan.json'),JSON.stringify(plan,null,2)+'\n');
    console.log(`sound viewer: ${sounds.length} effects / ${sounds.length*3} sidecars; ${music.length} music tracks / ${music.length*3} sidecars; ${parts.length} publish part(s) -> ${out}`);
    return {sounds,music,files,plan};
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){
    const arg=process.argv.indexOf('--out');
    if(arg>=0&&!process.argv[arg+1])throw new Error('--out needs a directory');
    build(arg>=0?resolve(process.argv[arg+1]):undefined);
}
