class_name Enemy extends CharacterBody3D

# [공통 변수]
@export var health: int = 10 
# [추가] 모델이 뒤를 보고 있다면 이 옵션을 켜세요! (기본값: false)
@export var flip_model: bool = false

var speed = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dead = false
var is_hit = false # 피격 상태

# [애니메이션 플레이어 자동 연결]
@onready var anim_player: AnimationPlayer = $AnimationPlayer 

func _ready():
	if not anim_player:
		for child in get_children():
			if child is AnimationPlayer:
				anim_player = child
				break
			for grandchild in child.get_children():
				if grandchild is AnimationPlayer:
					anim_player = grandchild
					break

func _physics_process(delta):
	if is_dead:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# 피격 중이 아닐 때만 이동
	if not is_hit:
		move_and_slide()
	else:
		# 피격 중에는 이동 멈춤
		velocity.x = 0
		velocity.z = 0
		move_and_slide()

# [공통] 데미지 입는 함수
func take_damage(amount, is_headshot: bool = false):
	if is_dead: return
	
	health -= amount
	
	if health <= 0:
		die(is_headshot)
	else:
		if anim_player and anim_player.has_animation("hit"):
			anim_player.play("hit")
			await anim_player.animation_finished
		else:
			await get_tree().create_timer(0.2).timeout
			
		is_hit = false

# [공통] 사망 함수
func die(is_headshot: bool = false):
	is_dead = true
	velocity = Vector3.ZERO 
	
	for child in find_children("*", "CollisionShape3D"):
		child.set_deferred("disabled", true)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_enemy_killed"):
		var score_reward = 10 
		if is_headshot:
			score_reward = 15 
			
		player.on_enemy_killed(20, score_reward)
	
	if anim_player and anim_player.has_animation("death"):
		anim_player.play("death")
		await anim_player.animation_finished
	
	queue_free()

# [공통 이동 및 바라보기 함수]
func move_towards_point(target_position: Vector3, _delta: float):
	var direction = (target_position - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	# [핵심] 바라보기 로직
	var look_target = Vector3(target_position.x, global_position.y, target_position.z)
	
	if global_position.distance_squared_to(look_target) > 0.001:
		look_at(look_target, Vector3.UP)
		
		# [수정] flip_model 값에 따라 회전 적용
		# 모델이 기본적으로 뒤를 보고 있다면(flip_model = true), 180도 돌려줍니다.
		if flip_model:
			rotate_y(PI)
