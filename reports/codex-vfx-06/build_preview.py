"""Self-contained offline HTML preview; only embeds candidate and reference pixels."""
import base64
import io
import json
import numpy as np
from build_boards import background, sprite, frame
from build_effects import OUT, REPORT


def uri(im):
    data = io.BytesIO()
    im.save(data, format='PNG')
    return 'data:image/png;base64,'+base64.b64encode(data.getvalue()).decode('ascii')


images = {'background': uri(background()), 'nova': uri(sprite('nova')), 'frey': uri(sprite('frey'))}
roots = {}
for v in 'ab':
    roots[v] = {}
    for kind in ('head', 'split', 'bind', 'tile'):
        p = OUT / f'nova_beam_{kind}-{v}-v2.png'
        images[v+'-'+kind] = 'data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode('ascii')
        if kind in ('split', 'bind'):
            roots[v][kind] = []
            for i in range(4):
                a = np.array(frame(kind, v, i))
                roots[v][kind].append(int(np.flatnonzero(a[77:84, :, 3].max(0))[0]))

html = '''<!doctype html>
<html lang="ko"><meta charset="utf-8"><title>NOVA VFX-06 후보 미리보기</title>
<style>
body{margin:24px;background:#0e1421;color:#e1eaf9;font:15px system-ui,sans-serif}
h1{font-size:25px;font-weight:650;margin:0 0 12px}p{color:#9bacbf;line-height:1.6}
.controls{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin:20px 0}
button,select{background:#1b2940;color:#eef4ff;border:1px solid #46556f;border-radius:5px;padding:9px;font:inherit}
.stages{display:flex;gap:20px;align-items:flex-start}canvas{width:480px;height:224px;image-rendering:pixelated;border:1px solid #38465c}
figure{margin:0}figcaption{margin:10px 0;color:#a8bbd7}a{color:#6ee4ec}
</style>
<h1>NOVA U · 갈라져 감싸고 끌어오기</h1>
<p>왼쪽 A 곡선 촉수 / 오른쪽 B 각진 갈고리. 실제 후보 PNG를 같은 스프라이트 위에 합성합니다.<br>
비행 16fps → 분리 40fps(0.1초) → 결박 12fps · 300px에서 69px 앞으로 이동. 게임 실행 화면은 아닙니다.</p>
<div class="controls">
<button id="play">일시정지</button><button id="reset">처음으로</button><button id="step">한 프레임</button>
<label>장면 <select id="mode"><option value="sequence">전체 흐름</option><option value="head">비행 루프</option><option value="split">분리 반복 검토</option><option value="bind">결박 루프</option><option value="arrived">69px 도착</option></select></label>
<label>속도 <select id="speed"><option value="1">정속</option><option value="0.25">1/4</option></select></label>
<label>확대 <select id="zoom"><option value="1">1×</option><option value="2">2×</option><option value="4">4×</option></select></label>
<label><input type="checkbox" id="guides">중앙 50×80 표시</label>
</div><p id="readout">이미지 읽는 중</p>
<div class="stages"><figure><canvas id="canvas-a" width="480" height="224"></canvas><figcaption>A · 세 갈래 곡선 촉수</figcaption></figure>
<figure><canvas id="canvas-b" width="480" height="224"></canvas><figcaption>B · 네 갈래 각진 갈고리</figcaption></figure></div>
<p>판단할 점: 벌어졌다 감싸는 의미, 포획 순간 밝기, 캐릭터 가독성, 결박 맥동, 짧아진 연결줄.<br>
정지 보드: <a href="board.png">전체 1×</a> · <a href="tether-seams-4x.png">연결줄 이음 4×</a></p>
<script>const DATA=__DATA__;</script><script>__JS__</script></html>
'''
html = html.replace('__DATA__', json.dumps({'images': images, 'roots': roots}, separators=(',', ':')))
html = html.replace('__JS__', (REPORT / 'preview.js').read_text(encoding='utf-8'))
(REPORT / 'preview.html').write_text(html.rstrip()+'\n', encoding='utf-8')
print('Wrote self-contained preview.html:', len(html.encode('utf-8')), 'bytes')
