import {palette, draw as paint} from "./luna-feet-b.mjs";
export const meta={
  "name": "luna_step B directional linger",
  "desc": "앞발 뒤로 분홍 먼지와 금빛 별가루가 낮게 흐른다. 한 걸음 0.35초에 끝난다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    100,
    48
  ],
  "origin": [
    78,
    34
  ],
  "duration": 0.35,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "step",
    "duration": 0.35,
    "seed": 909
  }
};
meta.options.palette=palette;
export const draw=paint;
