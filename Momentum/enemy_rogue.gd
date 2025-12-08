extends Enemy

@onready var player = get_tree().get_first_node_in_group("player")

# [설정] 인스펙터에서 Arrow.tscn을 넣어주세요!
@export var arrow_scene: PackedScene 
# [설정] 화살이 발사될 위치 (크로스보우 끝)
@onready var fire_point = $Rig_Medium/Skeleton3D/BoneAttachment3D/Crossbow/FirePoint 
# [설정] 회전시킬 무기 또는 상체 노드 (BoneAttachment3D 또는 그 자식 무기 노드)
@onready var weapon_pivot = $Rig_Medium/Skeleton3D/BoneAttachment3D/Crossbow 

var attack_range = 15.0 
var is_attacking = false
var is_spawning = true

func _init():
	health = 150 # 워리어는 체력 100으로 시작
	speed = 5.0  # 속도도 다르게 설정 가능

func _ready():
	if anim_player.has_animation("spawn"):
		anim_player.play("spawn")
		await anim_player.animation_finished
	is_spawning = false
	anim_player.play("idle")

func _physics_process(delta):
	super(delta)
	
	if is_spawning or health <= 0:
		return

	if player:
		var dist = global_position.distance_to(player.global_position)
		
		# 1. 몸통 회전 (이동 방향 또는 플레이어 방향)
		# 이동 중에는 이동 방향을 보지만, 멈춰서 쏠 때는 플레이어를 봅니다.
		if not is_attacking:
			var target_pos = player.global_position
			target_pos.y = global_position.y # Y축 고정 (기울어짐 방지)
			look_at(target_pos, Vector3.UP)

		# 2. [핵심] 무기만 따로 플레이어 조준!
		# 애니메이션이 팔을 흔들어도, 무기는 플레이어를 계속 쳐다봅니다.
		if weapon_pivot:
			weapon_pivot.look_at(player.global_position, Vector3.UP)
			# 만약 무기가 뒤집힌다면 축을 수정해야 합니다. (예: rotate_object_local)
		
		# 3. 이동 및 공격 로직
		if dist > attack_range and not is_attacking:
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			if anim_player.current_animation != "walk":
				anim_player.play("walk")
				
		elif dist <= attack_range:
			velocity.x = 0
			velocity.z = 0
			
			if not is_attacking:
				attack()
				
	move_and_slide()

func attack():
	is_attacking = true
	anim_player.play("attack") # 활 쏘는 모션 재생
	
	# 애니메이션 특정 타이밍에 발사 (또는 0.5초 뒤)
	await get_tree().create_timer(0.5).timeout 
	shoot_arrow()
	
	await anim_player.animation_finished
	is_attacking = false
	
	if health > 0:
		anim_player.play("idle")

func shoot_arrow():
	if arrow_scene and fire_point:
		var arrow = arrow_scene.instantiate()
		get_parent().add_child(arrow)
		
		arrow.global_position = fire_point.global_position
		arrow.look_at(player.global_position, Vector3.UP)
