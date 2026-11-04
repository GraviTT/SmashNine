import {drawSharp,palettes} from './sharp09-a.js';
export const meta={
  "name": "SN brave_hit_after A - sharp moment",
  "size": [
    166,
    72
  ],
  "origin": [
    83,
    28
  ],
  "duration": 0.3,
  "loop": false,
  "fps": 30,
  "tags": [
    "smashnine",
    "candidate-a",
    "hit"
  ],
  "options": {
    "kind": "hit",
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
