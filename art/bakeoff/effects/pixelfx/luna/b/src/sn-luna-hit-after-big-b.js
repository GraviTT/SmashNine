import { palette, drawHit } from "./luna-motion-b.mjs";
export const meta = {
  "name": "luna_hit_after_big B directional linger",
  "desc": "기존 혜성 폭발이 사라진 뒤에도 진행 방향 아래쪽으로 떨어지는 더 큰 별 조각. 중심 섬광은 추가하지 않는다.",
  "tags": [
    "smashnine",
    "candidate-b",
    "hit"
  ],
  "size": [
    216,
    112
  ],
  "origin": [
    96,
    44
  ],
  "duration": 0.8,
  "loop": false,
  "fps": 20,
  "options": {
    "seed": 47,
    "kind": "hit",
    "big": true,
    "duration": 0.8
  }
};
meta.options.palette = palette;
export const draw = drawHit;
