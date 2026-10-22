// No dependencies, downloads or network. SFX embedded; music stays in sidecars.
import {readFileSync, writeFileSync, mkdirSync, copyFileSync} from "node:fs";
import {dirname, join, basename} from "node:path";
import {fileURLToPath} from "node:url";
const here=dirname(fileURLToPath(import.meta.url));
const root=join(here,"../..");
const measurements=JSON.parse(readFileSync(join(root,"reports/codex-aud-01a/measurements.json"),"utf8"));
const musicMeasurements=JSON.parse(readFileSync(join(root,"reports/codex-aud-02a/measurements.json"),"utf8"));
const sounds=[], music=[];
const dist=join(here,"dist");
mkdirSync(join(dist,"audio"),{recursive:true});
for(const r of [...measurements.records,...musicMeasurements.records]){
    if(!/^art\/audio_bakeoff\/[a-z_]+-[abc]\.wav$/.test(r.file)) throw new Error("Unexpected audio path");
    const bytes=readFileSync(join(root,r.file));
    if(bytes.toString("ascii",0,4)!=="RIFF" || bytes.toString("ascii",8,12)!=="WAVE") throw new Error("Not WAV");
    const group=r.sound.startsWith("music_")?music:sounds;
    let sound=group.find(s=>s.id===r.sound);
    if(!sound){sound={id:r.sound,label:r.label,candidates:[]};group.push(sound);}
    const file=`audio/${basename(r.file)}`;
    copyFileSync(join(root,r.file),join(dist,file));
    sound.candidates.push({...r,file,...(group===sounds?{data:`data:audio/wav;base64,${bytes.toString("base64")}`}:{})});
}
if(!sounds.length || music.map(s=>s.id).join(",")!=="music_title,music_battle" || [...sounds,...music].some(s=>s.candidates.map(c=>c.style).join("")!=="abc")) throw new Error("Expected complete A/B/C trios and both music tracks");
const source=readFileSync(join(here,"index.html"),"utf8");
if(!source.includes("/*MANIFEST*/null")) throw new Error("Manifest placeholder missing");
const manifest=JSON.stringify({sounds,music}).replaceAll("<","\\u003c");
writeFileSync(join(dist,"index.html"),source.replace("/*MANIFEST*/null",manifest));
writeFileSync(join(dist,"files.json"),JSON.stringify([...measurements.records,...musicMeasurements.records].map(r=>({path:`audio/${basename(r.file)}`})),null,2)+"\n");
console.log(`sound viewer: ${sounds.length} effects / ${measurements.records.length} embedded WAVs; ${music.length} music tracks / ${musicMeasurements.records.length} external WAVs -> ${dist}`);
