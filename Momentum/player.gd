extends CharacterBody3D

const SPEED = 5.0
const CROUCH_SPEED = 2.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.005

# [공격 설정]
# 발사 간격 (0.5초마다 발사)
const SHOOT_INTERVAL = 0.5
# 최대 총알 수
const MAX_AMMO = 8

# [산탄총 설정]
const PELLET_COUNT = 5     # 한 번에 나가는 총알 개수
const SPREAD_ANGLE = 3.0   # 탄퍼짐 각도

# [추가] 인스펙터에서 PlayerBullet.tscn 연결 필수!
@export var bullet_scene: PackedScene 

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var default_height = 0.0

# 발사 쿨타임 및 탄약 변수
var shoot_timer = 0.0
var current_ammo = MAX_AMMO

# [추가] 체력 시스템 변수
var max_health = 250
var current_health = max_health

@onready var camera = $Camera3D
@onready var anim_player = %AnimationPlayer
# [추가] 총알 발사 위치 (Marker3D) 연결 (없으면 카메라 위치 사용)
@onready var fire_point = $Camera3D/FirePoint

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_height = camera.position.y
	print("Ammo: ", current_ammo, " / HP: ", current_health)
	
	# 애니메이션 종료 시그널 연결 (재장전 완료 감지용)
	if not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)

# 애니메이션 종료 시 자동 호출되는 함수
func _on_animation_finished(anim_name):
	# 재장전 완료 시 탄약 충전
	if anim_name == "reload":
		current_ammo = MAX_AMMO
		print("Reload Complete! Ammo: ", current_ammo)
		anim_player.play("stay") # 대기 상태로
	
	# 사격 완료 시 대기 상태로
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

	var current_speed = SPEED
	# 바닥에 있을 때만 앉기 가능
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
		# 재장전 중이 아닐 때만
		if anim_player.current_animation != "reload":
			# 쏠 준비 됨 (shoot이 아니거나, 끝났을 때) + 딜레이 끝남
			if (anim_player.current_animation != "shoot" or not anim_player.is_playing()) and shoot_timer <= 0:
				if current_ammo > 0:
					# 발사 애니메이션
					anim_player.play("shoot")
					shoot_timer = SHOOT_INTERVAL
					current_ammo -= 1
					
					# [핵심] 실제 총알 발사 함수 호출!
					shoot_shotgun()
					
					print("Bang! Ammo: ", current_ammo)
				else:
					# 총알이 0발일 때 클릭하면 재장전 시작
					anim_player.play("reload")
					
	# 애니메이션 상태 관리 (아무것도 안할 때 stay 재생)
	if not anim_player.is_playing():
		if anim_player.current_animation != "stay":
			anim_player.play("stay")

# [추가] 산탄총 발사 함수 (고정 원형 패턴)
func shoot_shotgun():
	if not bullet_scene:
		return
		
	# 발사 기준점(FirePoint 또는 카메라)의 Transform 가져오기
	var base_transform = camera.global_transform
	if fire_point:
		base_transform = fire_point.global_transform

	# 펠릿 사이의 각도 간격 계산 (360도 / 5발)
	var angle_step = TAU / PELLET_COUNT
	
	# 탄퍼짐 각도를 거리 비율로 변환
	var spread_ratio = tan(deg_to_rad(SPREAD_ANGLE))

	# 5발 반복 생성
	for i in range(PELLET_COUNT):
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		
		# 현재 총알의 회전 각도 계산
		var current_angle = i * angle_step
		
		# 로컬 XY 평면에서의 원형 오프셋 계산
		var local_x = cos(current_angle) * spread_ratio
		var local_y = sin(current_angle) * spread_ratio
		
		# 최종 발사 방향 벡터 계산
		var final_direction = -base_transform.basis.z
		final_direction += base_transform.basis.x * local_x
		final_direction += base_transform.basis.y * local_y
		
		# 방향 벡터 정규화
		final_direction = final_direction.normalized()

		# 총알 위치 설정
		bullet.global_position = base_transform.origin
		
		# 총알이 계산된 최종 방향을 바라보도록 회전 설정
		bullet.look_at(bullet.global_position + final_direction, base_transform.basis.y)

# [추가] 데미지 받는 함수 (적군이나 DeathZone이 호출함)
func take_damage(amount):
	current_health -= amount
	print("Ouch! HP: ", current_health)
	if current_health <= 0:
		die()

func die():
	print("Game Over!")
	# 게임 재시작
	get_tree().reload_current_scene()
