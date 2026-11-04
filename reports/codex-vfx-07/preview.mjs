// Bench reconstruction, not a game recording: real Frey cells and current slash/hit timing.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { bench } from "../../art/bakeoff/effects/pixelfx/frey/b/bench-link.mjs";
import { upscale } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/tools/lib/fxlib.mjs";
const {canvas,art,crop,blit,drawStrip,stripFrame,realm,label,savePNG}=bench;
const HERE=new URL("./",import.meta.url), ROOT=new URL("../../art/bakeoff/effects/pixelfx/frey/b/",import.meta.url);
const items=JSON.parse(readFileSync(new URL("items.json",ROOT),"utf8"));
const measurements=JSON.parse(readFileSync(new URL("measurements.json",HERE),"utf8")).measurements;
const MOVES=art("assets/art/frey/frey_moves_sheet.png"), MAIN=art("assets/art/frey/frey_sheet.png");
const SLASH=art("assets/art/attack_vfx/frey_slash.png"), HIT=art("assets/art/effects/hit/frey_hit.png");
const cell=i=>({...crop(MAIN,i%6*128,Math.floor(i/6)*128,128,128),root:[64,120]});
const move=(row,col)=>({...crop(MOVES,col*192,row*192,192,192),root:[96,152]});
const body=(cv,c,x,y,flip=false)=>blit(cv,c,x-(flip?c.w-1-c.root[0]:c.root[0]),y-c.root[1],{flip});
function affine(cv,img,pos,offset,sx,sy,rot,mode="add"){
 const c=Math.cos(rot),s=Math.sin(rot);
 const corners=[[0,0],[img.w,0],[0,img.h],[img.w,img.h]].map(([u,v])=>{const x=(u+offset[0])*sx,y=(v+offset[1])*sy;return[pos[0]+x*c-y*s,pos[1]+x*s+y*c];});
 const x0=Math.floor(Math.min(...corners.map(a=>a[0]))),x1=Math.ceil(Math.max(...corners.map(a=>a[0]))),y0=Math.floor(Math.min(...corners.map(a=>a[1]))),y1=Math.ceil(Math.max(...corners.map(a=>a[1])));
 for(let y=Math.max(0,y0);y<Math.min(cv.H,y1);y++)for(let x=Math.max(0,x0);x<Math.min(cv.W,x1);x++){
  const dx=x+0.5-pos[0],dy=y+0.5-pos[1],u=Math.floor((dx*c+dy*s)/sx-offset[0]),v=Math.floor((-dx*s+dy*c)/sy-offset[1]);
  if(u<0||v<0||u>=img.w||v>=img.h)continue;
  const si=(v*img.w+u)*4,a=img.data[si+3]/255,di=(y*cv.W+x)*4;
  for(let k=0;k<3;k++)cv.d[di+k]=mode==="add"?cv.d[di+k]+img.data[si+k]*a:img.data[si+k]*a+cv.d[di+k]*(1-a);
 }
}
function slash(cv,at,age,reach,angle){
 if(age<0||age>=6/36)return;
 const fr=stripFrame(SLASH,6,Math.floor(age*36));
 affine(cv,fr,at,[0,-128],reach/384,reach/384*0.62,angle*Math.PI/180);
}
function spark(cv,at,age,big){
 if(age<0||age>=4/44)return;
 const size=Math.min(56,18+(big?18:8)*1.35+(big?700:235)*0.035)*1.5;
 const fr=stripFrame(HIT,4,Math.floor(age*44));
 affine(cv,fr,at,[-fr.w/2,-fr.h/2],size*2/fr.w,size*2/fr.h,0,"mix");
}
const sample=item=>art(`art/bakeoff/effects/pixelfx/frey/b/frey_${item.id}-b.png`);
function layout(item){
 const m=measurements.find(m=>m.name===`frey_${item.id}-b`),b=m.painted_bounds;
 if(item.kind==="hit")return {w:330,h:190,at:[216,116]};
 const left=Math.min(-90,b[0]-8),right=Math.max(90,b[2]+8),top=Math.min(-100,b[1]-10),bottom=Math.max(48,b[3]+10);
 return {w:Math.ceil(right-left+12),h:Math.ceil(bottom-top+22),at:[6-left,16-top]};
}
function scene(item,age,{withFx=true,dark=false,flip=false,paired=false}={}){
 const L=layout(item),cv=canvas(L.w,L.h),at=L.at,impactAge=age+(item.kind==="hit"?0.075:0);
 realm(cv,dark?"alfheim":"asgard",{sx:700,sy:400,floorY:item.air?null:at[1]+32});
 if(dark)for(let i=0;i<cv.d.length;i+=4)for(let k=0;k<3;k++)cv.d[i+k]*=0.55;
 if(item.kind==="follow"){
  const follow=Math.max(item.recovery/4,1/item.bodyFps),col=age<0?Math.max(0,Math.min(1,Math.floor((age+item.startup)/item.startup*2))):Math.min(5,2+Math.floor((age+0.0005)/follow));
  const end=3*follow+1/item.bodyFps;
  body(cv,age<end?move(item.row,col):cell(item.air?24:Math.floor(age*6.3)%6),at[0],at[1]+32);
  slash(cv,at,age,item.reach,item.aimDeg);
 }else{
  const attacker=[at[0]-150,at[1]],row=item.big?5:8,col=item.big?Math.min(5,2+Math.floor(impactAge*15.75)):Math.min(1,1+Math.floor(impactAge*14.7));
  body(cv,impactAge<0.3?move(row,col):cell(0),attacker[0],attacker[1]+32);
  body(cv,impactAge<0.25?cell(42):cell(0),at[0],at[1]+32,true);
  slash(cv,attacker,impactAge,item.big?240:181,item.big?-10:-3.4);
  spark(cv,at,impactAge,item.big);
 }
 if(withFx&&age>=0&&age<item.frames/20)drawStrip(cv,stripFrame(sample(item),item.frames,Math.floor((age+1e-7)*20)),item.origin,at,{mode:"add"});
 if(flip){const data=new Uint8ClampedArray(cv.d.length);for(let y=0;y<cv.H;y++)for(let x=0;x<cv.W;x++)data.set(cv.d.subarray((y*cv.W+x)*4,(y*cv.W+x)*4+4),(y*cv.W+cv.W-1-x)*4);cv.d=data;}
 label(cv,`${item.id.toUpperCase()}  F${Math.floor(age*20+1.001)}  ${age.toFixed(2)}S`,4,4,[255,234,160]);
 return cv;
}
function into(cv,p,x,y,k=1){blit(cv,{w:p.W*k,h:p.H*k,data:k===1?p.d:upscale(p.d,p.W,p.H,k)},x,y);}
export function previews() {
mkdirSync(new URL("qa/",HERE),{recursive:true});
const quick=process.argv.includes("--quick");
const manifest=[];
for(const item of items){
 const L=layout(item),gap=8;
 const all=canvas(L.w*6+gap*5,L.h*Math.ceil(item.frames/6)+gap*(Math.ceil(item.frames/6)-1));
 for(let n=0;n<item.frames;n++)into(all,scene(item,n/20),n%6*(L.w+gap),Math.floor(n/6)*(L.h+gap));
 savePNG(fileURLToPath(new URL(`qa/${item.id}-1x.png`,HERE)),all);
 // Four consecutive frames per contact page. Pixel-exact 4x, no individual frame dumps.
 for(let start=0;!quick && start<item.frames;start+=4){
  const count=Math.min(4,item.frames-start),cols=2,rows=Math.ceil(count/2),page=canvas(L.w*4*cols+gap,L.h*4*rows+gap*(rows-1));
  for(let j=0;j<count;j++)into(page,scene(item,(start+j)/20),j%cols*(L.w*4+gap),Math.floor(j/cols)*(L.h*4+gap),4);
  const name=`qa/${item.id}-4x-${String(start+1).padStart(2,"0")}.png`;
  savePNG(fileURLToPath(new URL(name,HERE)),page);manifest.push({file:name,frames:[start+1,start+count],scale:4,size:[page.W,page.H]});
 }
}
if(quick){console.log("Quick 1x contacts written.");} else {
// Seven rows, key timings in 1x and one 4x detail. Actual game slash and hit spark remain underneath B.
const rows=items.map(item=>{
 const L=layout(item),times=[0,0.10,0.25,item.kind==="follow"?0.55:Math.min(0.35,(item.frames-1)/20)];
 const row=canvas(2220,Math.max(L.h*2+36,L.h*4+24));
 label(row,`FREY / ${item.id.toUpperCase()} / B / 20 FPS`,8,8);
 for(let j=0;j<4;j++)into(row,scene(item,times[j]),8+j%2*(L.w+8),24+Math.floor(j/2)*(L.h+8));
 const detail=scene(item,item.kind==="follow"?0.20:0.10);
 into(row,detail,L.w*2+36,24,4);
 label(row,"1X KEY FRAMES",8,16);label(row,"4X DETAIL",L.w*2+36,16);
 return row;
});
const board=canvas(2220,rows.reduce((s,r)=>s+r.H+12,40));
label(board,"CODEX-VFX-07 / FREY CANDIDATE B / BENCH RECONSTRUCTION - NOT GAME CAPTURE",8,8);
label(board,"REAL CELLS + CURRENT SLASH / HIT SPARK. EFFECT AGE IN SECONDS. 1 ART PX = 1 WORLD PX.",8,20);
let y=40;for(const row of rows){into(board,row,0,y);y+=row.H+12;}
savePNG(fileURLToPath(new URL("board.png",HERE)),board);
writeFileSync(new URL("qa/manifest.json",HERE),JSON.stringify(manifest,null,2)+"\n");
console.log(`Previewed ${items.reduce((s,i)=>s+i.frames,0)} frames at 1x/4x in ${manifest.length} contact pages; board ${board.W}x${board.H}`);
}
}
if(process.argv[1]===fileURLToPath(import.meta.url))previews();
export {scene,items,into,layout,ROOT,HERE};
