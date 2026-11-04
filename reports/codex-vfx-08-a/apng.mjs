// Minimal APNG encoder, no install or external encoder. Frames are supplied in memory.
import { encodePNG } from 'file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/tools/lib/png.mjs';
const table=Uint32Array.from({length:256},(_,i)=>{let c=i;for(let k=0;k<8;k++)c=(c&1)?0xedb88320^(c>>>1):c>>>1;return c>>>0;});
function crc(b){let c=0xffffffff;for(const v of b)c=table[(c^v)&255]^(c>>>8);return(c^0xffffffff)>>>0;}
function chunk(type,data){const name=Buffer.from(type),body=Buffer.concat([name,data]),n=Buffer.alloc(4),tail=Buffer.alloc(4);n.writeUInt32BE(data.length);tail.writeUInt32BE(crc(body));return Buffer.concat([n,body,tail]);}
function chunks(png){const a=[];for(let p=8;p<png.length;){const len=png.readUInt32BE(p);a.push([png.toString('ascii',p+4,p+8),png.subarray(p+8,p+8+len)]);p+=len+12;}return a;}
export function encodeAPNG(w,h,frames,fps) {
  const header=Buffer.alloc(13);header.writeUInt32BE(w);header.writeUInt32BE(h,4);header[8]=8;header[9]=6;
  const actl=Buffer.alloc(8);actl.writeUInt32BE(frames.length);let seq=0;
  const parts=[Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('acTL',actl)];
  for(let i=0;i<frames.length;i++) {
    const control=Buffer.alloc(26);control.writeUInt32BE(seq++);control.writeUInt32BE(w,4);control.writeUInt32BE(h,8);control.writeUInt16BE(1,20);control.writeUInt16BE(fps,22);
    parts.push(chunk('fcTL',control));
    const data=Buffer.concat(chunks(encodePNG(w,h,frames[i])).filter(([n])=>n==='IDAT').map(([,b])=>b));
    if(i===0)parts.push(chunk('IDAT',data));
    else {const n=Buffer.alloc(4);n.writeUInt32BE(seq++);parts.push(chunk('fdAT',Buffer.concat([n,data])));}
  }
  parts.push(chunk('IEND',Buffer.alloc(0)));return Buffer.concat(parts);
}
