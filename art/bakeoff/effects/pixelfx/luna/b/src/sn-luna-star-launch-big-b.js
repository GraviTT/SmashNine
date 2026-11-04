import { palette, drawLaunch } from "./luna-motion-b.mjs";
export const meta = {
  "name": "luna_star_launch_big B directional linger",
  "desc": "네 번째 큰 별 아래에서 더 넓은 별가루가 발사 방향으로 흐른다. 회전해도 발사자의 얼굴을 피한다.",
  "tags": [
    "smashnine",
    "candidate-b",
    "launch"
  ],
  "size": [
    136,
    88
  ],
  "origin": [
    32,
    28
  ],
  "duration": 0.6,
  "loop": false,
  "fps": 20,
  "options": {
    "seed": 47,
    "kind": "launch",
    "big": true,
    "duration": 0.6
  }
};
meta.options.palette = palette;
export const draw = drawLaunch;
