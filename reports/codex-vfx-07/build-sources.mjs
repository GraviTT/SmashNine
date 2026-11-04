import { mkdirSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
const ROOT=new URL("../../art/bakeoff/effects/pixelfx/frey/b/",import.meta.url);
const items=[
  {id:"jfx_up",kind:"follow",aimDeg:-83,reach:155,floorY:32,size:[200,250],origin:[70,190],frames:16,row:0,bodyFps:16.8,startup:0.12,recovery:0.23,air:false,note:"위로 벤 검의 호에서 금빛 쇳불꽃이 흩어지고, 떨어진 불꽃은 발 높이에서 한 번 튄다."},
  {id:"jfx_up_air",kind:"follow",aimDeg:-83,reach:155,floorY:null,size:[200,370],origin:[70,190],frames:16,row:0,bodyFps:16.8,startup:0.12,recovery:0.23,air:true,note:"공중 대공 베기 뒤 금빛 검날 흔적과 반짝임이 남고 불꽃은 바닥 없이 아래로 떨어진다."},
  {id:"jfx_down",kind:"follow",aimDeg:15,reach:157,floorY:32,size:[300,150],origin:[35,90],frames:15,row:1,bodyFps:17.85,startup:0.17,recovery:0.29,air:false,note:"지상의 15도 내려 베기를 따라 금빛 검날 조각이 남고 쇳불꽃이 발 높이에서 튄다."},
  {id:"jfx_down_air",kind:"follow",aimDeg:73,reach:157,floorY:null,size:[240,440],origin:[65,95],frames:14,row:1,bodyFps:17.85,startup:0.17,recovery:0.29,air:true,note:"공중의 73도 내려 베기 뒤 금빛 궤적이 조각나고 쇳불꽃이 아래로 길게 흩어진다."},
  {id:"jfx_side_air",kind:"follow",aimDeg:-2,reach:186,floorY:null,size:[330,360],origin:[35,100],frames:16,row:2,bodyFps:18.9,startup:0.106,recovery:0.17,air:true,note:"공중 옆 베기의 끝과 휘어진 검날에 금빛 반짝임이 남고 불꽃이 앞으로 튀며 낙하한다."},
  {id:"hit_after",kind:"hit",big:false,size:[160,150],origin:[75,70],frames:9,note:"기존 적중 불꽃이 잦아들 때 몸 양옆에 짧은 금빛 검날 조각과 작은 쇳불꽃이 남는다."},
  {id:"hit_after_big",kind:"hit",big:true,size:[200,180],origin:[90,80],frames:12,note:"강한 적중 뒤 더 큰 검날 조각과 다섯 반짝임이 남고 쇳불꽃이 넓게 흩어진다. 몸 중앙은 비운다."},
];
const text=(url,s)=>writeFileSync(url,s.trimEnd()+"\n");
mkdirSync(new URL("src/",ROOT),{recursive:true});
text(new URL("package.json",ROOT),JSON.stringify({private:true,type:"module"},null,2));
text(new URL("items.json",ROOT),JSON.stringify(items,null,2));
for(const item of items){
 const base=`frey_${item.id}-b`, module=`sn-frey-${item.id.replaceAll("_","-")}-b.js`, duration=item.frames/20;
 const opts=item.kind==="follow"?{aimDeg:item.aimDeg,reach:item.reach,floorY:item.floorY,duration,seed:71}:{big:item.big,duration,seed:83};
 const source=`// CODEX-VFX-07: ${item.note}\nimport { resolveOptions } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";\nimport { PALETTE, ${item.kind==="follow"?"createFollow":"createHit"} } from "./frey-b-common.mjs";\nexport const meta = ${JSON.stringify({name:base,desc:item.note,tags:["smashnine","frey","candidate-b","one-shot"],size:item.size,origin:item.origin,duration,loop:false,fps:20,options:opts},null,2)};\nmeta.options.palette = PALETTE;\nexport const create = (o) => ${item.kind==="follow"?"createFollow":"createHit"}(resolveOptions(meta,o));\n`;
 text(new URL(`src/${module}`,ROOT),source);
}
console.log(`Wrote ${items.length} candidate B modules to ${fileURLToPath(ROOT)}`);
