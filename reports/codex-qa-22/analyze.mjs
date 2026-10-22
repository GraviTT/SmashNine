import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
const dir = path.dirname(new URL(import.meta.url).pathname.replace(/^\/(?:([A-Za-z]:))/, '$1'));
const read = name => JSON.parse(fs.readFileSync(path.join(dir, name), 'utf8').replace(/^\uFEFF/, ''));
const sum = obj => Object.values(obj).reduce((a,b)=>a+b,0);
const inc = (obj,key,n=1) => obj[key]=(obj[key]??0)+n;
const sorted = obj => Object.entries(obj).sort((a,b)=>b[1]-a[1] || a[0].localeCompare(b[0]));
function rolling(events, seconds) {
  const rows = [...events].sort((a,b)=>a.t-b.t);
  let right=0, best={count:0,start:0,end:seconds,ids:{}};
  for(let left=0;left<rows.length;left++) {
    right=Math.max(left,right);
    while(right<rows.length && rows[right].t<rows[left].t+seconds-1e-8) right++;
    if(right-left>best.count) {
      const ids={}; for(let i=left;i<right;i++) inc(ids,rows[i].id);
      best={count:right-left,start:rows[left].t,end:rows[left].t+seconds,ids};
    }
  }
  return best;
}
const summaries=[];
const captures=[...new Set(fs.readdirSync(dir).filter(n=>/^sound-(br|story)-\d+(\.json|-events\.json\.gz)$/.test(n)).map(n=>n.replace('-events.json.gz','.json')))].sort();
for(const file of captures) {
  const rawPath=path.join(dir,file), gzipPath=path.join(dir,file.replace('.json','-events.json.gz'));
  const raw=fs.existsSync(rawPath)?fs.readFileSync(rawPath):zlib.gunzipSync(fs.readFileSync(gzipPath));
  const data=JSON.parse(raw), byId={}, buckets={}, frames={}, outcomes={}, allEligible=[];
  for(const [id,cat] of Object.entries(data.catalog)) byId[id]={group:cat.group,raw:0,watched:0,filtered:0,global:0,disabled:0,music:0,no_realm:0,peak_per_second:0,peak_same_frame:0};
  for(const e of data.events) {
    inc(outcomes,e.outcome);
    const id=byId[e.id]; id.raw++; inc(id,e.outcome);
    if(['watched','global','no_realm'].includes(e.outcome)) allEligible.push(e);
    if(e.outcome!=='watched') continue;
    const second=Math.floor(e.t+1e-7);
    buckets[second]??={}; inc(buckets[second],e.id);
    frames[e.frame]??={t:e.t,ids:{}}; inc(frames[e.frame].ids,e.id);
  }
  for(const [sec,ids] of Object.entries(buckets)) for(const [id,n] of Object.entries(ids)) {
    if(n>byId[id].peak_per_second) { byId[id].peak_per_second=n; byId[id].peak_second=Number(sec); }
  }
  for(const [frame,row] of Object.entries(frames)) for(const [id,n] of Object.entries(row.ids)) {
    if(n>byId[id].peak_same_frame) { byId[id].peak_same_frame=n; byId[id].peak_frame=Number(frame); byId[id].peak_frame_time=row.t; }
  }
  const watched=data.events.filter(e=>e.outcome==='watched');
  const alerts=[];
  for(const [id,row] of Object.entries(byId)) {
    const r=rolling(watched.filter(e=>e.id===id),1);
    row.peak_rolling_second=r.count; row.peak_rolling_start=r.start;
    const eligible=allEligible.filter(e=>e.id===id), bins={}, batches={};
    for(const e of eligible) { inc(bins,Math.floor(e.t+1e-7)); batches[e.frame]??={t:e.t,n:0}; batches[e.frame].n++; }
    const maxBin=sorted(bins)[0]??[0,0], maxBatch=Object.entries(batches).sort((a,b)=>b[1].n-a[1].n)[0];
    const allRolling=rolling(eligible,1);
    row.candidate_peak_per_second=maxBin[1]; row.candidate_peak_rolling_second=allRolling.count; row.candidate_peak_same_frame=maxBatch?.[1].n??0;
    if(allRolling.count>8 || row.candidate_peak_same_frame>3) alerts.push({id,scope:data.catalog[id].world?'watched':'global',aligned_peak:maxBin[1],second:Number(maxBin[0]),rolling_peak:allRolling,same_frame_peak:row.candidate_peak_same_frame,frame:maxBatch?Number(maxBatch[0]):0,t:maxBatch?.[1].t??0});
  }
  const framePeak=Object.entries(frames).sort((a,b)=>sum(b[1].ids)-sum(a[1].ids))[0];
  const seconds=Array.from({length:Math.floor(data.stats.seconds_simulated)+1},(_,t)=>({second:t,watched:sum(buckets[t]??{}),ids:buckets[t]??{}}));
  const validation={events_match_probe:data.events.length===sum(data.requests),raw_ids_match:Object.entries(byId).every(([id,r])=>r.raw===(data.requests[id]??0)),world_match:['watched','filtered','no_realm'].every(k=>(outcomes[k]??0)===data.world_probe[k]),actual_plays:data.events.filter(e=>e.played).length,no_realm:data.world_probe.no_realm,unclassified:outcomes.unclassified??0};
  if(!validation.events_match_probe || !validation.raw_ids_match || !validation.world_match || validation.unclassified) throw Error(`${file}: recorder inconsistency`);
  const summary={file,stats:data.stats,world_probe:data.world_probe,outcomes,validation,top:sorted(Object.fromEntries(Object.entries(byId).map(([id,r])=>[id,r.watched]))).filter(r=>r[1]>0).slice(0,10),busiest_five_seconds:rolling(watched,5),busiest_one_second:rolling(watched,1),peak_same_frame:framePeak?{frame:Number(framePeak[0]),...framePeak[1],total:sum(framePeak[1].ids)}:null,alerts,never_requested:Object.keys(byId).filter(id=>byId[id].raw===0),never_watched_world:Object.keys(byId).filter(id=>data.catalog[id].world && byId[id].watched===0),by_id:byId,seconds,checkpoints:data.checkpoints};
  summaries.push(summary);
  const zipped=zlib.gzipSync(raw);
  if(!zlib.gunzipSync(zipped).equals(raw)) throw Error('Gzip roundtrip failed: '+file);
  fs.writeFileSync(gzipPath,zipped);
  if(process.argv.includes('--compact') && fs.existsSync(rawPath)) fs.unlinkSync(rawPath);
}
fs.writeFileSync(path.join(dir,'sound-summary.json'),JSON.stringify(summaries,null,2)+'\n');
let md='| 실행 | 경기 시간 | 관찰 렐름 | 다른 렐름 차단 | 전역 SFX | 비활성 | no_realm | 최다 5초 | 한 프레임 최대 요청 |\n|---|---:|---:|---:|---:|---:|---:|---|---|\n';
for(const s of summaries) {
 const b=s.busiest_five_seconds, p=s.peak_same_frame;
 md+=`| ${s.file.replace('sound-','').replace('.json','')} | ${s.stats.seconds_simulated.toFixed(3)}s | ${s.outcomes.watched??0} | ${s.outcomes.filtered??0} | ${s.outcomes.global??0} | ${s.outcomes.disabled??0} | ${s.world_probe.no_realm} | ${b.start.toFixed(3)}–${b.end.toFixed(3)}s: ${b.count} | ${p?`${p.total} (${p.t.toFixed(3)}s)`:'0'} |\n`;
}
md+='\n## ID별 전체 측정\n\n관찰 렐름 요청은 재생 후보이며 음원 없음·40ms 간격·동시 voice 제한 이전이다. 피크는 경기 시간 기준이며 실제 voice 수가 아니다.\n';
for(const s of summaries) {
 md+=`\n### ${s.file}\n\n| ID | 원요청 | 관찰 | 타렐름 차단 | 전역 | 비활성 | 음악 | 최대/정수초 | 최대/이동1초 | 최대/동일프레임 |\n|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n`;
 for(const [id,r] of Object.entries(s.by_id)) md+=`| ${id} | ${r.raw} | ${r.watched} | ${r.filtered} | ${r.global} | ${r.disabled} | ${r.music} | ${r.peak_per_second} | ${r.peak_rolling_second} | ${r.peak_same_frame} |\n`;
 md+=`\n직접 미발동: ${s.never_requested.map(id=>'`'+id+'`').join(', ')}.\n`;
}
fs.writeFileSync(path.join(dir,'sound-tables.md'),md);
let neverMd='# 미발동 원인 분류\n\n원요청 0은 필터 차단과 구분했다. 연결이 있는 ID는 이 표본에서 조건 이벤트가 없었다는 뜻이며, 모든 실행에서 도달 불가능하다는 판정이 아니다.\n';
const fallback=new Set(['swing','skill_cast','ult_start','monster_attack']);
function reason(id,s) {
 if(fallback.has(id)) return '직접 훅 없음: 폴백 조회 전용(정상 계약). resolution_attempts는 원캡처에 별도 보존.';
 if(['story_text','story_advance'].includes(id)) return '도달할 직접 훅 없음: 예약 ID, StoryDialogue 미연결. 스토리는 해당 대화/진행 이벤트도 실제 통과.';
 if(s.file.includes('-story-') && ['results','victory','music_results','portal'].includes(id)) return '스토리 전용 결과/엔딩·Q 출구 경로는 BR 훅을 거치지 않음. StoryScreens/StorySession 미연결(계약 명시).';
 if(id.startsWith('ui_')) return '공통 메뉴의 해당 탐색/활성화/취소를 이 드라이버에서 조작하지 않음. 대화 skip은 StoryDialogue 소유.';
 if(id.startsWith('music_')) return '해당 음악을 요청하는 화면 경로 미방문. 별도 music-screens.json에서 BR 화면 경로 검사.';
 if(id==='card_offer' && s.file.includes('-br-')) return '8봇 관전: 사람 카드 패널이 나타나는 조건 없음. 봇 카드 적용 요청은 enabled=false로 별도 기록.';
 if(id==='hit_heavy') return '일반 비가드 적중을 hit_heavy로 분류하는 분기(최종 피해 >=10, hit_launch 우선 제외)가 이 표본에서 요청되지 않음.';
 if(id==='elite_appear' && s.file.includes('-story-')) return '이번 1/5/9장에는 BR 정예 스폰 경로 없음. 스토리 직접 정예 스폰 훅도 계약상 미연결이나 이 표본으로 정예 등장 사건을 검증하지 않음.';
 if(id.startsWith('monster_')) return '이 ID에 대응하는 몬스터 행동/타격/사망 이벤트 요청이 이 실행에서 발생하지 않음. 훅 도달은 SYS-05 기능 검사와 별개.';
 if(id.startsWith('skill_') || id.startsWith('ult_')) return '해당 캐릭터/변신 상태의 기술 성공 이벤트가 이 실행에서 발생하지 않음. 스토리는 강제 진행 fixture라 사람 기술 입력 없음.';
 if(['soul_pickup','card_pick','card_offer'].includes(id)) return '이 실행에서 해당 사람 성장/선택 이벤트 조건이 발생하지 않음.';
 return '이 ID를 요청하는 전투/이동/기믹 조건 이벤트가 이 실행에서 발생하지 않음. 미연결 또는 불가능으로 단정하지 않음.';
}
for(const s of summaries) {
 neverMd+=`\n## ${s.file}\n\n| 직접 요청 0 ID | 원인·범위 |\n|---|---|\n`;
 for(const id of s.never_requested) neverMd+=`| ${id} | ${reason(id,s)} |\n`;
 const filtered=s.never_watched_world.filter(id=>s.by_id[id].raw>0);
 neverMd+='\n| 월드 원요청은 있으나 관찰 재생 후보 0 | 원요청 | 다른 렐름 차단 |\n|---|---:|---:|\n';
 for(const id of filtered) neverMd+=`| ${id} | ${s.by_id[id].raw} | ${s.by_id[id].filtered} |\n`;
}
fs.writeFileSync(path.join(dir,'never-fired.md'),neverMd);
const plotted=summaries.find(s=>s.stats.seed===1001 && s.file.includes('-br-'));
if(plotted) {
 const W=1100,H=420,L=65,R=25,T=65,B=55, vals=plotted.seconds, xmax=vals.length, ymax=Math.ceil(Math.max(...vals.map(r=>r.watched))/5)*5;
 const x=t=>L+t/xmax*(W-L-R),y=n=>H-B-n/ymax*(H-T-B);
 let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"><rect width="100%" height="100%" fill="#111827"/><g font-family="Arial,sans-serif" fill="#e5e7eb"><text x="${L}" y="28" font-size="21">QA-22 | 8 bots, seed 1001 | watched-realm requests / match second</text><text x="${L}" y="49" font-size="13" fill="#9ca3af">Measured request demand before missing assets, 40 ms gap and voice caps. Actual audio plays: 0.</text>`;
 for(let n=0;n<=ymax;n+=5) svg+=`<path d="M${L} ${y(n)}H${W-R}" stroke="#374151"/><text x="${L-10}" y="${y(n)+4}" text-anchor="end" font-size="12">${n}</text>`;
 for(let t=0;t<=xmax;t+=30) svg+=`<text x="${x(t)}" y="${H-B+24}" text-anchor="middle" font-size="12">${t}s</text>`;
 svg+=`<path d="${vals.map((r,i)=>(i?'L':'M')+x(r.second).toFixed(2)+' '+y(r.watched).toFixed(2)).join(' ')}" stroke="#38bdf8" stroke-width="1.5" fill="none"/><text x="${L}" y="${H-12}" font-size="12">Aligned bins [s, s+1); zero-request seconds included. Source: sound-summary.json.</text></g></svg>`;
 fs.writeFileSync(path.join(dir,'sound-requests.svg'),svg);
}
console.log(JSON.stringify(summaries.map(s=>({file:s.file,stats:s.stats,outcomes:s.outcomes,top:s.top,alerts:s.alerts,validation:s.validation})),null,2));
