extends Enemy

@onready var anim_player_warrior = $AnimationPlayer
@onready var player = get_tree().get_first_node_in_group("player")

# [경로 확인] 무기 히트박스 경로. (미니언은 이 경로가 없어도 괜찮습니다.)
@onready var weapon_hitbox = get_node_or_null("Rig_Medium/Skeleton3D/BoneAttachment3D/Sword/WeaponHitbox")

var attack_range = 1.5
var is_attacking = false
var is_spawning = true # 스폰 중인지 확인하는 변수

func _ready():
	# 부모 클래스(Enemy)의 _ready() 호출 (필수)
	super()
	
	# 무기 히트박스 초기화 (워리어만 해당)
	if weapon_hitbox:
		weapon_hitbox.monitoring = false
		if not weapon_hitbox.body_entered.is_connected(_on_weapon_hit):
			weapon_hitbox.body_entered.connect(_on_weapon_hit)
	
	# 1. 스폰 애니메이션 재생
	if anim_player_warrior and anim_player_warrior.has_animation("spawn"):
		anim_player_warrior.play("spawn")
		await anim_player_warrior.animation_finished
	
	# 2. 스폰 완료 후 대기 상태로 전환
	is_spawning = false
	if anim_player_warrior:
		anim_player_warrior.play("idle")

func _physics_process(delta):
	# 부모(Enemy)의 중력 로직 실행
	super(delta)
	
	# 스폰 중이거나 죽었으면 움직이지 않음
	if is_spawning or health <= 0:
		return
	
	if player and health > 0:
		var dist = global_position.distance_to(player.global_position)
		
		# 1. 추격 (공격 사거리 밖이고 공격 중이 아닐 때)
		if dist > attack_range and not is_attacking:
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			# 플레이어 바라보기
			look_at(player.global_position, Vector3.UP)
			
			# 걷기 애니메이션 재생
			if anim_player_warrior and anim_player_warrior.current_animation != "walking":
				anim_player_warrior.play("walking")
				
		# 2. 공격 (공격 사거리 안)
		elif dist <= attack_range:
			velocity.x = 0
			velocity.z = 0
			
			if not is_attacking:
				attack()
				
	else:
		# 플레이어가 없거나 죽었으면 멈춤
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func attack():
	is_attacking = true
	if anim_player_warrior:
		anim_player_warrior.play("attack")
	
	# 공격 시작 시 판정 켜기 (워리어)
	if weapon_hitbox:
		weapon_hitbox.monitoring = true
	
	# 애니메이션 끝날 때까지 대기
	if anim_player_warrior:
		await anim_player_warrior.animation_finished
	
	# 공격 종료 시 판정 끄기
	if weapon_hitbox:
		weapon_hitbox.monitoring = false
	
	is_attacking = false
	
	# 살아있다면 다시 대기 상태로
	if health > 0 and anim_player_warrior:
		anim_player_warrior.play("idle")

# 워리어 무기 충돌 처리
func _on_weapon_hit(body):
	if body.is_in_group("player"):
		print("플레이어를 베었다!")
		if body.has_method("take_damage"):
			body.take_damage(15) # 워리어 데미지
