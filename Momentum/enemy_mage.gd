extends Enemy

@onready var player = get_tree().get_first_node_in_group("player")

# [필수] 인스펙터에서 Fireball.tscn 연결
@export var fireball_scene: PackedScene 
# [필수] 지팡이 끝 Marker3D 노드 연결 (경로 확인!)
@onready var fire_point = $Rig_Medium/Skeleton3D/BoneAttachment3D/Skeleton_Staff2/FirePoint

var attack_range = 10.0 
var is_attacking = false
var is_spawning = true

func _init():
	health = 150 # 워리어는 체력 100으로 시작
	speed = 3.5  # 속도도 다르게 설정 가능

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
		
		if dist > attack_range and not is_attacking:
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			look_at(player.global_position, Vector3.UP)
			
			if anim_player.current_animation != "walk":
				anim_player.play("walk")
		
		elif dist <= attack_range:
			velocity.x = 0
			velocity.z = 0
			look_at(player.global_position, Vector3.UP)
			
			if not is_attacking:
				attack()
				
	move_and_slide()

func attack():
	is_attacking = true
	anim_player.play("attack")
	
	await get_tree().create_timer(0.5).timeout 
	shoot_fireball()
	
	await anim_player.animation_finished
	is_attacking = false
	
	if health > 0:
		anim_player.play("idle")

func shoot_fireball():
	if fireball_scene and fire_point:
		var fireball = fireball_scene.instantiate()
		get_parent().add_child(fireball)
		
		fireball.global_position = fire_point.global_position
		fireball.look_at(player.global_position, Vector3.UP)
