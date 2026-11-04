import {mkdirSync,writeFileSync} from "node:fs";
const repo=new URL("../../",import.meta.url),write=(p,t)=>writeFileSync(p,t.trimEnd()+"\n","utf8");
const items=[
  {id:"luna_step",family:"luna",kind:"step",duration:.35,size:[100,48],origin:[78,34],blend:"mix",note:"앞발 뒤로 분홍 먼지와 금빛 별가루가 낮게 흐른다. 한 걸음 0.35초에 끝난다.",attach:"걷기 4·8번째 그림의 앞발, 발 기준 +17·18px. 한 걸음(4그림) 동안 재생."},
  {id:"luna_jump",family:"luna",kind:"jump",duration:.6,size:[180,70],origin:[90,48],blend:"mix",note:"도약 자리에서 별가루가 양옆으로 밀려나며 뒤쪽에 더 오래 남는다.",attach:"지상 점프 출발 순간 발 위치에 한 번, 오른쪽 기준."},
  {id:"luna_air_jump",family:"luna",kind:"air",duration:.7,size:[190,110],origin:[95,25],blend:"add",note:"공중 발밑에서 열린 두 갈래 별빛과 별조각이 아래·바깥으로 흐른다.",attach:"공중 점프 순간 발 위치에 한 번, 오른쪽 기준."},
  ...[
    ["brave_rush_1","jab",-1,131,.5,[250,150],[35,65],0,1,.1],
    ["brave_rush_2","kick",-3,147,.6,[270,160],[35,65],0,3,.11],
    ["brave_rush_3","spin",-22,157,.7,[280,200],[40,120],0,5,.18],
    ["brave_up","upper",-83,156,.7,[200,280],[80,235],1,2,.14],
    ["brave_low","low",-3,157,.6,[270,145],[35,48],2,2,.14],
    ["brave_side_air","fly",-5,170,.6,[290,170],[35,75],3,2,.12],
    ["brave_down_air","dive",81,206,.8,[200,360],[70,50],4,2,.18]
  ].map(([id,kind,aimDeg,reach,duration,size,origin,row,strike,recovery])=>({id,kind,aimDeg,reach,duration,size,origin,row,strike,recovery,family:"luna_brave",blend:"add",note:`${{jab:"잽",kick:"보디 킥",spin:"회전 킥",upper:"어퍼컷",low:"낮은 후리기",fly:"비행 킥",dive:"급강하 킥"}[kind]} 방향을 따라 끊어진 분홍·금빛 선과 별조각이 남고 아래로 가라앉는다.`,attach:`luna_brave_slash와 같은 시작 순간·몸 중심(발보다 32px 위). 각도 ${aimDeg}도, 도달거리 ${reach}px를 그림에 반영. 좌우 반전만 사용, 회전 금지. ${kind==="low"?"낮은 후리기는 그림 안에서 발 높이 +32px로 내렸다.":""}`})),
  {id:"brave_hit_after",family:"luna_brave",kind:"hit",duration:.6,size:[240,140],origin:[105,65],blend:"add",note:"적중 불꽃 바깥에 분홍·금빛 별조각이 전방으로 길게 흐른다. 중심은 비운다.",attach:"Brave 근접 적중마다 피격 몸 중심에 한 번. 기본 넉백 400 미만."},
  {id:"brave_hit_after_big",family:"luna_brave",kind:"hit",big:true,duration:.8,size:[290,175],origin:[125,70],blend:"add",note:"강한 적중 뒤 더 넓고 긴 별조각 여운. 중심 섬광은 기존 적중 그림이 담당한다.",attach:"Brave 근접 강타 적중마다 피격 몸 중심에 한 번. 기본 넉백 400 이상: 회전 킥 520, 어퍼컷 430, 급강하 475."}
];
for(const [i,s] of items.entries()) {
  s.fps=20;s.frames=Math.round(s.duration*s.fps);s.seed=909+i*37;
  const dir=new URL(`art/bakeoff/effects/pixelfx/${s.family}/b/`,repo);mkdirSync(new URL("src/",dir),{recursive:true});
  const helper=s.family==="luna"?"luna-feet-b.mjs":"brave-linger-b.mjs",fn=s.family==="luna"?"draw":s.kind==="hit"?"drawHit":"drawFollow";
  const options={kind:s.kind,duration:s.duration,seed:s.seed};for(const k of ["aimDeg","reach","big"])if(s[k]!==undefined)options[k]=s[k];
  write(new URL(`src/sn-${s.id.replaceAll("_","-")}-b.js`,dir),`import {palette, ${fn} as paint} from "./${helper}";\nexport const meta=${JSON.stringify({name:s.id+" B directional linger",desc:s.note,tags:["smashnine","stars","directional","one-shot"],size:s.size,origin:s.origin,duration:s.duration,loop:false,fps:s.fps,bg:"dark",options},null,2)};\nmeta.options.palette=palette;\nexport const draw=paint;`);
}
write(new URL("items.json",import.meta.url),JSON.stringify(items,null,2));
console.log(`Prepared ${items.length} candidate B modules.`);
