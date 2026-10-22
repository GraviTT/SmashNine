// No dependencies, downloads or network. The Artifact HTML is self-contained.
import {readFileSync, writeFileSync, mkdirSync, copyFileSync} from "node:fs";
import {dirname, join, basename} from "node:path";
import {fileURLToPath} from "node:url";
const here=dirname(fileURLToPath(import.meta.url));
const root=join(here,"../..");
const measurements=JSON.parse(readFileSync(join(root,"reports/codex-aud-01a/measurements.json"),"utf8"));
if(measurements.records.length!==36) throw new Error("Expected 36 measurements");
const sounds=[];
const dist=join(here,"dist");
mkdirSync(join(dist,"audio"),{recursive:true});
for(const r of measurements.records){
    if(!/^art\/audio_bakeoff\/[a-z_]+-[abc]\.wav$/.test(r.file)) throw new Error("Unexpected audio path");
    const bytes=readFileSync(join(root,r.file));
    if(bytes.toString("ascii",0,4)!=="RIFF" || bytes.toString("ascii",8,12)!=="WAVE") throw new Error("Not WAV");
    let sound=sounds.find(s=>s.id===r.sound);
    if(!sound){sound={id:r.sound,label:r.label,candidates:[]};sounds.push(sound);}
    const file=`audio/${basename(r.file)}`;
    copyFileSync(join(root,r.file),join(dist,file));
    sound.candidates.push({...r,file,data:`data:audio/wav;base64,${bytes.toString("base64")}`});
}
if(sounds.length!==12 || sounds.some(s=>s.candidates.map(c=>c.style).join("")!=="abc")) throw new Error("Expected twelve complete A/B/C trios");
const source=readFileSync(join(here,"index.html"),"utf8");
if(!source.includes("/*MANIFEST*/null")) throw new Error("Manifest placeholder missing");
const manifest=JSON.stringify({sounds}).replaceAll("<","\\u003c");
writeFileSync(join(dist,"index.html"),source.replace("/*MANIFEST*/null",manifest));
writeFileSync(join(dist,"files.json"),JSON.stringify(measurements.records.map(r=>({path:`audio/${basename(r.file)}`})),null,2)+"\n");
console.log(`sound viewer: ${sounds.length} cards / 36 embedded WAVs + sidecar WAVs -> ${dist}`);
