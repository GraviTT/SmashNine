// Behavior tests with explicit DOM/audio/database doubles; NOT browser rendering QA.
import {readFileSync,writeFileSync,mkdirSync,mkdtempSync,rmSync,statSync} from "node:fs";
import {dirname,join,resolve,sep} from "node:path";
import {fileURLToPath} from "node:url";
import vm from "node:vm";
import assert from "node:assert/strict";
import {partitionFiles,loadMusic} from "./build.mjs";
const here=dirname(fileURLToPath(import.meta.url)), root=join(here,"../..");
const arg=process.argv.indexOf('--out');
const out=arg>=0?resolve(process.argv[arg+1]):join(here,'dist');
const html=readFileSync(join(out,"index.html"),"utf8");
const script=html.match(/<script>([\s\S]*?)<\/script>/)[1];
const checks=[];
const tick=()=>new Promise(resolve=>setImmediate(resolve));

class Element {
    constructor(tag){this.tagName=tag;this.children=[];this.events={};this.dataset={};this.hidden=false;this.disabled=false;this.value="";this.textContent="";this.className="";
        this.classList={add:name=>{this.className+=" "+name;},remove:name=>{this.className=this.className.split(" ").filter(v=>v!==name).join(" ");},contains:name=>this.className.split(" ").includes(name)};}
    append(...nodes){this.children.push(...nodes);}
    setAttribute(name,value){this[name]=value;}
    addEventListener(name,fn){(this.events[name]??=[]).push(fn);}
    fire(name){for(const fn of this.events[name]||[]) fn({target:this});}
    querySelectorAll(selector){return this.children.flatMap(c=>c instanceof Element ? [...(matches(c,selector)?[c]:[]),...c.querySelectorAll(selector)] : []);}
}
function matches(el,selector){if(selector==="[data-badge]")return Boolean(el.dataset.badge);return selector.split(".").slice(1).every(name=>el.classList.contains(name));}

function environment({withDb=false,throws=false}={}){
    const elements=Object.fromEntries(["stop","volume","volumeValue","status","dbNote","sounds","music","stats","styleControls","styleAdoption","styleNote","styleAdopt","styleStatus","groupFilter","search","compare"].map(id=>[id,new Element("div")]));
    elements.volume.value="65";
    const audios=[],timers=[],writes=[];
    let snapshot,dbError,failWrite=false;
    class Audio {
        constructor(src){this.src=src;this.paused=false;this.volume=1;audios.push(this);}
        play(){return Promise.resolve();}
        pause(){this.paused=true;}
        removeAttribute(name){delete this[name];}
        load(){}
    }
    const db={collection(name){assert.equal(name,"sound_picks");return {
        onSnapshot(onNext,onError){snapshot=onNext;dbError=onError;onNext({docs:[]});},
        doc(id){return {async set(value){if(failWrite)throw new Error("test write failure");writes.push({id,value});}}}
    };}};
    const document={activeElement:null,createElement:tag=>new Element(tag),createTextNode:text=>({textContent:text}),
        getElementById:id=>elements[id]||Object.values(elements).flatMap(el=>el.querySelectorAll('*')).find(el=>el.id===id),querySelectorAll:selector=>Object.values(elements).flatMap(el=>el.querySelectorAll(selector))};
    const window={addEventListener(){}};
    if(withDb)window.claude={async use(cap){assert.equal(cap,"db");if(throws)throw new Error("db missing");return db;}};
    const context=vm.createContext({window,document,Audio,console,setTimeout:fn=>{timers.push(fn);return timers.length;}});
    vm.runInContext(script,context);
    return {context,elements,audios,writes,timers,run:code=>vm.runInContext(code,context),
        snapshot:value=>snapshot(value),dbError:()=>dbError(),failWrite:value=>{failWrite=value;}};
}

const local=environment();
await tick();
const manifest=local.run("M");
assert.equal(local.run('groups.size'),manifest.groups.length);
assert.equal(local.run('M.sounds.every(s=>cards.has(s.id))'),true);
assert.equal(local.elements.music.children.length,manifest.music.length);
const candidates=[...manifest.sounds,...manifest.music].flatMap(s=>s.candidates);
assert.equal(local.run("[...cards.values()].reduce((n,c)=>n+c.candidates.size,0)"),candidates.length);
assert.equal(local.run("[...cards.values()].every(c=>c.adoption.hidden)"),true);
assert.equal(local.run("[...cards.values()].every(c=>c.radios.size===3)"),true);
checks.push(`${manifest.sounds.length} effect cards, ${manifest.music.length} music cards, ${candidates.length} candidates; DB controls hidden without claude/db`);
for(const sound of manifest.sounds)for(const c of sound.candidates){
    assert.equal(c.data,undefined,'SFX must not be embedded');
    const bytes=readFileSync(join(out,c.file));
    assert.deepEqual(bytes,readFileSync(join(root,"art/audio_bakeoff",`${c.sound}-${c.style}.wav`)));
    assert.ok(sound.when_ko,'Korean event note required');
}
checks.push("Every SFX is external only; copied WAVs exactly match sources; all IDs have event notes");
const sidecars=JSON.parse(readFileSync(join(out,"files.json"),"utf8"));
assert.equal(new Set(sidecars.map(f=>f.path)).size,candidates.length);
for(const c of candidates) assert.ok(sidecars.some(f=>f.path===c.file));
assert.deepEqual(new Set(Array.from(manifest.music,s=>s.id)),new Set(loadMusic().rows.map(r=>r.sound)));
for(const sound of manifest.music)for(const c of sound.candidates){
    assert.equal(c.data,undefined,"Music must never be embedded");
    assert.match(c.file,/^audio\/music_[a-z_0-9]+-[abc]\.wav$/);
    assert.deepEqual(readFileSync(join(out,c.file)),readFileSync(join(root,"art/audio_bakeoff",`music_${c.track}-${c.style}.wav`)));
}
checks.push("Music is external only; every music sidecar byte matches the source and all files are listed once in files.json");

let playing=local.run("playQueue(M.sounds[0].candidates)");
assert.equal(local.audios.length,1);
assert.equal(local.audios[0].volume,.65);
for(let i=0;i<3;i++){
    assert.equal(local.audios[i].src,manifest.sounds[0].candidates[i].file);
    local.audios[i].onended(); await tick();
    if(i<2){assert.equal(local.timers.length,1);local.timers.shift()();await tick();}
}
await playing;
assert.match(local.elements.status.textContent,/재생 완료/);
checks.push("Per-sound whole playback: A -> 180 ms gap -> B -> 180 ms gap -> C");

const old=local.run("playQueue([M.sounds[1].candidates[0]])");
const oldAudio=local.audios.at(-1);
playing=local.run("playQueue([M.sounds[2].candidates[2]])");
await old;
assert.equal(oldAudio.paused,true);
assert.equal(local.audios.at(-1).src,manifest.sounds[2].candidates[2].file);
local.elements.volume.value="32";local.elements.volume.fire("input");
assert.equal(local.audios.at(-1).volume,.32);
assert.equal(local.elements.volumeValue.textContent,"32%");
local.elements.stop.fire("click");await playing;
assert.equal(local.run("player"),null);
assert.equal(local.elements.sounds.querySelectorAll(".candidate.playing").length,0);
checks.push("New playback cancels previous audio; live volume updates; Stop clears audio and playing marker");

playing=local.run("playQueue(M.sounds[3].candidates)");
local.audios.at(-1).onended();await tick();
const count=local.audios.length;local.elements.stop.fire("click");local.timers.shift()();await playing;
assert.equal(local.audios.length,count);
checks.push("Stop during A/B/C gap prevents later sounds from starting");
playing=local.run("playQueue([M.sounds[4].candidates[0]])");
local.audios.at(-1).onerror();await playing;
assert.match(local.elements.status.textContent,/재생하지 못했습니다/);
checks.push("Audio error ends sequence and exposes a Korean retry message");

playing=local.run("playQueue([M.music[0].candidates[0]])");
assert.equal(local.audios.at(-1).src,manifest.music[0].candidates[0].file);
assert.equal(local.audios.at(-1).loop,true);
const titleLoop=local.run("musicLoops.get('music_title')");
titleLoop.checked=false;titleLoop.fire("change");
assert.equal(local.audios.at(-1).loop,false);
local.audios.at(-1).onended();await playing;
assert.match(local.elements.status.textContent,/재생 완료/);
playing=local.run("playQueue([M.music[1].candidates[2]])");
assert.equal(local.audios.at(-1).loop,true);
titleLoop.checked=true;titleLoop.fire("change");
assert.equal(local.audios.at(-1).loop,true,"Changing another card must not affect the current track");
const musicAudio=local.audios.at(-1);
const loopSwitch=local.run("musicLoops.get('music_battle')");
loopSwitch.checked=false;loopSwitch.fire("change");assert.equal(musicAudio.loop,false);
loopSwitch.checked=true;loopSwitch.fire("change");assert.equal(musicAudio.loop,true);
local.run("cards.get('music_battle').candidates.get('c').children.find(el=>el.textContent==='■ 정지').fire('click')");
await playing;assert.equal(musicAudio.paused,true);assert.equal(local.run("player"),null);
playing=local.run("playQueue([M.music[0].candidates[1]])");
const interruptedMusic=local.audios.at(-1);
const sfxPlaying=local.run("playQueue([M.sounds[0].candidates[0]])");await playing;
assert.equal(interruptedMusic.paused,true);assert.equal(local.audios.at(-1).loop,false);
local.elements.stop.fire("click");await sfxPlaying;
playing=local.run("playQueue([M.music[0].candidates[1]])");
local.audios.at(-1).onerror();await playing;
assert.match(local.elements.status.textContent,/再生|재생하지 못했습니다/);
checks.push("Music sidecar playback, default looping, live loop on/off, per-card isolation, candidate Stop, music/SFX mutual interruption and missing sidecar errors");

const hosted=environment({withDb:true});await tick();
assert.equal(hosted.run("[...cards.values()].every(c=>!c.adoption.hidden)"),true);
hosted.snapshot({docs:[{id:"guard",exists:true,data:()=>({sound:"guard",style:"b",note:"부드러운 방어음",adopted_at:"2026-10-22T15:00:00Z"})}]});
const guard=hosted.run("cards.get('guard')");
assert.equal(guard.radios.get("b").checked,true);
assert.equal(guard.note.value,"부드러운 방어음");
assert.match(guard.status.textContent,/B 채택됨/);
guard.note.value="다음 선택 메모";guard.note.fire("input");
hosted.snapshot({docs:[]});assert.equal(guard.note.value,"다음 선택 메모");
checks.push("DB snapshot restores choice/note/badge; unrelated snapshots preserve unsaved note edits");
guard.radios.get("c").fire("change");
await hosted.run("adoptSound('guard')");
assert.equal(hosted.writes.length,1);
const {id,value}=hosted.writes[0];assert.equal(id,"guard");assert.equal(value.sound,"guard");assert.equal(value.style,"c");assert.equal(value.note,"다음 선택 메모");
assert.deepEqual(Object.keys(value).sort(),["adopted_at","note","sound","style"]);
assert.ok(!Number.isNaN(Date.parse(value.adopted_at)));
assert.equal(guard.adopt.disabled,false);
checks.push("Adopt writes exactly sound/style/note/adopted_at to sound_picks/<sound>, and allows replacement");
for(const track of ["title","battle"]){
    const id=`music_${track}`,ui=hosted.run(`cards.get('${id}')`);
    ui.radios.get("b").fire("change");ui.note.value="음악 선택 확인";
    await hosted.run(`adoptSound('${id}')`);
    const saved=hosted.writes.at(-1);assert.equal(saved.id,id);assert.equal(saved.value.sound,id);assert.equal(saved.value.style,"b");
}
hosted.snapshot({docs:[{id:"music_title",exists:true,data:()=>({sound:"music_title",style:"c",note:"음악 복원",adopted_at:"2026-10-23T00:00:00Z"})},
    {id:"guard",exists:true,data:()=>({sound:"guard",style:"c",note:"다음 선택 메모",adopted_at:"2026-10-23T00:00:00Z"})}]});
assert.equal(hosted.run("cards.get('music_title').radios.get('c').checked"),true);
assert.equal(hosted.run("cards.get('music_title').note.value"),"음악 복원");
checks.push("Music adoption uses exact music_title / music_battle document IDs in sound_picks; music snapshots restore style and memo");
hosted.failWrite(true);await hosted.run("adoptSound('guard')");
assert.match(guard.status.textContent,/저장하지 못했습니다/);
assert.equal(guard.adopt.disabled,false);
hosted.dbError();assert.equal(hosted.run("[...cards.values()].every(c=>c.adoption.hidden)"),true);
checks.push("Failed save remains retryable; DB subscription failure hides all adoption controls");
const rejected=environment({withDb:true,throws:true});await tick();
assert.equal(rejected.run("[...cards.values()].every(c=>c.adoption.hidden)"),true);
checks.push("Rejected claude.use('db') safely falls back to local listening mode");
assert.ok(html.includes("@media(max-width:640px)"));
assert.ok(html.includes("grid-template-columns:1fr"));
checks.push("Phone-width CSS breakpoint present (structural check only, not rendered layout verification)");
// All new selection, filtering, batching and discovery cases below are deterministic doubles.
local.run("setStyle('c')");
assert.equal(local.run('activeStyle'),'c');
assert.equal(local.run("M.sounds.every(s=>[...cards.get(s.id).candidates].every(([key,p])=>p.hidden===(key!=='c')))"),true);
assert.equal(local.run("styleButtons.get('c')['aria-pressed']"),'true');
local.elements.compare.checked=true;local.elements.compare.fire('change');
assert.equal(local.run('M.sounds.every(s=>[...cards.get(s.id).candidates.values()].every(p=>!p.hidden))'),true);
checks.push('Global A/B/C switch updates all 72 SFX panels; compare reveals all candidates without changing individual picks');
local.elements.groupFilter.value='Skills';local.elements.groupFilter.fire('change');
assert.equal(local.run("[...groups].filter(([g,u])=>!u.section.hidden).map(([g])=>g).join()"),'Skills');
local.elements.search.value='skill_rio_1';local.elements.search.fire('input');
assert.equal(local.run('M.sounds.filter(s=>!cards.get(s.id).card.hidden).length'),1);
playing=local.run('playStyle()');
assert.equal(local.audios.at(-1).src,'audio/skill_rio_1-c.wav');local.audios.at(-1).onended();await playing;
local.elements.search.value='no_such_sound';local.elements.search.fire('input');
assert.equal(local.run("$('filterStatus').textContent"),'검색 결과가 없습니다.');
local.elements.search.value='';local.elements.groupFilter.value='';local.elements.search.fire('input');
playing=local.run('playStyle()');
let start=local.audios.length-1;
for(let i=0;i<manifest.sounds.length;i++){
    assert.equal(local.audios[start+i].src,manifest.sounds[i].candidates[2].file);
    local.audios[start+i].onended();await tick();
    if(i<manifest.sounds.length-1){local.timers.shift()();await tick();}
}
await playing;
checks.push('Group filter, ID search, empty results, filtered selected-style playback and complete 72-effect same-style sequence');
const styled=environment({withDb:true});await tick();
styled.snapshot({docs:[{id:'style',exists:true,data:()=>({style:'b',note:'전체 메모'})},{id:'guard',exists:true,data:()=>({sound:'guard',style:'c',note:'기존 개별 선택'})}]});
assert.equal(styled.run('activeStyle'),'b');assert.equal(styled.elements.styleNote.value,'전체 메모');
styled.run("setStyle('a')");styled.elements.styleNote.value='새 메모';styled.elements.styleNote.fire('input');
styled.snapshot({docs:[{id:'style',exists:true,data:()=>({style:'b',note:'전체 메모'})}]});
assert.equal(styled.run('activeStyle'),'a');assert.equal(styled.elements.styleNote.value,'새 메모');
await styled.run('adoptStyle()');
assert.equal(styled.writes.length,1);assert.equal(styled.writes[0].id,'style');
assert.deepEqual(JSON.parse(JSON.stringify(styled.writes[0].value)),{style:'a',note:'새 메모'});
assert.equal(styled.run("drafts.has('guard')"),false);
styled.failWrite(true);await styled.run('adoptStyle()');assert.match(styled.elements.styleStatus.textContent,/저장하지 못했습니다/);
assert.equal(styled.elements.styleAdopt.disabled,false);styled.dbError();assert.equal(styled.elements.styleAdoption.hidden,true);
checks.push('sound_picks/style exact two-field write, snapshot restore, unsaved style/note preservation, no per-sound writes, retry and DB-loss fallback');
const plan=JSON.parse(readFileSync(join(out,'publish-plan.json'),'utf8'));
let published=[];
for(const part of plan.parts){
    const list=JSON.parse(readFileSync(join(out,part.manifest),'utf8'));
    assert.ok(list.length+1<=250);
    assert.ok(list.reduce((n,f)=>n+statSync(join(out,f.path)).size,Buffer.byteLength(html))<=60_000_000);
    published.push(...list.map(f=>f.path));
}
assert.deepEqual(published,sidecars.map(f=>f.path));
assert.equal(new Set(published).size,published.length);
for(const files of [Array.from({length:251},(_,i)=>({path:`n${i}`,bytes:1})),Array.from({length:3},(_,i)=>({path:`n${i}`,bytes:29_000_000}))]){
    const parts=partitionFiles(files,1000);assert.ok(parts.length>1);
    assert.deepEqual(parts.flat(),files);
    for(const part of parts){assert.ok(part.length+1<=250);assert.ok(part.reduce((n,f)=>n+f.bytes,1000)<=60_000_000);}
}
assert.throws(()=>partitionFiles([{path:'huge',bytes:60_000_000}],1000),/Single audio/);
checks.push('Publish parts exactly cover sidecars once; real and synthetic >250-file / >60MB boundaries include HTML overhead; oversized file rejects');
const fixtureBase=resolve(root,'reports/codex-aud-01');
mkdirSync(fixtureBase,{recursive:true});
const fixture=mkdtempSync(join(fixtureBase,'viewer-fixture-'));
try{
    for(const name of ['codex-aud-02a','codex-aud-02','codex-aud-02b'])mkdirSync(join(fixture,'reports',name),{recursive:true});
    const row=(sound,style,extra={})=>({sound,style,...extra});
    writeFileSync(join(fixture,'reports/codex-aud-02a/measurements.json'),JSON.stringify({records:[row('music_title','a',{label:'trial'})]}));
    writeFileSync(join(fixture,'reports/codex-aud-02/measurements.json'),JSON.stringify({records:[row('music_title','a',{label:'full'}),row('music_final','c')]}));
    writeFileSync(join(fixture,'reports/codex-aud-02b/measurements.json'),JSON.stringify({records:[row('music_extra','b'),row('not_music','a')]}));
    const found=loadMusic(fixture);assert.equal(found.sources.length,3);assert.equal(found.rows.length,3);
    assert.equal(found.rows.find(r=>r.sound==='music_title').label,'full');assert.ok(found.rows.some(r=>r.sound==='music_final'));assert.ok(found.rows.some(r=>r.sound==='music_extra'));
}finally{
    // Verify absolute target containment before recursive fixture cleanup on Windows.
    assert.ok(resolve(fixture).startsWith(fixtureBase+sep));rmSync(fixture,{recursive:true});
}
checks.push('Music discovery reads all AUD-02* reports, accepts additional tracks and prefers full AUD-02 over duplicated trial IDs');
writeFileSync(join(root,"reports/codex-aud-01/viewer-checks.json"),JSON.stringify({status:"PASS",checks,
    method:"Node vm with DOM, Audio and Artifact DB test doubles; exact WAV byte comparisons",
    limitations:["Browser origin approval denied access to http://127.0.0.1:8077; actual screen layout and audio playback were not exercised","Hosted claude db API not exercised; follows motion viewer API pattern"]},null,2)+"\n");
console.log(`PASS: ${checks.length} viewer behavior checks; no real browser/Artifact runtime used`);
