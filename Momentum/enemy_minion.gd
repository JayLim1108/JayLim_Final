extends Enemy

@onready var anim_player_minion = $AnimationPlayer
# [중요] 그룹으로 플레이어 찾기
@onready var player = get_tree().get_first_node_in_group("player")

# [설정] 공격 판정 영역
@onready var attack_area = get_node_or_null("AttackArea")

var attack_range = 1.2
var is_attacking = false
var is_spawning = true

func _ready():
	super() # 부모(Enemy)의 설정 불러오기
	
	if attack_area:
		attack_area.monitoring = false
		if not attack_area.body_entered.is_connected(_on_attack_hit):
			attack_area.body_entered.connect(_on_attack_hit)
	
	if anim_player_minion and anim_player_minion.has_animation("spawn"):
		anim_player_minion.play("spawn")
		await anim_player_minion.animation_finished
	
	is_spawning = false
	if anim_player_minion:
		anim_player_minion.play("idle")

func _physics_process(delta):
	super(delta) # 중력 적용
	
	if is_spawning or health <= 0:
		return

	if player:
		var dist = global_position.distance_to(player.global_position)

		# ▼▼▼ [핵심 수정] 매 프레임마다 플레이어를 바라보게 함 ▼▼▼
		var look_target = player.global_position
		look_target.y = global_position.y # 내 높이와 같게 설정 (기울어짐 방지)
		
		look_at(look_target, Vector3.UP)
		rotate_y(PI) # 모델이 뒤를 보고 있다면 180도 회전 (필요 없다면 삭제)
		# ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

		# 1. 추격
		if dist > attack_range and not is_attacking:
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			if anim_player_minion and anim_player_minion.current_animation != "walking":
				anim_player_minion.play("walking")
				
		# 2. 공격
		elif dist <= attack_range:
			velocity.x = 0
			velocity.z = 0
			
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
	
	if attack_area:
		attack_area.monitoring = true
	
	if anim_player_minion:
		await anim_player_minion.animation_finished
	
	if attack_area:
		attack_area.monitoring = false
	
	is_attacking = false
	
	if health > 0 and anim_player_minion:
		anim_player_minion.play("idle")

func _on_attack_hit(body):
	if body.is_in_group("player"):
		# print("미니언 공격 적중!")
		if body.has_method("take_damage"):
			body.take_damage(5)
