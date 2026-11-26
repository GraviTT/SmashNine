extends RefCounted
## What is delivering the hit that is being applied right now.
## A swing's hit area raises `melee` round its apply_hit call: a fighter's swing (Attack.gd), a
## monster's (MonsterAttack.gd), Nova's flying body (NovaBodyHitbox.gd). Shots, beams, fields and
## the bursts a fighter sets off somewhere else (Luna's star burst, Rio's decoy: their hit areas
## carry the meta "ranged") do not.
## Riposte (a soul card) reads it: a parried swing stuns the foe who swung, a parried shot does not
## (2026-11-26, the lead's reading of D54's "패리에 성공하면 그 상대가 1초 기절한다": not a foe
## across the screen).

static var melee := 0
