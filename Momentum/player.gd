extends CharacterBody3D

# [변수화] const를 var로 변경하여 업그레이드가 가능하게 함
var SPEED = 5.0
const CROUCH_SPEED = 2.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.005

# [수정] 발사 속도, 공격력 변수화
var shoot_interval_rate = 0.5 # 현재 공격 속도 딜레이
var damage = 20.0			  # 현재 공격력
const MAX_AMMO = 8

# [산탄총 설정]
const PELLET_COUNT = 5		# 한 번에 나가는 총알 개수
const SPREAD_ANGLE = 3.0	# 탄퍼짐 각도

# [핵심 수정] 총알 씬 변수 추가 (Godot 에디터에서 PlayerBullet.tscn 파일을 연결해야 합니다!)
@export var bullet_scene: PackedScene 

# [레벨업 시스템 상수]
const UPGRADE_MAX_HEALTH = "UPGRADE MAX HEALTH"
const UPGRADE_DAMAGE = "UPGRADE DAMAGE"
const UPGRADE_LIFESTEAL = "UPGRADE LIFESTEAL"
const UPGRADE_ATTACK_SPEED = "UPGRADE ATTACK SPEED"
const UPGRADE_MOVE_SPEED = "UPGRADE MOVE SPEED"

const ALL_UPGRADES = [
	UPGRADE_MAX_HEALTH,
	UPGRADE_DAMAGE,
	UPGRADE_LIFESTEAL,
	UPGRADE_ATTACK_SPEED,
	UPGRADE_MOVE_SPEED,
]
# [필수] 레벨업 UI 씬 경로 (사용자가 직접 LevelUpMenu.tscn 파일을 만들어야 함)
const LEVEL_UP_MENU_SCENE = preload("res://level_up_menu.tscn") # [수정] 주석 해제 및 경로 지정

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var default_height = 0.0

# [추가] 신규 스탯
var lifesteal_amount = 0.0 # 현재 흡혈량 (0.0 ~ 1.0)

# 발사 쿨타임 및 탄약 변수
var shoot_timer = 0.0
var current_ammo = MAX_AMMO

# 체력 시스템 변수
var max_health = 250
var current_health = max_health

# [추가] 레벨, 경험치, 점수 변수
var level = 1
var current_xp = 0
var max_xp = 100 # 다음 레벨까지 필요한 경험치 (예시)
var score = 0

# 노드 연결
@onready var camera = $Camera3D
@onready var anim_player = %AnimationPlayer
@onready var fire_point = $Camera3D/FirePoint 
@onready var hud = $UI_Layer/HUD 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_height = camera.position.y
	print("Ammo: ", current_ammo, " / HP: ", current_health)
	
	if hud:
		hud.init_health(max_health)
		hud.update_health(current_health, max_health)
		hud.update_ammo(current_ammo, MAX_AMMO)
		hud.update_level_xp(level, current_xp, max_xp)
		hud.update_score(score)
	
	if not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name):
	if anim_name == "reload":
		current_ammo = MAX_AMMO
		print("Reload Complete! Ammo: ", current_ammo)
		
		if hud:
			hud.update_ammo(current_ammo, MAX_AMMO)
			
		anim_player.play("stay")
	
	elif anim_name == "shoot":
		anim_player.play("stay")

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var current_speed = SPEED # [수정] var SPEED 사용
	
	if Input.is_action_pressed("crouch") and is_on_floor():
		current_speed = CROUCH_SPEED
		camera.position.y = lerp(camera.position.y, default_height - 0.7, delta * 10)
	else:
		camera.position.y = lerp(camera.position.y, default_height, delta * 10)

	var input_dir = Vector3()
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	var direction = (transform.basis * input_dir).normalized()

	if is_on_floor():
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = lerp(velocity.x, direction.x * current_speed, 0.1)
		velocity.z = lerp(velocity.z, direction.z * current_speed, 0.1)

	move_and_slide()

func _process(delta):
	if shoot_timer > 0:
		shoot_timer -= delta

	# 1. 수동 장전 (R키)
	if Input.is_action_just_pressed("reload"):
		if anim_player.current_animation != "reload" and current_ammo < MAX_AMMO:
			anim_player.play("reload")

	# 2. 발사 (마우스 꾹 누르면 연사)
	if Input.is_action_pressed("attack"):
		if anim_player.current_animation != "reload":
			if (anim_player.current_animation != "shoot" or not anim_player.is_playing()) and shoot_timer <= 0:
				if current_ammo > 0:
					anim_player.play("shoot")
					shoot_timer = shoot_interval_rate # [수정] var shoot_interval_rate 사용
					current_ammo -= 1
					
					# [핵심] 실제 산탄총 발사 함수 호출!
					shoot_shotgun()
					
					if hud:
						hud.update_ammo(current_ammo, MAX_AMMO)
					
					print("Bang! Ammo: ", current_ammo)
				else:
					anim_player.play("reload")
					
	if not anim_player.is_playing():
		if anim_player.current_animation != "stay":
			anim_player.play("stay")

# 산탄총 발사 함수 (고정 원형 패턴)
func shoot_shotgun():
	if not bullet_scene:
		return
		
	# [추가] 흡혈 로직: 발사 시 확률적으로 체력 회복 (간단 구현)
	if lifesteal_amount > 0.0:
		# 흡혈량에 비례하여 체력 회복
		var health_gain = damage * lifesteal_amount * 0.1 
		current_health = min(max_health, current_health + health_gain)
		if hud:
			hud.update_health(current_health, max_health)
	
	# 발사 기준점(FirePoint 또는 카메라)의 Transform 가져오기
	var base_transform = camera.global_transform
	if fire_point:
		base_transform = fire_point.global_transform

	var angle_step = TAU / PELLET_COUNT
	var spread_ratio = tan(deg_to_rad(SPREAD_ANGLE))

	# 5발 반복 생성
	for i in range(PELLET_COUNT):
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		
		# [수정] 총알 데미지를 플레이어 스탯으로 설정 (PlayerBullet.gd에서 damage 변수를 export해야 함)
		if bullet.has_method("set_damage"):
			bullet.set_damage(damage)
			
		var current_angle = i * angle_step
		var local_x = cos(current_angle) * spread_ratio
		var local_y = sin(current_angle) * spread_ratio
		
		var final_direction = -base_transform.basis.z
		final_direction += base_transform.basis.x * local_x
		final_direction += base_transform.basis.y * local_y
		
		final_direction = final_direction.normalized()

		bullet.global_position = base_transform.origin
		bullet.look_at(bullet.global_position + final_direction, base_transform.basis.y)

# 데미지 받는 함수 (적군이나 DeathZone이 호출함)
func take_damage(amount):
	current_health -= amount
	print("Ouch! HP: ", current_health)
	
	if hud:
		hud.update_health(current_health, max_health)
	
	if current_health <= 0:
		die()

# [수정] 레벨업 로직에 메뉴 표시 기능 추가
func on_enemy_killed(xp_amount: int, score_amount: int):
	current_xp += xp_amount
	score += score_amount
	
	# 레벨업 체크
	if current_xp >= max_xp:
		current_xp -= max_xp
		level += 1
		max_xp = int(max_xp * 1.2) # 다음 레벨 필요 경험치 증가
		
		# [핵심] 레벨업 시 게임 일시정지 및 선택지 표시
		print("Level Up! Level: ", level)
		show_level_up_menu()
		
	# UI 업데이트
	if hud:
		hud.update_level_xp(level, current_xp, max_xp)
		hud.update_score(score)

# [새 함수] 레벨업 메뉴 표시 및 게임 일시정지
func show_level_up_menu():
	# 게임 일시 정지
	get_tree().paused = true
	
	# 선택지 3개 가져오기
	var choices = get_unique_upgrades(3)
	
	# [TODO: UI 인스턴스화 및 표시]
	if LEVEL_UP_MENU_SCENE and hud:
		var menu = LEVEL_UP_MENU_SCENE.instantiate()
		
		# [수정] HUD의 부모 노드(CanvasLayer)에 추가
		hud.get_parent().add_child(menu) 
		
		# set_choices 호출 및 시그널 연결 (LevelUpMenu.gd 필요)
		if menu.has_method("set_choices"):
			menu.set_choices(choices)
		
		if menu.has_signal("upgrade_selected"):
			menu.upgrade_selected.connect(apply_upgrade)
	else:
		# 임시 출력 (UI 로직 구현 필요)
		print("--- LevelUpMenu 씬이 로드되지 않았거나 HUD 노드를 찾을 수 없습니다. ---")
		print("1: ", choices[0])
		print("2: ", choices[1])
		print("3: ", choices[2])
		# UI 없으므로 게임 일시정지 해제 (디버그용)
		get_tree().paused = false 


# [새 함수] 고유한 업그레이드 선택지 N개 가져오기
func get_unique_upgrades(count: int) -> Array:
	var upgrade_pool = ALL_UPGRADES.duplicate()
	upgrade_pool.shuffle()
	return upgrade_pool.slice(0, min(count, upgrade_pool.size()))

# [새 함수] 업그레이드 선택 후 적용 (UI 버튼 클릭 시 호출될 함수)
# 이 함수는 LevelUpMenu UI에서 시그널로 연결되어야 합니다.
func apply_upgrade(upgrade_name: String):
	# 게임 재개
	get_tree().paused = false
	
	# 마우스 다시 잠금
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	
	print("--- 업그레이드 적용: ", upgrade_name, " ---")
	
	match upgrade_name:
		UPGRADE_MAX_HEALTH:
			max_health += 50
			current_health = max_health 
			if hud: hud.init_health(max_health)
			print("최대 체력이 50 증가했습니다.")
			
		UPGRADE_DAMAGE:
			damage += 5.0 # 공격력 5 증가
			print("공격 데미지가 5 증가했습니다. 현재 공격력: ", damage)
			
		UPGRADE_LIFESTEAL:
			lifesteal_amount = min(lifesteal_amount + 0.05, 0.5) # 5% 증가, 최대 50%
			print("흡혈량이 5% 증가했습니다. 현재: ", lifesteal_amount * 100, "%")
			
		UPGRADE_ATTACK_SPEED:
			shoot_interval_rate = max(shoot_interval_rate - 0.05, 0.1) # 0.05초 감소, 최소 0.1초
			print("공격 속도가 빨라졌습니다. 딜레이: ", shoot_interval_rate)
			
		UPGRADE_MOVE_SPEED:
			SPEED += 1.0 # 이동 속도 1.0 증가
			print("이동 속도가 1.0 증가했습니다. 현재 속도: ", SPEED)

	# UI 업데이트
	if hud:
		hud.update_health(current_health, max_health)
		hud.update_level_xp(level, current_xp, max_xp)

func die():
	print("Game Over!")
	get_tree().reload_current_scene()
