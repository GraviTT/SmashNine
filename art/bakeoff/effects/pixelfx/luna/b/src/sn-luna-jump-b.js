import {palette, draw as paint} from "./luna-feet-b.mjs";
export const meta={
  "name": "luna_jump B directional linger",
  "desc": "도약 자리에서 별가루가 양옆으로 밀려나며 뒤쪽에 더 오래 남는다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    180,
    70
  ],
  "origin": [
    90,
    48
  ],
  "duration": 0.6,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "jump",
    "duration": 0.6,
    "seed": 946
  }
};
meta.options.palette=palette;
export const draw=paint;
