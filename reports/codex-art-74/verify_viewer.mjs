import {readFileSync,existsSync} from 'node:fs';
import assert from 'node:assert/strict';
const html=readFileSync('tools/motion_viewer/dist/index.html','utf8');
const prefix='const M = ';const at=html.indexOf(prefix);assert(at>=0);
const end=html.indexOf(';\n',at);const m=JSON.parse(html.slice(at+prefix.length,end));
const ids=['midgard_rooftop_slinger','svartalfheim_gear_beetle','svartalfheim_cog_drone','vanaheim_vine_hound','vanaheim_seed_sprite','jotunheim_rune_golem'];
let count=0;
for(const id of ids){
 const monster=m.monsters.find(x=>x.id===id);assert(monster);
 assert.deepEqual(monster.base.rows.map(x=>x.name),['idle','walk','windup','attack','hurt','defeat']);
 for(const row of monster.base.rows){
  assert.equal(row.candidates.length,1);const c=row.candidates[0];count++;
  assert.equal(c.cell,96);assert.equal(c.feet,72);assert(existsSync(`tools/motion_viewer/dist/${c.file}`));
  assert.equal(c.frames,{idle:6,walk:6,windup:4,attack:6,hurt:2,defeat:4}[row.name]);
  if(['windup','defeat'].includes(row.name)){assert.equal(row.newRow,true);assert.equal(row.start,null);assert.equal(row.loop,false);}
  else assert.equal(row.start,{idle:0,walk:1,attack:2,hurt:3}[row.name]);
  if(row.name==='attack')assert.equal(c.loop,['svartalfheim_gear_beetle','svartalfheim_cog_drone'].includes(id));
 }
}
assert.equal(count,36);assert(html.includes('loop: candidate.loop ?? a.row.loop'));
assert.equal(m.monsters.length,18);
console.log('VIEWER VERIFY: 36 candidates; 12 new rows; original row indices intact; candidate loops; all files present.');
