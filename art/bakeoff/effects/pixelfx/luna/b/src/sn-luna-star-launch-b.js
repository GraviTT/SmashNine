import { palette, drawLaunch } from "./luna-motion-b.mjs";
export const meta = {
  "name": "luna_star_launch B directional linger",
  "desc": "작은 별이 발사된 자리 아래쪽에서 분홍·금 별가루가 전방으로 밀려 나간다. 회전해도 발사자의 얼굴을 피한다.",
  "tags": [
    "smashnine",
    "candidate-b",
    "launch"
  ],
  "size": [
    112,
    64
  ],
  "origin": [
    28,
    18
  ],
  "duration": 0.45,
  "loop": false,
  "fps": 20,
  "options": {
    "seed": 47,
    "kind": "launch",
    "big": false,
    "duration": 0.45
  }
};
meta.options.palette = palette;
export const draw = drawLaunch;
