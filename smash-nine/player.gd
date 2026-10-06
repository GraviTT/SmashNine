extends CharacterBody2D

## 플레이어 캐릭터 컨트롤러 & HP x 넉백 하이브리드 전투 스크립트 (Player.gd)
##
## 이 스크립트는 고도 엔진 4 (Godot 4) 기반의 2D 플랫폼 격투 배틀로얄 플레이어 캐릭터용입니다.
## GDD의 핵심 매커니즘인 '남은 HP 비례 제곱식 넉백' 및 '피격 경직(Hitstun)' 시스템을 구현합니다.

# --- 시그널 (Signals) ---
signal eliminated # 체력이 0% 이하로 떨어져 완전히 탈락할 때 격발되는 시그널

# --- 상상력/밸런싱 파라미터 (Export Variables) ---
@export_group("Movement Settings")
@export var SPEED: float = 300.0              # 기본 지상 좌우 이동 속도
@export var JUMP_VELOCITY: float = -450.0      # 기본 점프 속도 (음수 방향)
@export var GRAVITY_MULTIPLIER: float = 1.0    # 프로젝트 중력에 곱할 배율

@export_group("HP & Combat Settings")
@export var max_hp: float = 100.0             # 최대 체력 (GDD 기준 기본 100)
@export var knockback_decay: float = 300.0     # 초당 감쇠할 넉백 속도 (지상 마찰력 개념)
@export var base_hitstun_duration: float = 0.1 # 기본 피격 경직 시간 (초)
@export var min_hp_for_calc: float = 5.0       # 나누기 0 방지 및 과도한 넉백 증폭 제한을 위한 최소 계산 체력 기준
@export var max_knockback_multiplier: float = 50.0 # 넉백 배율의 최대 상한선

# --- 상태 변수 (State Variables) ---
var current_hp: float = 100.0
var hitstun_timer: float = 0.0

# 프로젝트 설정에서 기본 중력 가속도 로드
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	current_hp = max_hp
	print("[Player] 초기화 완료 - HP: ", current_hp, "/", max_hp)

func _physics_process(delta: float) -> void:
	# 1. 중력 적용 (공중에 있는 경우)
	if not is_on_floor():
		velocity.y += gravity * GRAVITY_MULTIPLIER * delta

	# 2. 피격 경직(Hitstun) 상태 처리
	if hitstun_timer > 0.0:
		hitstun_timer -= delta
		
		# 경직 중에는 넉백 속도가 지배적이며, 사용자의 이동 입력을 무시합니다.
		# 지상에 닿아있다면 마찰력을 적용하여 넉백의 수평 속도를 줄여줍니다.
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, knockback_decay * 2.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, knockback_decay * delta)
	else:
		# 경직 상태가 아닐 때: 일반적인 키보드/패드 입력 이동 처리
		_handle_normal_movement()

	# 3. 고도 4 물리 이동 실행
	move_and_slide()

## 일반 플레이어 수동 이동 처리
func _handle_normal_movement() -> void:
	# A, D 키 또는 방향키 지원을 위해 기본 매핑 확인 및 키 감지 구현
	var direction := 0.0
	
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction += 1.0

	# 좌우 이동 속도 할당
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 0.2) # 부드럽게 감속

	# 점프 감지 (Space 키 또는 위쪽 방향키)
	if (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP)) and is_on_floor():
		velocity.y = JUMP_VELOCITY

## 외부 데미지 및 HP 비례 제곱식 넉백 적용 함수
## damage_amount: 입힐 피해량
## knockback_direction: 넉백을 가할 방향 벡터 (정규화된 상태 권장)
## base_knockback_force: 공격의 기본 넉백 강도
func apply_damage_and_knockback(damage_amount: float, knockback_direction: Vector2, base_knockback_force: float) -> void:
	# 1. 체력 감산 (최소 0)
	current_hp = max(0.0, current_hp - damage_amount)
	print("[Player 피격] 데미지: ", damage_amount, " | 남은 HP: ", current_hp)
	
	# 2. HP 비례 제곱식 넉백 승수(Multiplier) 계산
	# GDD: "남은 HP 수치에 가감 없이 반비례하여 피격 시 밀려나는 물리 넉백 계수가 제곱식으로 증가"
	# 공식: (max_hp / max(current_hp, min_hp_for_calc)) ^ 2
	var hp_ratio = max_hp / max(current_hp, min_hp_for_calc)
	var knockback_multiplier = pow(hp_ratio, 2.0)
	
	# 안전 상한선(max_knockback_multiplier) 적용
	knockback_multiplier = min(knockback_multiplier, max_knockback_multiplier)
	
	# 3. 최종 속도 및 경직 시간 설정
	var final_knockback_velocity = knockback_direction.normalized() * base_knockback_force * knockback_multiplier
	velocity = final_knockback_velocity
	
	# 경직 시간도 넉백 크기에 비례하여 증가하도록 유기적 조정
	hitstun_timer = base_hitstun_duration * knockback_multiplier
	
	print("[Player 넉백] 승수: %.2f 배 | 적용 넉백 속도: %s | 경직 시간: %.3f 초" % [knockback_multiplier, str(final_knockback_velocity), hitstun_timer])
	
	# 4. 체력이 0%에 도달했는지 확인하여 탈락 처리
	if current_hp <= 0.0:
		print("[Player 탈락] 체력이 0%에 도달하여 전장에서 정화 탈락되었습니다.")
		eliminated.emit()
