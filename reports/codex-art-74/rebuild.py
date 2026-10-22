"""Reproduce accepted rows from local ImageGen raws, using ART-71's D35 pipeline."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,subprocess,sys
import process as p
from refine import translate

# (factor, common x offset, ground every frame, normalization feet target)
CONFIG={
'midgard_rooftop_slinger':[(.2,0,1,72),(.185,0,1,72),(.16,0,1,72),(.23,-3,1,72),(.105,0,1,72),(.16,0,1,72)],
'svartalfheim_gear_beetle':[(.2,0,1,72),(.2,0,1,72),(.15,0,1,72),(.18,0,1,72),(.12,0,1,72),(.15,0,1,72)],
'svartalfheim_cog_drone':[(.2,0,0,72),(.22,0,0,72),(.175,0,0,78),(.21,0,0,72),(.115,0,0,72),(.16,0,0,72)],
'vanaheim_vine_hound':[(.2,0,1,72),(.2,0,1,72),(.15,4,1,72),(.2,0,0,72),(.12,0,1,72),(.16,0,1,72)],
'vanaheim_seed_sprite':[(.19,0,1,72),(.19,0,1,72),(.15,0,1,72),(.185,-4,1,72),(.115,0,1,72),(.145,-1,1,72)],
'jotunheim_rune_golem':[(.19,0,1,72),(.17,0,1,72),(.16,0,1,72),(.175,1,1,72),(.12,0,1,72),(.16,4,1,72)],
}
NOTES={
'midgard_rooftop_slinger':{'windup':'투척 준비: 짧게 접은 슬링을 머리 뒤로 올리고 몸을 비튼다.','attack':'슬링 투척 1회: 앞으로 뻗기 → 팔 내림 → 회복. 돌은 그리지 않았다.'},
'svartalfheim_gear_beetle':{'windup':'등딱지 준비: 머리와 다리를 안으로 접는다.','attack':'닫힌 등딱지가 바닥에 닿는 미끄럼 돌진 반복. 먼지와 궤적 없음.'},
'svartalfheim_cog_drone':{'walk':'수평 이동: 기체를 수평으로 유지하는 호버 비행.','windup':'폭탄 투하 준비: 기체가 조금 올라가고 아래 해치가 열린다.','attack':'빈 해치 개방 → 위쪽 반동 → 해치 폐쇄 반복. 폭탄·급강하 없음.'},
'vanaheim_vine_hound':{'windup':'도약 준비: 몸을 낮추고 다리를 접고 덩굴을 당긴다.','attack':'도약 1회: 이륙 → 공중 두 장 → 착지와 회복. 지상·공중 높이 구분.'},
'vanaheim_seed_sprite':{'windup':'씨앗 방출 준비: 잎과 꼬투리를 몸 쪽으로 모으고 부풀린다.','attack':'꼬투리 잎을 열며 앞으로 내밀고 반동 뒤 회복. 씨앗 투사체 없음.'},
'jotunheim_rune_golem':{'windup':'내려찍기 준비: 두 번째 프레임부터 양 주먹이 머리 위. 룬은 몸 표면에만 표시.','attack':'양 주먹 내려찍기 1회: 바닥 접촉 → 낮은 충격 자세 → 회복. 충격파·먼지 없음.'},
}
SELECTED={
'midgard_rooftop_slinger':[1,2,2,2,2,1],
'svartalfheim_gear_beetle':[1,2,1,3,1,1],
'svartalfheim_cog_drone':[1,1,1,1,1,2],
'vanaheim_vine_hound':[2,1,1,2,1,1],
'vanaheim_seed_sprite':[1,2,1,3,1,1],
'jotunheim_rune_golem':[1,2,2,2,1,3],
}
if __name__=='__main__':
    for mid,settings in CONFIG.items():
        for row,(factor,offset,ground,feet) in zip(p.ROWS,settings):p.normalize(mid,row,factor,bool(ground),feet=feet,offset=offset)
    subprocess.run([sys.executable,str(p.REPORT/'drone_align.py')],check=True)
    p.contacts('svartalfheim_cog_drone','defeat','2,3')
    p.contacts('vanaheim_vine_hound','attack','0,1,4,5')
    translate('vanaheim_vine_hound','attack',[[0,0],[0,0],[0,-10],[0,-1],[0,0],[0,0]],'airborne frames 3/4 follow ascending/descending arc; ground contacts stay at72')
    translate('vanaheim_seed_sprite','attack',[[0,0],[0,2],[0,2],[0,0],[0,0],[0,0]],'frames2/3 visible root foot y70 ->72; opened attached leaf tip ends at74, disclosed separately')
    for mid in CONFIG:
        for row in p.ROWS:
            path=p.BAKE/f'{mid}-{row}-v1.json';m=json.loads(path.read_text('utf-8'))
            if row in NOTES[mid]:m['note']=NOTES[mid][row]
            path.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n','utf-8')
        p.board(mid)
    (p.REPORT/'selection.json').write_text(json.dumps({mid:dict(zip(p.ROWS,rows)) for mid,rows in SELECTED.items()},indent=2),'utf-8')
