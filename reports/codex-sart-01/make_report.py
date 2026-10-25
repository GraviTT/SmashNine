"""Create a factual handoff, using final metrics only if actually present."""
import html
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-sart-01'


def main():
    manifest=json.loads((REPORT/'generation-manifest-v2.json').read_text(encoding='utf-8'))
    raw=json.loads((REPORT/'raw-measurements-v1.json').read_text(encoding='utf-8'))
    final_path=REPORT/'measurements-v1.json'
    alternative_path=REPORT/'measurements-alternative-v1.json'
    completed=final_path.exists() or alternative_path.exists()
    alternative=not final_path.exists() and alternative_path.exists()
    final=json.loads((final_path if final_path.exists() else alternative_path).read_text(encoding='utf-8')) if completed else None
    review=json.loads((REPORT/'visual-review-v1.json').read_text(encoding='utf-8'))
    measures=final['candidates'] if completed else raw['items']
    scope='가공 후보' if completed else '생성 원본'
    state='완료: 비교 후보 6장, 교체 전 멧돼지 2장, 각각의 JSON, JPEG 연락판과 검수 기록.' if completed else '미완료: 생성·원본 보존·원본 계측·육안 검수는 끝났으나, 규격 가공 후보와 JPEG 연락판은 아직 만들지 못했다.'
    lines=['# SART-01 · 스토리 장면 그림 검수 및 인계','',state,'',
        '- 브랜치: `codex/sart-01`. 후보 작업이며 게임 채택·연결은 하지 않았다.',
        '- 생성: 내장 `image_gen` 6회 + 멧돼지 하단 구도 수정 2회. 총 8개 원본을 서로 다른 버전 이름으로 보존했다.',
        '- 실제 참조를 `referenced_image_paths`에 전달했다. 모든 장면은 `transparent_background=false`.',
        '- 생성 도구 반환 경로 → `art/raw/story/<name>-vN_raw.png` 복사. 8/8 SHA-256 일치, PNG CRC 및 불투명 RGB/alpha 확인.',
        '- `smash-nine-prototype/` 변경 없음. Godot·설치·다운로드·병합·push 실행 없음.',
        '- `.git`은 현재 환경에서 읽기 전용이다. `commit.ps1`과 마지막 줄이 지정 Co-Authored-By인 `commit-message.txt`를 준비했으며 실행하지 않았다.','',
        '## 현재 상태','']
    if completed:
        lines += ['8장 모두 1600×900 불투명 RGB PNG로 가공했다. 비교 대상은 숲 v1/v2, 멧돼지 v3/v4, 심장 v1/v2다. 멧돼지 v1/v2는 원안의 하단 가독성 실패 이력으로만 남긴다.','']
        if alternative:
            lines += ['후처리는 사용자 허용을 받은 대체 방식인 Python 표준 라이브러리의 분리형 Lanczos3로 수행했다. Pillow를 사용했다고 주장하지 않는다. JPEG 연락판의 글자·대화 띠·JPEG quality 90 인코딩에는 기존 Windows System.Drawing을 사용했다.','']
    else:
        lines += [
            'Python 3.12의 실행 파일 경로가 샌드박스에서 액세스 거부되었다. 별도 기존 Python 3.14와 3.13 실행기는 작동했지만 Pillow가 없었다. Temp의 기존 Pillow 가상환경은 동일하게 차단된 Python 3.12를 기반으로 하므로 우회 실행하지 않았다. 설치·다운로드는 하지 않았다.',
            '',
            '`build_candidates.py`는 요청한 Python + Pillow 후처리·계측·연락판 생성용이며 아직 실행하지 못했다. `fallback_lanczos.py`는 사용자의 대체 가공 허용이 있을 때만 실행하도록 준비한 코드이고, 허용 플래그 없이는 출력 파일을 만들지 않는다. 두 스크립트를 실행 완료 또는 검증 완료로 보아서는 안 된다.',
            '',
            '따라서 이 보고서의 밝기·색상 거리·육안 판정은 **생성 원본** 기준이다. `art/bakeoff/story/`의 규격 후보 PNG/JSON, 최종 후보 계측 및 JPEG 연락판은 남은 작업이다.','']
    lines += ['## 그림별 비교와 추천','',
        '| 장면 | 비교 버전 | 추천 | 이유 |',
        '|---|---|---|---|',
        '| cg_forest · stage 5 | v1 먼 전경 / v2 가까운 사선 | **v1** | 수정 3개와 끊어진 다리, 무너지는 두 지반의 관계가 빠르게 읽히고 하단도 더 조용하다. |',
        '| cg_beast · stage 7 | v3 측면 / v4 정면 사선 | **v3** | 몸통·등 가시·굽은 엄니와 바닥 긁기가 잘 구분된다. v4는 정면 돌진의 압박감이 더 강한 대안이다. |',
        '| cg_heart · stage 9 | v1 정면 / v2 사선 | **v1** | 원형 경기장과 다섯 불꽃이 한눈에 보이고 중앙 심장에 시선이 모인다. v2는 공간 깊이가 더 크다. |','',
        '멧돼지 v1/v2는 앞발과 바닥 긁는 불꽃이 화면 하단 25%에 들어가 **FAIL**로 기록했다. 같은 원안을 실제 edit target으로 전달해 v3/v4로 다시 생성했으며 원안을 덮어쓰지 않았다.','',
        '### 실제 파일','']
    for asset,pair in [('cg_forest',('v1','v2')),('cg_beast',('v3','v4')),('cg_heart',('v1','v2'))]:
        paths=[]
        for version in pair:
            name=asset+'-'+version
            path=f'../../art/bakeoff/story/{name}.png' if completed else f'../../art/raw/story/{name}_raw.png'
            paths.append(f'[{name} {scope}]({path})')
        lines += ['- '+asset+': '+' · '.join(paths)]
    lines += ['', '[브라우저 비교판](raw-compare.html)은 이미지를 나란히 보고 하단 대화 영역을 켜고 끄는 로컬 검토용 HTML이다. JPEG 연락판을 대체했다고 간주하지 않는다.','',
        '## 명세 줄별 PASS / FAIL','',
        '내용·스타일의 PASS는 생성 원본을 전 해상도에서 본 육안 판정이다. OCR·얼굴 검출기의 자동 무검출 결과가 아니다. 후처리 이후 최종 PNG도 전 해상도에서 별도로 확인해야 한다. 필수 주제인 멧돼지의 동물 머리·눈은 허용하고, 공통 금지 얼굴은 사람 얼굴·인간형 형상·의도하지 않은 얼굴 모티프로 해석했다.','',
        '| 공통 명세 | 숲 v1/v2 | 멧돼지 v3/v4 | 심장 v1/v2 | 근거 |',
        '|---|---|---|---|---|',
        ('| 최종 1600×900 | PASS | PASS | PASS | 실제 후보 PNG 계측 |' if completed else '| 최종 1600×900 | FAIL(미완료) | FAIL(미완료) | FAIL(미완료) | 원본은 1672×940 또는 1672×941, 가공 후보 없음 |'),
        '| 불투명 | PASS | PASS | PASS | 모든 원본 픽셀 확인; 반투명·투명 없음 |',
        ('| 16:9 크롭·축소·확대 금지 | PASS | PASS | PASS | 아래 처리 좌표와 배율 기록 |' if completed else '| 16:9 크롭·축소·확대 금지 | FAIL(미완료) | FAIL(미완료) | FAIL(미완료) | 계획만 준비; 확대는 하지 않음 |'),
        ('| Python + Pillow LANCZOS | 사용자 허용 대체 | 사용자 허용 대체 | 사용자 허용 대체 | 표준 Lanczos3 구현, Pillow 미사용 |' if alternative else '| Python + Pillow LANCZOS | PASS | PASS | PASS | 가공 기록 확인 |' if completed else '| Python + Pillow LANCZOS | FAIL(미완료) | FAIL(미완료) | FAIL(미완료) | 실행 환경 문제 |'),
        '| ART-70 페인티드 픽셀 아트·픽셀 덩어리·에어브러시 회피 | PASS | PASS | PASS | cg_prologue와 title_bg를 실제 참조로 전달; 픽셀 군집과 계단형 외곽 |',
        '| 하늘 노출부의 깊은 남색·은하 | PASS | PASS | PASS | 모든 원본에서 확인 |',
        '| 하단 25% 어둡고 조용함 | PASS | PASS | PASS | 밝기 수치 + 중요 주제 가림 여부 육안 확인 |',
        '| 사람·얼굴·인물·인간 조각상 없음 | PASS | PASS | PASS | 필수 멧돼지 외의 생물/인물 없음 |',
        '| 글자·글리프·로고·UI·프레임·테두리·워터마크·사진풍 없음 | PASS | PASS | PASS | 전 해상도에서 발견 없음 |',
        '| Text: none | PASS | PASS | PASS | 읽을 수 있는 글자나 유사 글자열 발견 없음 |',
        '| 두 안의 명확한 차이 | PASS | PASS | PASS | 먼 전경/근경 사선, 측면/정면 사선, 정면/사선 |','',
        '### cg_forest','',
        '| 명세 | v1 | v2 | 확인 |','|---|---|---|---|',
        '| 참조 3 바나헤임·참조 7 수정 | PASS | PASS | 스타일 참조 1·2와 함께 도구에 전달 |',
        '| 숲 섬 붕괴·거목·기울어진 이끼 사원 | PASS | PASS | v1 왼쪽 사원과 오른쪽 거목 / v2 오른쪽 위 사원과 왼쪽 거목 |',
        '| 뿌리 뜯김·낙하하는 지반 조각 | PASS | PASS | 벌어진 토양 아래 노출 뿌리와 분리된 낙하 조각 |',
        '| 끊어지는 덩굴 다리 | PASS | PASS | 끊어진 바닥과 벌어진 끝, 늘어지거나 끊어진 덩굴 |',
        '| 초록·금빛 숲 조명·균열의 적주황 붕괴광 | PASS | PASS | 잎·사원 광원과 지반 균열에서 확인 |',
        '| 보라 소울 수정 정확히 3개, 다른 높이 | PASS | PASS | 별개의 수정 3개; 좌표는 visual-review-v1.json |',
        '| 지정 팔레트 | PASS | PASS | 육안 계열 확인; 색상별 거리와 점유율은 계측 JSON. 수치 합격선은 카드에 없음 |','',
        '### cg_beast','',
        '| 명세 | v1 | v2 | v3 | v4 |','|---|---|---|---|---|',
        '| 참조 4 용암 렐름·참조 6 멧돼지 디자인 | PASS | PASS | PASS | PASS |',
        '| 거대 멧돼지·어두운 암석·발광 균열·등 가시·굽은 엄니 | PASS | PASS | PASS | PASS |',
        '| 낮은 시점·용암의 아래 조명 | PASS | PASS | PASS | PASS |',
        '| 바닥 긁기·돌진 직전 자세 | PASS | PASS | PASS | PASS |',
        '| 연기·불씨·뒤쪽 분출 기둥 | PASS | PASS | PASS | PASS |',
        '| 유일한 생물 | PASS(1마리) | PASS(1마리) | PASS(1마리) | PASS(1마리) |',
        '| 지정 팔레트 | PASS | PASS | PASS | PASS |',
        '| 하단 25% 조용함 | **FAIL** | **FAIL** | PASS | PASS |','',
        'v1/v2의 하단 평균이 어둡다는 사실만으로 합격시키지 않았다. 앞발과 긁는 동작이 대화 상자에 가려지므로 구도를 수정했다.','',
        '### cg_heart','',
        '| 명세 | v1 | v2 | 확인 |','|---|---|---|---|',
        '| 참조 5 중앙 렐름·참조 1 심장 외형 | PASS | PASS | 스타일 title_bg와 함께 전달 |',
        '| 세계수 아래 최종 경기장·뿌리와 돌의 원형 바닥 | PASS | PASS | 정면 타원 / 사선 타원으로 원형 바닥 표현 |',
        '| 뒤틀린 분홍 심장·균열·검보라 맥·발광 | PASS | PASS | 갈라진 표면과 뒤엉킨 어두운 가지형 맥, 분홍/백색 균열 빛 |',
        '| 바닥에서 심장 쪽으로 오르는 검보라 불꽃 정확히 5개 | PASS | PASS | 독립 바닥 접점 5개, 서로 구분되는 화염 |',
        '| 추상 불꽃만, 얼굴·몸·사람 실루엣 없음 | PASS | PASS | 머리·눈·어깨·팔·다리 없이 꼬인 화염 띠 |',
        '| 희미한 분홍 빛 입자 | PASS | PASS | 불꽃 사이와 심장 주변의 작은 입자 |',
        '| 지정 팔레트 | PASS | PASS | 육안 계열과 색상별 거리 함께 기록 |','',
        f'## {scope} 계측','',
        "밝기는 모든 픽셀의 감마 인코딩된 sRGB에서 `Y′=0.2126R+0.7152G+0.0722B`(0~255)를 계산했다. 하단은 `floor(H×3/4)`부터다. 대화 띠를 씌우기 전 그림 자체를 측정했다.",
        '',
        '색상 거리는 sRGB→D65 CIELAB의 ΔE76이다. 아래 평균은 각 픽셀에서 지정 팔레트 중 가장 가까운 색까지의 거리를 픽셀 수로 가중했다. 남색 하늘·다른 명암색도 포함하므로 색상 품질 점수로 단정하지 않는다. 카드에는 수치 합격선이 없다. 각 팔레트 색의 최소 거리와 ΔE≤10 점유율은 JSON에 있다.','',
        '| 버전 | 실제 크기 | 상단 75% 평균 | 하단 25% 평균 | 하단/상단 | 팔레트 평균 ΔE76 |','|---|---|---:|---:|---:|---:|']
    for item in measures:
        m=item['measurements']
        size=item.get('size',m.get('size'))
        lines.append(f"| {item['name']} | {size[0]}×{size[1]} | {m['top_mean_luma']:.2f} | {m['bottom_mean_luma']:.2f} | {m['bottom_to_top_ratio']:.3f} | {m['nearest_palette_mean_delta_e76']:.2f} |")
    lines += ['', ('전체 계측: [최종 가공 계측](measurements-alternative-v1.json).' if alternative else '전체 계측: [최종 가공 계측](measurements-v1.json).' if completed else '전체 계측: [원본 전용 계측](raw-measurements-v1.json). 최종 후보 계측으로 오인하지 말 것.'), '',
        '## 크롭·리사이즈','',
        ('실제 수행한 공통 처리:' if completed else '**아래는 아직 실행하지 못한 처리 계획이다.**'),'',
        '| 원본 | 중앙 크롭 상자 | 크롭 결과 | 축소 목표 | 배율 |','|---|---|---|---|---|',
        '| 1672×941 (6장) | (4, 2, 1668, 938) | 1664×936 | 1600×900 | 25/26 ≈ 0.961538 |',
        '| 1672×940 (forest v2, beast v4) | (4, 2, 1668, 938) | 1664×936 | 1600×900 | 25/26 ≈ 0.961538 |','',
        '상자는 `[left, top, right, bottom)`이다. 좌우 4px씩, 941px 원본은 위 2px·아래 3px, 940px 원본은 위아래 2px씩만 제거한다. 확대·페인팅·색상 매핑·선명화·합성·검은 띠 굽기는 후보에 적용하지 않는다.', '',
        '## 연락판','']
    if completed:
        for sheet in final['contact_sheets']:
            name=Path(sheet['path']).name
            lines.append(f"- [{name}]({name}): {sheet['bytes']:,} bytes, JPEG quality 90, 각 그림 1280×720, 전체 3840×828.")
        lines += ['', '각 장면의 두 최종 후보 옆에 ART-70 cg_prologue를 놓고 하단 25%에만 RGBA (8,12,25,200) 띠를 올렸다. 후보 PNG에는 띠나 글자가 없다. `cg_beast-before-contact.jpg`는 탈락 원안 비교용이다.']
    else:
        lines += ['JPEG 연락판은 **미생성**이다. 생성 예정 경로:', '',
            '- `reports/codex-sart-01/cg_forest-contact.jpg`',
            '- `reports/codex-sart-01/cg_beast-contact.jpg`',
            '- `reports/codex-sart-01/cg_heart-contact.jpg`',
            '- 원안 확인용 추가 계획: `cg_beast-before-contact.jpg`', '',
            '완료 시 각 후보와 cg_prologue를 1280×720씩 나란히 놓고 하단 25%에 대화 띠를 표시한다. JPEG quality 90, 파일당 2,000,000 bytes 이하를 검사하도록 스크립트를 준비했다. 지금 확인할 수 있는 자료는 [원본 비교 HTML](raw-compare.html)과 원본 PNG다.']
    lines += ['', '## 사람이 판단할 부분','',
        '1. 숲: 넓게 설명하는 v1과 눈앞에서 붕괴하는 v2 중 대사 분위기에 더 맞는 구도. 수정과 끊어진 다리가 바로 읽히는지.',
        '2. 멧돼지: v3의 몸체·등 가시 가독성과 v4의 정면 압박감 중 선호. 기존 작은 멧돼지 스프라이트와 같은 짐승으로 느껴지는지.',
        '3. 심장: v1의 명확한 최종 무대와 v2의 공간 깊이 중 선호. 불꽃이 사람이나 유령 얼굴로 오해되지 않는지, 심장의 타락이 충분히 보이는지.',
        '4. 공통: ART-70와 나란히 보았을 때 픽셀 밀도·채도·광원 강도가 맞는지. 최종 채택 후 리드가 실제 대화 상자를 얹어 가림과 읽기 편함을 확인할 것.', '',
        '## 남은 작업과 실행','']
    lines += (['후보 채택은 사용자 판단이다. 리드의 통합 후 실제 스토리 화면에서 대화 가림을 확인하면 된다. 게임 실행 검증은 하지 않았다.'] if completed else [
        '1. 실행 가능한 Python + Pillow 환경을 제공하거나, 준비된 대체 Lanczos3 방식 사용을 사용자가 명시적으로 허용해야 한다.',
        '2. 접근 가능한 기존 Python + Pillow가 있는 사용자 세션에서 `finish.ps1 -Python <실행기 경로>` 실행. 이 스크립트는 설치·다운로드·commit 없이 `build_candidates.py`와 보고서 갱신만 수행한다. 대체 방법을 명시적으로 허용한 경우에만 `fallback_lanczos.py --approved-alternative`를 사용할 수 있다.',
        '3. 최종 PNG 8장과 JSON, 최종 계측, JPEG 연락판을 확인하고 `make_report.py`로 이 보고서를 실제 완료 상태로 갱신.',
        '4. 최종 크기에서 육안 검수 후 리드가 `commit.ps1` 실행. 원본 `art/raw/`는 staging 대상이 아니다.'])
    lines += ['', '## 최종 프롬프트 전문','', '수정본은 원안과 수정 프롬프트를 함께 남긴다. 개별 복사용 파일은 [PROMPTS.md](PROMPTS.md), 기계 판독용은 [generation-manifest-v2.json](generation-manifest-v2.json)이다.','']
    for item in manifest['candidates']:
        lines += ['### '+item['name'], '', '참조 순서: '+' → '.join(item['refs']), '', '~~~text',item['prompt'],'~~~','']
    (REPORT/'README.md').write_text('\n'.join(lines),encoding='utf-8',newline='\n')
    sections=[]
    for asset,pair in [('cg_forest',('v1','v2')),('cg_beast',('v3','v4')),('cg_heart',('v1','v2')),('cg_beast_before',('v1','v2'))]:
        base='cg_beast' if asset=='cg_beast_before' else asset
        panels=[]
        for version in pair:
            name=base+'-'+version
            url=f'../../art/bakeoff/story/{name}.png' if completed else f'../../art/raw/story/{name}_raw.png'
            panels.append(f'<figure><figcaption>{name} ({scope})</figcaption><div class="picture"><img src="{url}" alt="{name}"><div class="band"></div></div></figure>')
        panels.append('<figure><figcaption>ART-70 cg_prologue · 스타일 기준</figcaption><div class="picture"><img src="../../smash-nine-prototype/assets/art/story/cg_prologue.png" alt="cg_prologue"><div class="band"></div></div></figure>')
        sections.append('<section><h2>'+asset+'</h2><div class="row">'+''.join(panels)+'</div></section>')
    page='<!doctype html><html lang="ko"><meta charset="utf-8"><title>SART-01 비교</title><style>body{background:#101522;color:#eee;font:16px Malgun Gothic,sans-serif;margin:24px}h1{font-size:24px}.row{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}figure{margin:0}figcaption{padding:8px 0}.picture{aspect-ratio:16/9;position:relative}img{width:100%;height:100%;object-fit:cover}.band{position:absolute;inset:75% 0 0;background:rgba(8,12,25,.784)}body.no-band .band{display:none}button{padding:8px 16px;cursor:pointer}section{margin:24px 0}a{color:#c5a4ff}</style><h1>SART-01 '+scope+' 비교</h1><p>'+html.escape(state)+'</p><p>HTML 표시용 비교이며 JPEG 연락판과 구별합니다. 원본/후보 파일은 변경하지 않습니다.</p><button onclick="document.body.classList.toggle(\'no-band\')">하단 대화 영역 표시/숨기기</button>'+''.join(sections)+'</html>'
    (REPORT/'raw-compare.html').write_text(page,encoding='utf-8',newline='\n')
    print('README.md and raw-compare.html written. final_candidates_complete='+str(completed))


if __name__=='__main__':
    main()
