import {drawSharp,palettes} from './sharp09-a.js';
export const meta={
  "name": "SN brave_down_air A - sharp moment",
  "size": [
    310,
    450
  ],
  "origin": [
    95,
    185
  ],
  "duration": 0.36666666666666664,
  "loop": false,
  "fps": 30,
  "tags": [
    "smashnine",
    "candidate-a",
    "dive"
  ],
  "options": {
    "kind": "dive",
    "aim": 81,
    "reach": 206,
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
