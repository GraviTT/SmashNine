import { fileURLToPath } from "node:url";
import { bench } from "../../art/bakeoff/effects/pixelfx/frey/b/bench-link.mjs";
const { canvas, art, crop, blit, label, savePNG, stripFrame } = bench;
const cv = canvas(768, 788);
const moves = art("assets/art/frey/frey_moves_sheet.png");
const slash = art("assets/art/attack_vfx/frey_slash.png");
console.log({moves:[moves.w,moves.h],slash:[slash.w,slash.h]});
for (let i=0;i<6;i++) {
  const f=stripFrame(slash,6,i);
  blit(cv,f,i%2*384,Math.floor(i/2)*260);
  label(cv,`SLASH ${i+1}`,i%2*384+4,Math.floor(i/2)*260+4);
}
savePNG(fileURLToPath(new URL("reference.png",import.meta.url)),cv);
