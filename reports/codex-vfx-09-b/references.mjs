import {bench} from "./bench-link.mjs";
import {fileURLToPath} from "node:url";
const {canvas,art,crop,blit,label,savePNG}=bench;
const cv=canvas(1200,1050);
for(const [k,name] of ["luna","luna_brave"].entries()) {
  const sh=art(`assets/art/luna/${name}_sheet.png`);
  label(cv,name,10,k*140+5);
  for(let i=0;i<8;i++)blit(cv,crop(sh,i<2?i*128:(i%6)*128,i<2?0:(1+Math.floor(i/6))*128,128,128),i*140,k*140+12);
}
const moves=art("assets/art/luna/luna_brave_moves_sheet.png");
for(let row=0;row<5;row++) {
  label(cv,["COMBO JAB / KICK / SPIN","UPPER","LOW","FLY","DIVE"][row],8,290+row*138);
  for(let i=0;i<6;i++)blit(cv,crop(moves,i*192+32,row*192+56,128,136),i*170,300+row*138);
}
savePNG(fileURLToPath(new URL("references.png",import.meta.url)),cv);
const fx=canvas(1200,300);label(fx,"CURRENT BRAVE SLASH / HIT",10,10);
for(const [i,p] of ["assets/art/attack_vfx/luna_brave_slash.png","assets/art/effects/hit/luna_brave_hit.png"].entries()) {
  const sh=art(p),n=i?4:6;
  for(let j=0;j<n;j++)blit(fx,bench.stripFrame(sh,n,j),j*195,22+i*140);
}
savePNG(fileURLToPath(new URL("references-fx.png",import.meta.url)),fx);
console.log("reference boards ready");
