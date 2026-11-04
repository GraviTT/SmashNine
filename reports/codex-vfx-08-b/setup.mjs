import { mkdirSync, writeFileSync } from "node:fs";
const repo=new URL("../../",import.meta.url);
export const specs=[
  {id:"frey_jump",family:"frey",kind:"jump",duration:.6,size:[160,64],origin:[80,24],blend:"mix",note:"도약 지점 아래와 바깥으로 눌려 나가는 금빛 먼지와 흰 깃털.",attach:"Frey 지상 점프가 시작되는 순간 발 위치에 한 번. 생성 위치에 남기고 오른쪽 기준 좌우 반전만 한다."},
  {id:"frey_air_jump",family:"frey",kind:"air",duration:.7,size:[160,72],origin:[80,20],blend:"add",note:"공중 두 번째 발차기 아래로 벌어지는 흰 깃털 여덟 개와 금빛 알갱이.",attach:"Frey _perform_air_jump의 실제 공중 점프 순간 발 위치에 한 번. 날개 정지·돌진과 구분. 생성 위치에 남는다."},
  {id:"frey_land",family:"frey",kind:"land",duration:.55,size:[160,64],origin:[80,45],blend:"mix",note:"낮은 착지에서 바닥을 따라 양쪽으로 미끄러지는 작은 먼지와 깃털.",attach:"Frey 낙하 높이 130px 미만 착지 순간 바닥의 발 위치에 한 번. 생성 위치에 남는다."},
  {id:"frey_land_big",family:"frey",kind:"land",big:true,duration:.8,size:[216,80],origin:[108,57],blend:"mix",note:"큰 착지에서 넓게 굴러 나가는 황금 먼지와 깃털. 작은 착지보다 넓고 오래 남는다.",attach:"Frey 낙하 높이 130px 이상 착지 순간 바닥의 발 위치에 한 번. 생성 위치에 남는다."},
  {id:"luna_star_launch",family:"luna",kind:"launch",duration:.45,size:[112,64],origin:[28,18],blend:"add",note:"작은 별이 발사된 자리 아래쪽에서 분홍·금 별가루가 전방으로 밀려 나간다. 회전해도 발사자의 얼굴을 피한다.",attach:"Luna _fire_star의 실제 작은 별 생성 위치에 한 번. +x를 발사 방향(0도, 위·아래 60도)에 맞춰 회전. 생성 위치에 남는다."},
  {id:"luna_star_launch_big",family:"luna",kind:"launch",big:true,duration:.6,size:[136,88],origin:[32,28],blend:"add",note:"네 번째 큰 별 아래에서 더 넓은 별가루가 발사 방향으로 흐른다. 회전해도 발사자의 얼굴을 피한다.",attach:"Luna _fire_star의 네 번째 큰 별 생성 위치에 한 번. +x를 발사 방향에 맞춰 회전. 생성 위치에 남는다."},
  {id:"luna_star_trail",family:"luna",kind:"trail",duration:.5,size:[144,52],origin:[130,26],blend:"add",loop:true,note:"작은 별 뒤에서 서로 떨어진 분홍·금 빛줄기와 작은 별들이 뒤로 흐르는 반복 꼬리.",attach:"작은 LunaStar의 중심에 붙여 비행 중에만 반복. +x를 비행 방향으로 회전하고 -x에 꼬리. 별 제거 시 즉시 제거. 속도 1050px/s, 수명 0.3초."},
  {id:"luna_star_trail_big",family:"luna",kind:"trail",big:true,duration:.6,size:[192,60],origin:[174,30],blend:"add",loop:true,note:"큰 별의 중심을 비워 둔 채 더 길게 흐르는 분홍·금빛 별가루 꼬리.",attach:"큰 LunaStar의 중심에 붙여 비행 중에만 반복. +x를 비행 방향으로 회전하고 -x에 꼬리. 별 제거 시 즉시 제거. 속도 930px/s, 수명 0.36초."},
  {id:"luna_hit_after",family:"luna",kind:"hit",duration:.6,size:[176,100],origin:[76,40],blend:"add",note:"기존 적중 불꽃 옆에서 별 조각이 탄의 진행 방향으로 떠밀려 내려오는 여운. 몸 가운데는 비운다.",attach:"작은 별의 실제 적중 한 번당 한 번, 기존 적중 불꽃이 생기는 맞은 몸 중심. 방어·패리·빗나감 제외. +x가 발사 방향이며 좌우 반전. 생성 위치에 남는다."},
  {id:"luna_hit_after_big",family:"luna",kind:"hit",big:true,duration:.8,size:[216,112],origin:[96,44],blend:"add",note:"기존 혜성 폭발이 사라진 뒤에도 진행 방향 아래쪽으로 떨어지는 더 큰 별 조각. 중심 섬광은 추가하지 않는다.",attach:"큰 별의 실제 적중당 한 번, 맞은 몸 중심. luna_comet_burst와 함께 검사한 여운. 직접 적중과 폭발에서 중복 생성하지 않는다. 방어·패리·빗나감 제외. +x가 발사 방향이며 좌우 반전."},
];
for(const s of specs) {
  const root=new URL(`art/bakeoff/effects/pixelfx/${s.family}/b/`,repo);
  mkdirSync(new URL("src/",root),{recursive:true});
  const name=`sn-${s.id.replaceAll("_","-")}-b.js`;
  const draw=s.family==="frey"?"drawMotion":s.kind==="launch"?"drawLaunch":s.kind==="trail"?"drawTrail":"drawHit";
  const meta={name:s.id+" B directional linger",desc:s.note,tags:["smashnine","candidate-b",s.kind],size:s.size,origin:s.origin,duration:s.duration,loop:!!s.loop,fps:20,options:{seed:47,kind:s.kind,big:!!s.big,duration:s.duration}};
  writeFileSync(new URL(`src/${name}`,root),`import { palette, ${draw} } from "./${s.family}-motion-b.mjs";\nexport const meta = ${JSON.stringify(meta,null,2)};\nmeta.options.palette = palette;\nexport const draw = ${draw};\n`,"utf8");
}
writeFileSync(new URL("items.json",import.meta.url),JSON.stringify(specs,null,2)+"\n","utf8");
