"""Keep only explicitly inspected valid proposals; never count obscured eyes."""
import sys,json
from pathlib import Path
stem,row,att,valid,reason=sys.argv[1:6]
base=Path(f'reports/codex-skm-02/{stem}/{row}/attempt-{att}')
d=json.loads((base/'face-proposed.json').read_text(encoding='utf-8'));valid={int(x) for x in valid.split(',')}
for f in d['frames']:
 f['eye_ratio']=None
 f['eye_measurement']='반대쪽 눈이 가려져 두 눈 거리 측정 불가. 수치 통과로 취급하지 않음.'
 if f['frame'] not in valid:
  f['face_width_ratio']=None;f['excluded_reason']=reason
 else:f['review']='4배 표식과 전신 판 직접 확인, 노출 얼굴 폭 표식 채택.'
d['review_note']='자동 제안에서 육안 확인된 노출 얼굴 폭만 채택. 머리 전체 값은 별도 head-scale.json 참조.'
(base/'face-measured.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
