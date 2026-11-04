import {drawSharp,palettes} from './sharp09-a.js';
export const meta={
  "name": "SN brave_hit_after_big A - sharp moment",
  "size": [
    244,
    96
  ],
  "origin": [
    122,
    30
  ],
  "duration": 0.36666666666666664,
  "loop": false,
  "fps": 30,
  "tags": [
    "smashnine",
    "candidate-a",
    "hit_big"
  ],
  "options": {
    "kind": "hit_big",
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
