"""AUD-01: catalog-complete original numpy SFX. Never rewrites the trial WAVs.

Run with PYTHONDONTWRITEBYTECODE=1. Pillow is used only for measurement plots.
"""
from __future__ import annotations

import hashlib
import json
import re
import wave
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
import synth as dsp

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-aud-01'
OUT = ROOT / 'art/audio_bakeoff'
SR = dsp.SR
TRIAL = {row[0]: row for row in dsp.SOUNDS}
# Card order; fallback sounds belong to their functional group for listening.
GROUPS = ['Fighters', 'Skills', 'Monsters', 'Realms', 'Progress', 'Menus/story']
FALLBACK_GROUP = {'swing': 'Fighters', 'skill_cast': 'Skills', 'ult_start': 'Skills', 'monster_attack': 'Monsters'}

# id: Korean title, duration s, full-file RMS dBFS, intended identity.
# These parameters are authored compositions, never inferred from sampled audio.
SPECS = {
    'swing_light': ('가벼운 휘두름', .16, -15, '짧은 바람과 내려가는 가는 검 궤적'),
    'swing_heavy': ('무거운 휘두름', .29, -15, '넓은 바람과 낮은 검 몸통'),
    'hit_launch': ('강제 발사 적중', .38, -13.5, '타격 몸통 뒤 위로 튀는 발사 음정'),
    'dash': ('기술 돌진 시작', .20, -15, '빠르게 솟는 공기와 짧은 추진 펄스'),
    'tumble': ('강한 넉백 회전', .28, -14, '내려가는 두 펄스의 회전'),
    'respawn': ('링아웃 복귀', .54, -16, '올라오는 세 음과 열리는 빛'),
    'skill_frey_1': ('프레이 · 돌진 베기', .25, -14, '강철 검·날개 바람·금빛 종'),
    'skill_frey_2': ('프레이 · 상승 가르기', .34, -14, '위로 벼리는 검과 열린 날개'),
    'ult_frey': ('프레이 · 발키리 강림', 1.08, -14, '강철 호명·날개·두 번의 낮은 여진'),
    'skill_luna_1': ('루나 · 별 혜성', .28, -14, '상승 별방울과 작은 반짝임'),
    'skill_luna_2': ('루나 · 달고리', .36, -14, '두 방향으로 펼치는 부드러운 별 종'),
    'ult_luna': ('루나 · Brave 변신 시작', 1.18, -14, '여섯 별방울의 상승과 변신의 빛'),
    'skill_luna_brave_1': ('브레이브 루나 · 혜성 돌진', .22, -14, '압축된 주먹 몸통과 낮은 별 폭발'),
    'skill_luna_brave_2': ('브레이브 루나 · Luna Breaker', .34, -14, '회전 킥 두 펄스와 무거운 별'),
    'ult_luna_brave': ('브레이브 루나 · Heart Laser', 1.05, -14, '별 충전 후 굵어지는 펄스 광선'),
    'skill_yuki_1': ('유키 · 부적 놓기', .24, -14, '종이 넘김·부채 스냅·작은 방울'),
    'skill_yuki_2': ('유키 · 결계', .38, -14, '부채가 펼쳐지고 두 방울이 교차'),
    'ult_yuki': ('유키 · 대결계', 1.12, -14, '세 번의 종이 봉인과 길게 남는 방울'),
    'skill_nova_1': ('노바 · 벡터 시프트', .23, -14, '서보 기어가 올라가며 짧은 에너지 추진'),
    'skill_nova_2': ('노바 · 중력 제동', .37, -14, '하강 서보와 세 번의 중력 펄스'),
    'ult_nova': ('노바 · 사건의 지평선 시작', 1.16, -14, '고속 충전·중력 몸통·다중 에너지 펄스'),
    'skill_rio_1': ('리오 · 차원의 베기', .26, -14, '룬의 두 음과 찢기는 차원·검 울림'),
    'skill_rio_2': ('리오 · 룬 반격', .36, -14, '역방향 룬 회전과 검 공명'),
    'ult_rio': ('리오 · Infinity Overdrive', 1.10, -14, '엇갈린 룬 아르페지오·차원 절단·검 드론'),
    'skill_cast': ('공용 기술 폴백', .24, -15, '특정 캐릭터에 치우치지 않은 상승 펄스'),
    'ult_start': ('공용 궁극기 폴백', .90, -14, '중립 충전과 넓어지는 두 공명'),
    'monster_windup': ('몬스터 · 공격 예고', .16, -18, '공격음보다 짧은 낮은 두 박 예고'),
    'monster_bite': ('몬스터 · 물기', .18, -14, '닫히는 턱·짧은 이빨 스냅'),
    'monster_charge': ('몬스터 · 돌진', .32, -14, '낮은 발굽 펄스와 전진 바람'),
    'monster_leap': ('몬스터 · 도약', .28, -14, '탄력 있는 위쪽 궤적'),
    'monster_slam': ('몬스터 · 내려찍기', .39, -13.5, '깊은 지면 타격과 돌 파편'),
    'monster_shell': ('몬스터 · 껍질 구르기', .35, -14, '단단한 껍질이 세 번 구르는 공명'),
    'monster_bolt': ('몬스터 · 직사', .19, -14, '좁은 고속 에너지 하강'),
    'monster_lob': ('몬스터 · 곡사', .31, -14, '먼저 올랐다 내려오는 투척 곡선'),
    'monster_swoop': ('몬스터 · 급강하', .33, -14, '높은 날개 바람에서 낮은 급강하로'),
    'monster_blink': ('몬스터 · 순간이동', .22, -15, '사라짐·틈·재등장의 두 룬 음'),
    'monster_homing': ('몬스터 · 유도탄', .36, -14, '진폭이 흔들리는 추적 펄스'),
    'monster_hurt': ('몬스터 · 피격', .20, -13.5, '선수 피격보다 거친 낮은 몸통'),
    'monster_defeat': ('몬스터 · 쓰러짐', .57, -16, '부서짐과 두 단계 하강'),
    'elite_appear': ('정예 · 등장', .82, -16, '완전5도의 짧은 낮은 뿔피리 호명'),
    'monster_attack': ('공용 몬스터 공격 폴백', .23, -14, '중립적인 발톱 바람과 몸통'),
    'hazard_warning': ('렐름 · 위험 예고', .40, -18, '중저음 두 박 경고'),
    'eruption': ('화염 분출', .68, -16, '낮은 압력과 위로 솟는 대역 잡음'),
    'quake': ('지진', .74, -16, '서로 어긋난 세 지면 진동'),
    'beam': ('빛줄기', .55, -18, '길게 열리는 유리 공명'),
    'vines': ('덩굴 다리', .49, -20, '마찰 잡음과 나무의 상승 공명'),
    'belt_reverse': ('벨트 반전', .35, -20, '톱니 세 번과 하강 서보'),
    'gate_open': ('달빛 문 열림', .72, -18, '완전5도 빛 종과 공간 열림'),
    'gate_travel': ('달빛 문 통과', .45, -18, '안쪽으로 모이는 두 음'),
    'bush_rustle': ('수풀 은신 변화', .18, -24, '짧고 얇은 잎 마찰'),
    'collapse_warning': ('렐름 붕괴 경고', .90, -17, '고음을 억제한 가속 세 박 경고'),
    'soul_pickup': ('소울 획득', .13, -20, '빠르게 모이는 작은 두 별 음'),
    'card_offer': ('성장 카드 제안', .46, -18, '펼치는 바람 뒤 열린 세 음'),
    'card_pick': ('성장 카드 적용', .34, -17, '모이는 룬과 확정의 완전5도'),
    'match_start': ('경기·스테이지 시작', .84, -16, '두 준비 박 뒤 열리는 시작 화음'),
    'results': ('결과 표시', .67, -18, '승패에 치우치지 않는 하강 정리'),
    'victory': ('승리 팡파르', 1.65, -16, '직접 작곡한 D-A-D-F-A-D 짧은 팡파르'),
    'ui_move': ('메뉴 이동', .045, -24, '반복 탐색에 맞춘 아주 짧은 낮은 틱'),
    'story_text': ('대사 한 줄 표시', .032, -28, '글자마다가 아닌 한 줄당 작은 틱'),
    'story_advance': ('대사 다음·건너뛰기', .085, -23, '위로 열리는 조용한 두 음'),
}


def catalog():
    source = (ROOT / 'smash-nine-prototype/scripts/audio/AudioCatalog.gd').read_text(encoding='utf-8')
    entries = {}
    for sound, body in re.findall(r'"([a-z_0-9]+)":\s*\{([^}]+)\}', source):
        group = re.search(r'"group":\s*"([^"]+)"', body).group(1)
        if group != 'Music':
            gap = re.search(r'"gap_ms":\s*(\d+)', body)
            entries[sound] = {'catalog_group': group, 'group': FALLBACK_GROUP.get(sound, group),
                              'gap_ms': int(gap.group(1)) if gap else 40}
    for line in (ROOT / 'design/AUDIO.md').read_text(encoding='utf-8').splitlines():
        if not line.startswith('| '):
            continue
        cells = [c.strip() for c in line.split('|')[1:-1]]
        if len(cells) >= 3:
            sound = cells[1].strip('`')
            if sound in entries:
                entries[sound]['when_ko'] = cells[2]
    assert all('when_ko' in row for row in entries.values())
    assert set(entries) == set(SPECS) | set(TRIAL), (set(entries) - set(SPECS) - set(TRIAL))
    return dict(sorted(entries.items(), key=lambda pair: GROUPS.index(pair[1]['group'])))


def seed_for(sound, style):
    return int.from_bytes(hashlib.sha256(f'AUD01/{sound}/{style}'.encode()).digest()[:4], 'little')


def tone(t, style, hz, end=None, decay=.06, colour='round', attack=.0007):
    """Same identity envelope, three distinct trial-compatible synthesizer families."""
    end = hz if end is None else end
    if style == 'a':
        kind = 'square' if colour in ('steel', 'tech', 'horn') else 'triangle'
        body = dsp.osc(t, hz, end, decay * .6, kind)
        if colour == 'bell':
            body = .76 * body + .24 * dsp.osc(t, hz * 2, end * 2, decay, 'square')
    elif style == 'b':
        ratio = {'steel': 2.76, 'bell': 3.5, 'tech': 2.01, 'horn': 1, 'rune': 1.414}.get(colour, 1.5)
        index = {'steel': 2.4, 'bell': 1.1, 'tech': 2.8, 'horn': 1.7, 'rune': 1.8}.get(colour, .9)
        body = dsp.fm(t, hz, end, ratio, index, decay * .65, decay * .6)
    else:
        body = .72 * dsp.fm(t, hz, end, 1.5, .65, decay, decay * .6)
        body += .20 * dsp.osc(t, hz * 2.003, end * 2.003, decay)
        if colour in ('steel', 'bell', 'rune'):
            body += .14 * dsp.osc(t, hz * 3.01, end * 3.01, decay)
        if colour in ('tech', 'horn'):
            body += .13 * dsp.osc(t, hz / 2, end / 2, decay)
    return body * dsp.env(t, decay, attack)


def render_raw(sound, style):
    """Each branch is an explicit event recipe; reusable oscillators are not samples."""
    _, duration, _, _ = SPECS[sound]
    t = dsp.clock(duration)
    seed = seed_for(sound, style)
    x = np.zeros(len(t))

    def add(at, values, gain=1):
        start = round(at * SR)
        if start < len(x):
            x[start:] += gain * values[:len(x) - start]

    def note(at, hz, end=None, decay=.06, gain=1, colour='round', attack=.0007):
        u = t[:max(0, len(t) - round(at * SR))]
        add(at, tone(u, style, hz, end, decay, colour, attack), gain)

    def air(at=0, decay=.035, gain=.4, low=700, high=8500, pulse=0):
        u = t[:max(0, len(t) - round(at * SR))]
        n = dsp.noise(u, seed + round(at * SR), low, high if style != 'b' else min(high, 6500), 4 if style == 'a' else 1)
        e = dsp.env(u, decay, .001)
        if pulse:
            e *= .65 + .35 * np.cos(2 * np.pi * pulse * u)
        add(at, n * e, gain)

    def impact(at=0, hz=180, decay=.055, gain=1, grit=.6):
        note(at, hz, hz * .37, decay, gain)
        air(at, min(decay * .35, .025), grit * gain, 500, 10000)
        if style == 'c':
            note(at, 100, 45, min(.075, decay), gain * .45)

    def melody(notes, spacing, decay=.08, gain=.6, colour='bell', offset=0):
        for i, hz in enumerate(notes):
            note(offset + i * spacing, hz, decay=decay, gain=gain, colour=colour)

    if sound in ('swing_light', 'swing_heavy', 'dash'):
        heavy = sound == 'swing_heavy'
        air(decay=.065 if heavy else .030, gain=.9, low=600 if heavy else 1800, high=11000)
        note(0, 740 if heavy else 1250, 130 if heavy else 270, .055 if heavy else .032, .20)
        if sound == 'dash':
            note(0, 150, 900, .042, .45, 'tech')
    elif sound == 'hit_launch':
        impact(hz=160, decay=.07, grit=.9)
        note(.015, 260, 1550, .075, .42, 'tech')
    elif sound == 'tumble':
        impact(hz=175, decay=.04, grit=.25)
        note(.055, 330, 90, .055, .5)
        air(.075, .025, .25)
    elif sound == 'respawn':
        melody([392, 587.33, 783.99], .085, .105, .7)
        air(decay=.11, gain=.16, low=1800)
    elif sound.startswith(('skill_', 'ult_')) and sound not in ('skill_cast', 'ult_start'):
        ultimate = sound.startswith('ult_')
        who = sound.removeprefix('skill_').removeprefix('ult_')
        second = who.endswith('_2')
        who = re.sub(r'_[12]$', '', who)
        d = .18 if ultimate else (.075 if second else .055)
        if who == 'frey':
            air(decay=d * .8, gain=.5, low=1500, high=12000)
            note(0, 470 if second else 660, 1260 if second else 410, d, .75, 'steel')
            note(.025, 1320, decay=d * 1.15, gain=.34, colour='bell')
            if ultimate:
                melody([293.66, 440, 587.33], .11, .21, .38, 'horn')
                impact(.24, 120, .15, .8); impact(.52, 85, .13, .55)
        elif who == 'luna':
            melody([783.99, 1174.66, 1567.98] if not second else [987.77, 783.99, 1174.66], .04 if not ultimate else .105, d, .65)
            note(0, 600, 950, d, .14)
            if ultimate:
                melody([1760, 2093, 2349.32], .09, .19, .34, offset=.34)
                air(.45, .17, .2, 2200)
        elif who == 'luna_brave':
            impact(hz=210 if not second else 145, decay=d, grit=.65)
            note(.016, 783.99, decay=d * .9, gain=.32, colour='bell')
            if second:
                impact(.07, 180, .07, .7)
            if ultimate:
                note(0, 220, 880, .22, .4, 'tech')
                for i in range(5):
                    impact(.15 + i * .10, 260, .08, .45, .2)
                note(.15, 392, 587.33, .28, .65, 'bell')
        elif who == 'yuki':
            air(decay=.018, gain=.9, low=2200, high=10500)
            note(.008, 1174.66, decay=d * 1.1, gain=.5, colour='bell')
            note(0, 310, 600, .018, .3, 'steel')
            if second or ultimate:
                note(.09, 1760, decay=d, gain=.35, colour='bell'); air(.085, .025, .5, 3000)
            if ultimate:
                air(.25, .035, .6, 1800); air(.47, .04, .6, 1800)
                melody([587.33, 880, 1174.66], .18, .22, .38, offset=.20)
        elif who == 'nova':
            note(0, 140 if not second else 750, 950 if not second else 95, d, .7, 'tech')
            air(decay=.016, gain=.3, low=1600)
            for i in range(3 if second else 2):
                note(i * .055, 180 + 90 * i, 75, .035, .5, 'tech')
            if ultimate:
                note(0, 100, 1400, .22, .55, 'tech')
                for at in [.22, .37, .53]:
                    impact(at, 95, .12, .75, .5)
        elif who == 'rio':
            note(0, 220, 440 if not second else 110, d, .7, 'rune')
            note(.035, 311.13, 622.25, d, .4, 'rune')
            air(decay=.026, gain=.7, low=1800, high=10000, pulse=65)
            note(0, 110, decay=d * 1.3, gain=.35, colour='steel')
            if ultimate:
                melody([440, 622.25, 880, 1244.51], .095, .16, .45, 'rune', .17)
                air(.28, .12, .5, 1300, pulse=43)
        else:
            raise ValueError(who)
    elif sound in ('skill_cast', 'ult_start'):
        note(0, 330, 660, .065 if sound == 'skill_cast' else .20, .8)
        air(decay=.04, gain=.25)
        if sound == 'ult_start':
            note(.10, 220, 440, .20, .5); note(.22, 660, decay=.18, gain=.4)
    elif sound == 'monster_windup':
        melody([220, 293.66], .045, .025, .7, 'horn')
    elif sound == 'monster_bite':
        air(decay=.009, gain=.8, low=1600); impact(.012, 240, .025, 1, .4)
    elif sound == 'monster_charge':
        air(decay=.075, gain=.6, low=400)
        for at in [0, .065, .12]:
            impact(at, 115, .032, .7, .25)
    elif sound == 'monster_leap':
        note(0, 110, 670, .065, 1); air(decay=.025, gain=.35)
    elif sound == 'monster_slam':
        impact(hz=95, decay=.085, grit=1); air(.035, .055, .35, 120, 3200)
    elif sound == 'monster_shell':
        for i, at in enumerate([0, .075, .14]):
            note(at, 390 - i * 65, decay=.055, gain=1 - i * .18, colour='steel')
            air(at, .009, .3, 1400)
    elif sound == 'monster_bolt':
        note(0, 1700, 180, .035, 1, 'tech'); air(decay=.008, gain=.3)
    elif sound == 'monster_lob':
        note(0, 140, 850, .045, .8); note(.065, 850, 190, .06, .65); air(decay=.022, gain=.25)
    elif sound == 'monster_swoop':
        air(decay=.07, gain=.8, low=1400); note(0, 1450, 140, .075, .4)
    elif sound == 'monster_blink':
        note(0, 660, 1760, .022, 1, 'rune'); note(.095, 880, 330, .03, .8, 'rune')
    elif sound == 'monster_homing':
        note(0, 440, 880, .09, 1, 'tech'); x *= .7 + .3 * np.cos(2 * np.pi * 27 * t)
        air(decay=.025, gain=.2)
    elif sound == 'monster_hurt':
        impact(hz=120, decay=.042, grit=.7); note(0, 290, 85, .024, .3, 'horn')
    elif sound == 'monster_defeat':
        impact(hz=150, decay=.065, grit=.9); melody([220, 146.83, 73.42], .085, .07, .5, 'horn')
    elif sound == 'elite_appear':
        melody([146.83, 220, 293.66], .14, .17, .8, 'horn'); air(decay=.075, gain=.12, low=200, high=2800)
    elif sound == 'monster_attack':
        impact(hz=200, decay=.045, grit=.6); air(decay=.025, gain=.4, low=1500)
    elif sound in ('hazard_warning', 'collapse_warning'):
        offsets = [0, .14] if sound == 'hazard_warning' else [0, .24, .42]
        for at in offsets:
            note(at, 330, decay=.055 if len(offsets) == 2 else .085, gain=.8, colour='horn')
            note(at, 440, decay=.06, gain=.30)
    elif sound == 'eruption':
        impact(hz=85, decay=.12, grit=.6); air(decay=.17, gain=1, low=180, high=5000, pulse=13)
        note(0, 90, 400, .15, .2)
    elif sound == 'quake':
        for i, at in enumerate([0, .15, .31]):
            impact(at, 80 - i * 7, .11, 1 - i * .15, .35)
        air(decay=.18, gain=.4, low=60, high=1700)
    elif sound == 'beam':
        note(0, 587.33, 1174.66, .13, .7, 'bell'); note(.03, 1760, decay=.14, gain=.3, colour='bell')
        air(decay=.1, gain=.15, low=2400)
    elif sound == 'vines':
        air(decay=.11, gain=.8, low=450, high=4500, pulse=32)
        melody([130.81, 196, 261.63], .065, .075, .38)
    elif sound == 'belt_reverse':
        for i, at in enumerate([0, .045, .10]):
            note(at, 460 - i * 100, decay=.023, gain=.65, colour='steel')
        note(0, 720, 95, .075, .5, 'tech'); air(decay=.035, gain=.3, low=1200, high=6000)
    elif sound == 'gate_open':
        melody([293.66, 440, 587.33], .085, .14, .6, 'rune'); air(decay=.12, gain=.2, low=1700)
    elif sound == 'gate_travel':
        note(0, 880, 220, .105, .8, 'rune'); note(.04, 1320, 330, .09, .3, 'bell')
        air(decay=.065, gain=.3, low=1900)
    elif sound == 'bush_rustle':
        air(decay=.031, gain=1, low=2000, high=7800, pulse=47); air(.035, .018, .4, 3300, 9500)
    elif sound == 'soul_pickup':
        melody([987.77, 1481.66], .025, .025, .8)
    elif sound == 'card_offer':
        air(decay=.028, gain=.35, low=1400); melody([392, 587.33, 783.99], .06, .09, .6, 'rune')
    elif sound == 'card_pick':
        note(0, 780, 392, .05, .3, 'rune'); melody([587.33, 880], .055, .065, .7)
    elif sound == 'match_start':
        melody([293.66, 293.66, 587.33], .17, .12, .65, 'horn')
        note(.34, 440, decay=.13, gain=.35, colour='bell'); impact(0, 110, .055, .35, .2)
    elif sound == 'results':
        melody([587.33, 440, 293.66], .13, .11, .6, 'rune')
    elif sound == 'victory':
        melody([293.66, 440, 587.33, 698.46, 880, 1174.66], .18, .18, .7, 'horn')
        for at in [0, .36, .72]:
            impact(at, 100, .06, .25, .25)
        note(.9, 587.33, decay=.21, gain=.3, colour='bell')
    elif sound == 'ui_move':
        note(0, 520, 650, .008, .9)
    elif sound == 'story_text':
        note(0, 390, 310, .005, .8); air(decay=.003, gain=.12, low=1100, high=4300)
    elif sound == 'story_advance':
        melody([520, 780], .016, .014, .7)
    else:
        raise ValueError(sound)
    return x


def master(x, target):
    """Preserve envelope by default; soften crest only if RMS gain exceeds ceiling.

    PCM ceiling uses floor so new files really stay <= -1 dBFS after rounding.
    Trial uses the old master and remains byte-identical (its rounding is +0.00015dB).
    """
    x = x - np.mean(x)
    x /= np.max(np.abs(x))
    fade = np.ones(len(x))
    a, b = round(.0007 * SR), min(round(.012 * SR), len(x) // 3)
    fade[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** 2
    fade[-b:] = np.sin(np.linspace(np.pi / 2, 0, b)) ** 2
    fade[0] = fade[-1] = 0
    ceiling = np.floor(dsp.PEAK * 32768) / 32768
    goal = 10 ** (target / 20)

    def shaped(gamma):
        y = np.sign(x) * np.abs(x) ** gamma * fade
        return y * goal / np.sqrt(np.mean(y * y))

    gamma = 1.0
    y = shaped(gamma)
    if np.max(abs(y)) > ceiling:
        lo, hi = .10, 1.0
        assert np.max(abs(shaped(lo))) < ceiling, 'Target RMS unattainable'
        for _ in range(45):
            mid = (lo + hi) / 2
            if np.max(abs(shaped(mid))) > ceiling:
                hi = mid
            else:
                lo = mid
        gamma = lo
        y = shaped(gamma)
    pcm = np.rint(y * 32768).astype('<i2')
    assert np.max(abs(pcm.astype(np.int32))) <= int(np.floor(dsp.PEAK * 32768))
    return pcm, gamma


def trio_picture(sound, rows):
    """One plot per id: fixed axes, comparable A/B/C waveform and log STFT."""
    im = Image.new('RGB', (1536, 700), '#0e1523')
    d = ImageDraw.Draw(im)
    d.text((22, 12), sound + ' / measured PCM16 / 44.1 kHz mono', font=dsp.font(22), fill='white')
    stops = np.array([[10, 16, 30], [36, 52, 106], [104, 65, 153], [220, 97, 105], [255, 222, 144]])
    for col, (m, x) in enumerate(rows):
        ox = col * 512
        left, right, top, bottom = ox + 54, ox + 492, 105, 265
        colour = ['#83e2c3', '#bcadff', '#ffc38c'][col]
        d.text((ox + 24, 48), f"{m['style'].upper()}  {m['length_s']:.3f}s  RMS {m['rms_dbfs']:.1f} / peak {m['peak_dbfs']:.2f}", font=dsp.font(16), fill=colour)
        for val in [-1, -.5, 0, .5, 1]:
            yy = (top + bottom) / 2 - val * 80
            d.line((left, yy, right, yy), fill='#2e3a51')
            d.text((ox + 10, yy - 8), f'{val:+.1f}', font=dsp.font(12), fill='#a9b8ce')
        bins = np.linspace(0, len(x), right - left + 1).astype(int)
        for i, (a, b) in enumerate(zip(bins[:-1], bins[1:])):
            v = x[a:max(a + 1, b)]
            d.line((left + i, 185 - max(v) * 80, left + i, 185 - min(v) * 80), fill=colour)
        nfft, hop = 1024, 128
        frames = np.lib.stride_tricks.sliding_window_view(np.pad(x, (512, 512)), nfft)[::hop]
        win = np.hanning(nfft)
        levels = 20 * np.log10(np.maximum(abs(np.fft.rfft(frames * win, axis=1)) * 2 / win.sum(), 1e-6))
        st, sb = 335, 605
        hz = np.geomspace(SR / 2, 60, sb - st)
        rr = np.clip(np.rint(hz / SR * nfft).astype(int), 0, 512)
        cc = np.clip(np.rint(np.linspace(0, len(x) / hop, right - left)).astype(int), 0, len(frames) - 1)
        values = np.clip((levels[cc[None, :], rr[:, None]] + 80) / 80, 0, 1) * 4
        k = np.minimum(values.astype(int), 3)
        rgb = stops[k] * (1 - (values - k)[..., None]) + stops[k + 1] * (values - k)[..., None]
        im.paste(Image.fromarray(rgb.astype(np.uint8)), (left, st))
        d.text((left, 298), 'Hann1024 hop128 / log Hz', font=dsp.font(15), fill='#cbd7ed')
        for f in [60, 250, 1000, 4000, 16000]:
            yy = st + np.log((SR / 2) / f) / np.log((SR / 2) / 60) * (sb - st)
            d.text((ox + 3, yy - 7), str(f), font=dsp.font(12), fill='#a9b8ce')
        for at in np.linspace(0, m['length_s'], 4):
            xx = left + at / m['length_s'] * (right - left)
            d.text((xx - 14, 614), f'{at:.2f}', font=dsp.font(12), fill='#a9b8ce')
        d.text((ox + 24, 648), f"tail1ms {m['last_1ms_peak_dbfs']:.1f}dBFS / ends 0", font=dsp.font(15), fill=colour)
    d.text((22, 678), 'Time (s); amplitude +/-1; spectrum fixed -80..0 dBFS. Design intent is not a listening verdict.', font=dsp.font(15), fill='#a9b8ce')
    im.save(REPORT / f'{sound}.png')


def main():
    REPORT.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    entries = catalog()
    trial = json.loads((ROOT / 'reports/codex-aud-01a/measurements.json').read_text(encoding='utf-8'))
    old = {(r['sound'], r['style']): r for r in trial['records']}
    records = []
    for sound, meta in entries.items():
        trio = []
        for style in 'abc':
            path = OUT / f'{sound}-{style}.wav'
            if sound in TRIAL:
                before = old[sound, style]
                assert hashlib.sha256(path.read_bytes()).hexdigest() == before['sha256'], path
                m, x = dsp.measure(path, before['crest_shape_gamma'])
                label, target, intent, limits = before['label'], TRIAL[sound][3], before['note'], before['duration_range_s']
            else:
                label, duration, target, intent = SPECS[sound]
                pcm, gamma = master(render_raw(sound, style), target)
                with wave.open(str(path), 'wb') as w:
                    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
                m, x = dsp.measure(path, gamma)
                limits = [.6, 1.2] if sound.startswith('ult_') else ([.15, .4] if sound.startswith('skill_') else [duration, duration])
            m.update(sound=sound, style=style, label=label, note=dsp.STYLE_NOTES[style],
                     intent_ko=intent, target_rms_dbfs=target, duration_range_s=limits,
                     preserved_trial=sound in TRIAL, **meta)
            assert m['peak_dbfs'] <= (-.9998 if sound in TRIAL else -1), (sound, style, m['peak_dbfs'])
            assert abs(m['rms_dbfs'] - target) < .02, (sound, style, m['rms_dbfs'])
            assert m['clipped_samples'] == 0 and m['lead_in_ms_at_minus60'] <= 5
            assert m['first_sample'] == m['last_sample'] == 0
            assert m['last_1ms_peak_dbfs'] < -45 and m['last_1ms_max_step'] < .001, (sound, style, m['last_1ms_peak_dbfs'])
            assert limits[0] - 1 / SR <= m['length_s'] <= limits[1] + 1 / SR
            records.append(m); trio.append((m, x))
        trio_picture(sound, trio)
        print(f"{meta['group']:12s} {sound:24s} ABC  RMS {target:5.1f} dBFS", flush=True)
    summary = {'method': 'Original deterministic numpy synthesis; measured written PCM16; trial WAVs read-only',
               'sample_rate': SR, 'peak_target_dbfs': -1, 'records': records}
    (REPORT / 'measurements.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    lines = ['| 그룹 | 파일 | 길이 s | Peak dBFS | RMS dBFS | 목표 RMS | 시작 ms | 끝 1ms dBFS |',
             '|---|---|---:|---:|---:|---:|---:|---:|']
    lines += [f"| {m['group']} | `{Path(m['file']).name}` | {m['length_s']:.3f} | {m['peak_dbfs']:.5f} | {m['rms_dbfs']:.4f} | {m['target_rms_dbfs']:.1f} | {m['lead_in_ms_at_minus60']:.3f} | {m['last_1ms_peak_dbfs']:.2f} |" for m in records]
    (REPORT / 'measurements.md').write_text('\n'.join(lines) + '\n', encoding='utf-8', newline='\n')
    print('Complete:', len(entries), 'ids;', Counter(m['group'] for m in records))


if __name__ == '__main__':
    main()
