// Generates only CODEX-VFX-08 A wrappers. Existing pilot A assets remain intact.
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
const repo = fileURLToPath(new URL('../../', import.meta.url));
export const specs = [
  ['frey_jump', 8, 24, 124, 32, [62, 9], 'jump', false, '지면에서 도약하는 순간 발밑에 강철 섬광과 짧은 금빛 깃털이 벌어진다.', '지상 점프 시작 시 발 위치에 한 번 생성하고 그 자리에 남긴다.'],
  ['frey_air_jump', 10, 30, 138, 38, [68, 9], 'air', false, '공중 재도약 순간 아래로 부채꼴 깃털 셋씩이 짧게 펼쳐진다.', '공중 점프 시작 시 발 위치에 한 번 생성하고 그 자리에 남긴다.'],
  ['frey_land', 8, 30, 124, 28, [62, 22], 'land', false, '가벼운 착지에 낮고 짧은 금빛 접촉선과 쇳불꽃이 양옆으로 튄다.', '낙하 높이 130px 미만 착지 시 바닥의 발 위치에 한 번 생성한다.'],
  ['frey_land_big', 12, 30, 178, 42, [89, 34], 'land_big', false, '높은 낙하 착지에 넓은 강철 광선과 깃털 파편이 빠르게 흩어진다.', '낙하 높이 130px 이상 착지 시 바닥의 발 위치에 한 번 생성한다.'],
  ['luna_star_launch', 6, 30, 30, 52, [1, 26], 'launch', false, '작은 별이 나가는 순간 분홍 별빛과 흰 예각 섬광이 전방으로 터진다.', '작은 J 별 생성 좌표에 한 번 생성. +x를 조준 방향(수평 또는 ±60도)으로 회전한다.'],
  ['luna_star_launch_big', 7, 30, 44, 78, [1, 39], 'launch_big', false, '네 번째 큰 별의 금색 갈래 섬광이 더 넓고 짧게 터진다.', '큰 J 별 생성 좌표에 한 번 생성. +x를 조준 방향으로 회전한다.'],
  ['luna_star_trail', 8, 40, 72, 28, [90, 14], 'trail', true, '작은 별 뒤에 짧은 분홍 광선과 작은 별 셋이 끊어져 흐른다.', '작은 별 중심에 부착해 생존 중 반복. +x는 비행 방향, 꼬리는 -x. 1050px/s, 0.30초.'],
  ['luna_star_trail_big', 10, 40, 96, 40, [128, 20], 'trail_big', true, '큰 별 뒤의 금빛 별 네 개와 분홍 쐐기 잔광이 짧게 이어진다.', '큰 별 중심에 부착해 생존 중 반복. +x는 비행 방향, 꼬리는 -x. 930px/s, 0.36초.'],
  ['luna_hit_after', 9, 30, 120, 42, [60, 19], 'hit', false, '적중점 중앙을 비우고 몸 양옆에 별 네 개가 찰나에 갈라져 사라진다.', '작은 별 적중 시 맞은 몸 중심에서 한 번. 기존 적중 불꽃과 동시 시작, +x는 입사 방향.'],
  ['luna_hit_after_big', 11, 30, 162, 60, [81, 21], 'hit_big', false, '기존 혜성 폭발 바깥쪽 아래에 금색 별 갈래가 남았다가 빠르게 꺼진다.', '큰 별 적중 시 맞은 몸 중심에서 한 번. 기존 luna_comet_burst와 함께 시작, 중복 생성 금지.'],
].map(([name,frames,fps,w,h,anchor,kind,loop,note,attach]) => ({name,frames,fps,w,h,anchor,kind,loop,note,attach,char:name.split('_')[0]}));

export function writeModules() {
for (const s of specs) {
  const dir = resolve(repo, `art/bakeoff/effects/pixelfx/${s.char}/a`);
  mkdirSync(`${dir}/src`, {recursive:true});
  const source = `art/bakeoff/effects/pixelfx/${s.char}/a/src/sn-${s.name.replaceAll('_','-')}-a.js`;
  const code = `import { drawEffect, palettes } from './sharp-a.js';\nexport const meta = ${JSON.stringify({name:`SN ${s.name} A - sharp moment`,size:[s.w,s.h],origin:s.anchor,duration:s.frames/s.fps,fps:s.fps,loop:s.loop,tags:['smashnine','candidate-a',s.kind],options:{kind:s.kind,seed:8}},null,2)};\nmeta.options.palette = palettes.main;\nmeta.options.gold = palettes.gold;\nexport const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);\n`;
  writeFileSync(resolve(repo,source),code,'utf8');
}
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))writeModules();
