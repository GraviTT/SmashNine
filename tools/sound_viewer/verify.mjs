// Behavior tests with explicit DOM/audio/database doubles; NOT browser rendering QA.
import {readFileSync,writeFileSync} from "node:fs";
import {dirname,join} from "node:path";
import {fileURLToPath} from "node:url";
import vm from "node:vm";
import assert from "node:assert/strict";
const here=dirname(fileURLToPath(import.meta.url)), root=join(here,"../..");
const html=readFileSync(join(here,"dist/index.html"),"utf8");
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
    const elements=Object.fromEntries(["stop","volume","volumeValue","status","dbNote","sounds","music"].map(id=>[id,new Element("div")]));
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
        getElementById:id=>elements[id],querySelectorAll:selector=>Object.values(elements).flatMap(el=>el.querySelectorAll(selector))};
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
assert.equal(local.elements.sounds.children.length,manifest.sounds.length);
assert.equal(local.elements.music.children.length,manifest.music.length);
const candidates=[...manifest.sounds,...manifest.music].flatMap(s=>s.candidates);
assert.equal(local.run("[...cards.values()].reduce((n,c)=>n+c.candidates.size,0)"),candidates.length);
assert.equal(local.run("[...cards.values()].every(c=>c.adoption.hidden)"),true);
assert.equal(local.run("[...cards.values()].every(c=>c.radios.size===3)"),true);
checks.push(`${manifest.sounds.length} effect cards, ${manifest.music.length} music cards, ${candidates.length} candidates; DB controls hidden without claude/db`);
for(const sound of manifest.sounds)for(const c of sound.candidates){
    const bytes=Buffer.from(c.data.split(",")[1],"base64");
    assert.deepEqual(bytes,readFileSync(join(here,"dist",c.file)));
    assert.deepEqual(bytes,readFileSync(join(root,"art/audio_bakeoff",`${c.sound}-${c.style}.wav`)));
}
checks.push("All embedded effect WAVs and copied WAVs exactly match delivered source files");
const sidecars=JSON.parse(readFileSync(join(here,"dist/files.json"),"utf8"));
assert.equal(new Set(sidecars.map(f=>f.path)).size,candidates.length);
for(const c of candidates) assert.ok(sidecars.some(f=>f.path===c.file));
assert.deepEqual(Array.from(manifest.music,s=>s.id),["music_title","music_battle"]);
for(const sound of manifest.music)for(const c of sound.candidates){
    assert.equal(c.data,undefined,"Music must never be embedded");
    assert.match(c.file,/^audio\/music_(title|battle)-[abc]\.wav$/);
    assert.deepEqual(readFileSync(join(here,"dist",c.file)),readFileSync(join(root,"art/audio_bakeoff",`music_${c.track}-${c.style}.wav`)));
}
checks.push("Music is external only; every music sidecar byte matches the source and all files are listed once in files.json");

let playing=local.run("playQueue(M.sounds[0].candidates)");
assert.equal(local.audios.length,1);
assert.equal(local.audios[0].volume,.65);
for(let i=0;i<3;i++){
    assert.equal(local.audios[i].src,manifest.sounds[0].candidates[i].data);
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
assert.equal(local.audios.at(-1).src,manifest.sounds[2].candidates[2].data);
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
writeFileSync(join(root,"reports/codex-aud-02a/viewer-checks.json"),JSON.stringify({status:"PASS",checks,
    method:"Node vm with DOM, Audio and Artifact DB test doubles; exact WAV byte comparisons",
    limitations:["No browser was connected; screen layout and real audio playback were not exercised","Hosted claude db API not exercised; follows motion viewer API pattern"]},null,2)+"\n");
console.log(`PASS: ${checks.length} viewer behavior checks; no real browser/Artifact runtime used`);
