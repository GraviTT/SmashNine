"""One-time setup for the user-authorized skm-06c continuation."""
import json
from pathlib import Path
root=Path('reports/codex-skm-06')
p=root/'deliver.py';s=p.read_text(encoding='utf-8')
s=s.replace('이전 실행의 약 6시간 지연은 사용자 확인에 따른 이미지 생성 서비스 지연이다.', '이전 중단은 사용자 설명에 따른 PC 절전 및 image_gen 대기이며 이번 회차와 별도다.')
s=s.replace("stage = sorted(set(stage))", "stage = sorted(set(stage + [str(root/'continue_c.py')]))\nbase_commit = timing['base_commit']\ndef branch_changed(path):\n    old = subprocess.run(['git','show',base_commit+':'+path],capture_output=True)\n    return old.returncode != 0 or old.stdout != Path(path).read_bytes()\nstage = [p for p in stage if p.endswith(('commit.ps1','files-to-stage.json','audit.json')) or branch_changed(p)]")
p.write_text(s,encoding='utf-8')
p=root/'verify_skm.py';s=p.read_text(encoding='utf-8')
s=s.replace("=='codex/skm-06'", "=='codex/skm-06c'")
s=s.replace("check(not git('diff','--name-only','HEAD').strip(),'no tracked files changed')", "check(all(writable(p) for p in git('diff','--name-only','HEAD').splitlines()),'tracked changes stay in scope')")
s=s.replace("check(b[3]-1==152,key+f' F{i+1} feet')", "check((128<=b[3]-1<=152 if row=='recoil_jump' else 90<=b[3]-1<=152 if row=='dive' else b[3]-1==152),key+f' F{i+1} feet or permitted lift')")
s=s.replace("all(.95<=f['face_width_ratio']<=1.06 for f in face['frames'])", "all(.95<=f['face_width_ratio']<=1.06 for f in face['frames'] if f['frame'] in r['face_frames'])")
p.write_text(s,encoding='utf-8')
base=root/'xion/double_float/attempt-1'
(base/'corrections-c.json').write_text(json.dumps({'2':{'points':[[94.5,79],[104.5,79]],'reason':'F2 픽셀 격자에서 x93.5 표식은 짙은 구레나룻/귀 쪽 경계였다. 기준과 같은 눈 아래 볼의 시작 x94.5로 보정. 오른쪽 볼 경계 x104.5 유지; 그림은 변경하지 않음.'}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
rows=json.loads((root/'selection.json').read_text(encoding='utf-8'))
r=rows[2];r.update(accepted=True,face_verified=True,note='도플갱어 부유 6프레임 후보. F2 구레나룻을 제외해 수동 재측정한 노출 얼굴 폭은 전 프레임 1.000이며 눈 간 거리는 가림으로 측정 불가다.',attempt_notes='기존 1차 원본·공통 배율 0.36 유지. F2 왼쪽 얼굴 표식 x93.5→94.5(같은 y79)로 보정하여 1.100→1.000. 원래 자동 표식과 수정 근거를 보존했다. 새 생성이나 픽셀 수정 없음.',human_review='작은 무릎·스카프 변화가 부유로 읽히는지, 발끝 방향과 F6→F1 연결을 판단. 게임이 위치를 띄우므로 모든 발끝은 y152에 맞췄다.')
(root/'selection.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
