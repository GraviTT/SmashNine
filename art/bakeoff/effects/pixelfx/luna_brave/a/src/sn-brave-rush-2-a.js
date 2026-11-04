import {drawSharp,palettes} from './sharp09-a.js';
export const meta={
  "name": "SN brave_rush_2 A - sharp moment",
  "size": [
    310,
    450
  ],
  "origin": [
    95,
    185
  ],
  "duration": 0.26666666666666666,
  "loop": false,
  "fps": 30,
  "tags": [
    "smashnine",
    "candidate-a",
    "kick"
  ],
  "options": {
    "kind": "kick",
    "aim": -3,
    "reach": 147,
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
