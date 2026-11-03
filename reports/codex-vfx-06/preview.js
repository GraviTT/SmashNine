'use strict';
const $ = id => document.getElementById(id);
let elapsed = 0, lastTime = null, playing = true, loaded = false;
const images = {}, roots = DATA.roots;

function geometry(time, mode) {
  if (mode === 'head') return {kind: 'head', frame: Math.floor(time*16)%4, foe: 380, head: 230};
  if (mode === 'bind') return {kind: 'bind', frame: Math.floor(time*12)%4, foe: 380};
  if (mode === 'split') return {kind: 'split', frame: Math.floor(time*40)%4, foe: 380};
  if (mode === 'arrived') return {kind: 'bind', frame: Math.floor(time*12)%4, foe: 149};
  const t = time % 1.6;
  if (t < .16) return {kind: 'head', frame: Math.floor(t*16)%4, foe: 380, head: 104+276*t/.16};
  if (t < .26) return {kind: 'split', frame: Math.min(3, Math.floor((t-.16)*40)), foe: 380};
  if (t < .71) return {kind: 'bind', frame: Math.floor((t-.26)*12)%4, foe: Math.round(380-231*(t-.26)/.45)};
  if (t < 1.02) return {kind: 'bind', frame: Math.floor((t-.26)*12)%4, foe: 149};
  return {kind: 'rest', frame: 0, foe: 380};
}

function draw(variant, state) {
  const ctx = $('canvas-'+variant).getContext('2d');
  ctx.imageSmoothingEnabled = false;
  ctx.globalCompositeOperation = 'source-over';
  ctx.drawImage(images.background, 0, 0);
  ctx.drawImage(images.nova, 16, 43);
  ctx.drawImage(images.frey, state.foe-64, 43);
  if (state.kind !== 'rest') {
    ctx.globalCompositeOperation = 'lighter';
    const isHead = state.kind === 'head';
    const w = isHead ? 48 : 160;
    const x = isHead ? state.head : state.foe;
    const root = isHead ? x-17 : x-80+roots[variant][state.kind][state.frame]+3;
    for (let from = 104; from < root; from += 64) {
      const width = Math.min(64, root-from);
      ctx.drawImage(images[variant+'-tile'], 0, 0, width, 16, from, 123, width, 16);
    }
    ctx.drawImage(images[variant+'-'+state.kind], state.frame*w, 0, w, w, Math.round(x-w/2), 131-w/2, w, w);
    ctx.globalCompositeOperation = 'source-over';
    if ($('guides').checked && !isHead) {
      ctx.strokeStyle = '#eda066';
      ctx.strokeRect(state.foe-25+.5, 91+.5, 49, 79);
    }
  }
  ctx.fillStyle = '#e1eaf9';
  ctx.font = '13px sans-serif';
  const names = {head:'비행', split:'분리', bind:'결박', rest:'다음 시전 대기'};
  ctx.fillText(variant.toUpperCase()+' · '+names[state.kind]+' · F'+(state.frame+1)+' · 거리 '+(state.foe-80)+'px', 10, 21);
}

function render() {
  if (!loaded) return;
  const state = geometry(elapsed, $('mode').value);
  for (const v of ['a', 'b']) draw(v, state);
  $('readout').textContent = '재생 '+elapsed.toFixed(3)+'s · '+(playing?'재생 중':'정지')+' · '+$('speed').value+'배속';
}

function tick(now) {
  if (lastTime !== null && playing) elapsed += Math.min(.1, (now-lastTime)/1000)*Number($('speed').value);
  lastTime = now;
  render();
  requestAnimationFrame(tick);
}

$('play').onclick = () => { playing = !playing; $('play').textContent = playing?'일시정지':'재생'; render(); };
$('reset').onclick = () => { elapsed=0; render(); };
$('step').onclick = () => {
  playing=false; $('play').textContent='재생';
  const fps = $('mode').value==='head'?16:$('mode').value==='split'?40:12;
  elapsed += 1/fps; render();
};
$('mode').onchange = () => { elapsed=0; render(); };
$('zoom').onchange = () => {
  const z=Number($('zoom').value);
  document.querySelectorAll('canvas').forEach(c => {c.style.width=(480*z)+'px'; c.style.height=(224*z)+'px';});
};
$('guides').onchange = render;
Promise.all(Object.entries(DATA.images).map(([name, url]) => new Promise((resolve, reject) => {
  const im = new Image(); im.onload = () => {images[name]=im; resolve();}; im.onerror=reject; im.src=url;
}))).then(() => {loaded=true; requestAnimationFrame(tick);}).catch(() => {$('readout').textContent='이미지 읽기 실패';});
