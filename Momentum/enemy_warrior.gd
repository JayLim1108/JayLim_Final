extends Enemy

@onready var anim_player_minion = $AnimationPlayer
@onready var player = get_tree().get_first_node_in_group("player")

# [수정] 미니언의 공격 범위 (팔이 짧으므로 워리어보다 짧게 설정)
@export var attack_area: Area3D

var attack_range = 1.2
var is_attacking = false
var is_spawning = true

func _ready():
	# 부모 클래스의 _ready() 호출
	super()
	
	# 공격 범위(AttackArea) 설정 초기화
	if attack_area:
		attack_area.monitoring = false
		if not attack_area.body_entered.is_connected(_on_attack_hit):
			attack_area.body_entered.connect(_on_attack_hit)
	
	# 스폰 애니메이션 재생
	if anim_player_minion and anim_player_minion.has_animation("spawn"):
		anim_player_minion.play("spawn")
		await anim_player_minion.animation_finished
	
	is_spawning = false
	if anim_player_minion:
		anim_player_minion.play("idle")

func _physics_process(delta):
	# 부모(Enemy)의 중력 로직 실행
	super(delta)
	
	# 스폰 중이거나 죽었으면 움직이지 않음
	if is_spawning or health <= 0:
		return

	if player and health > 0:
		var dist = global_position.distance_to(player.global_position)

		# 1. 공격 사거리 밖이고, 공격 중이 아닐 때 -> 추격
		if dist > attack_range and not is_attacking:
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			# [수정] 플레이어를 바라보게 한 뒤, 180도 회전하여 앞을 보게 함
			look_at(player.global_position, Vector3.UP)
			rotate_y(PI) # 모델이 뒤를 보고 있을 때 180도 회전
			
			if anim_player_minion and anim_player_minion.current_animation != "walking":
				anim_player_minion.play("walking")
				
		# 2. 공격 사거리 안이고, 공격 중이 아닐 때 -> 공격 시작
		elif dist <= attack_range:
			velocity.x = 0
			velocity.z = 0
			
			# 공격할 때도 플레이어를 바라봐야 함 (180도 회전 포함)
			look_at(player.global_position, Vector3.UP)
			rotate_y(PI) 
			
			if not is_attacking:
				attack()
			
	else:
		velocity.x = 0
		velocity.z = 0
			
	move_and_slide()

func attack():
	is_attacking = true
	if anim_player_minion:
		anim_player_minion.play("attack")
	
	# 공격 시작 시 판정 켜기
	if attack_area:
		attack_area.monitoring = true
	
	# 애니메이션 끝날 때까지 대기
	if anim_player_minion:
		await anim_player_minion.animation_finished
	
	# 공격 종료 시 판정 끄기
	if attack_area:
		attack_area.monitoring = false
	
	is_attacking = false
	
	# 살아있다면 다시 대기 상태로
	if health > 0 and anim_player_minion:
		anim_player_minion.play("idle")

# 공격 판정에 누군가 닿았을 때 실행되는 함수
func _on_attack_hit(body):
	if body.is_in_group("player"):
		print("미니언 공격 적중!")
		if body.has_method("take_damage"):
			body.take_damage(5) # 미니언 데미지 (예: 5)
