extends Enemy

@onready var player = get_tree().get_first_node_in_group("player")

# [필수] 인스펙터에서 Fireball.tscn 연결
@export var fireball_scene: PackedScene 
# [필수] 지팡이 끝 Marker3D 노드 연결 (경로 확인!)
@onready var fire_point = get_node_or_null("Rig_Medium/Skeleton3D/BoneAttachment3D/Staff/FirePoint")

var attack_range = 20.0 # 원거리 공격 사거리
var is_attacking = false
var is_spawning = true

func _ready():
	# 부모 클래스의 _ready() 호출
	super()
	
	if anim_player and anim_player.has_animation("spawn"):
		anim_player.play("spawn")
		await anim_player.animation_finished
	
	is_spawning = false
	if anim_player:
		anim_player.play("idle")

func _physics_process(delta):
	# 부모의 중력 로직 실행
	super(delta)
	
	if is_spawning or health <= 0:
		return

	if player:
		var dist = global_position.distance_to(player.global_position)
		
		# [중요] 플레이어 바라보기 (Y축 고정)
		var look_target = player.global_position
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)
		
		# [수정] 모델이 뒤를 보고 있다면 180도 회전 (필요시 주석 해제)
		# rotate_y(PI) 

		# 1. 추격 (사거리 밖)
		if dist > attack_range and not is_attacking:
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			if anim_player and anim_player.current_animation != "walk":
				anim_player.play("walk")
		
		# 2. 공격 (사거리 안)
		elif dist <= attack_range:
			velocity.x = 0
			velocity.z = 0
			
			# 공격할 때도 플레이어를 쳐다봐야 함
			var look_target_attack = player.global_position
			look_target_attack.y = global_position.y
			look_at(look_target_attack, Vector3.UP)
			# rotate_y(PI) # 필요시 해제
			
			if not is_attacking:
				attack()
				
	else:
		velocity.x = 0
		velocity.z = 0
			
	move_and_slide()

func attack():
	is_attacking = true
	if anim_player:
		anim_player.play("attack")
	
	# 애니메이션 타이밍에 맞춰 발사 (예: 0.5초 뒤)
	await get_tree().create_timer(0.5).timeout 
	shoot_fireball()
	
	if anim_player:
		await anim_player.animation_finished
	
	is_attacking = false
	
	if health > 0 and anim_player:
		anim_player.play("idle")

func shoot_fireball():
	if fireball_scene:
		var fireball = fireball_scene.instantiate()
		get_parent().add_child(fireball) # 씬(Main)에 추가
		
		# 발사 위치 및 방향 설정
		if fire_point:
			fireball.global_position = fire_point.global_position
			# 플레이어 가슴 높이 정도를 조준
			fireball.look_at(player.global_position + Vector3(0, 1.0, 0), Vector3.UP)
		else:
			# FirePoint가 없으면 몸통에서 발사 (임시)
			fireball.global_position = global_position + Vector3(0, 1.0, 0)
			fireball.look_at(player.global_position + Vector3(0, 1.0, 0), Vector3.UP)
