import {palette, draw as paint} from "./luna-feet-b.mjs";
export const meta={
  "name": "luna_air_jump B directional linger",
  "desc": "공중 발밑에서 열린 두 갈래 별빛과 별조각이 아래·바깥으로 흐른다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    190,
    110
  ],
  "origin": [
    95,
    25
  ],
  "duration": 0.7,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "air",
    "duration": 0.7,
    "seed": 983
  }
};
meta.options.palette=palette;
export const draw=paint;
