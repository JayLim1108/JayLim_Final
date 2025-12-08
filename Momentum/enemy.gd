class_name Enemy extends CharacterBody3D

# [공통 변수]
# 인스펙터에서 적군마다 다르게 설정할 수 있습니다.
@export var health: int = 10 
var speed = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dead = false

# [추가] 애니메이션 플레이어 연결
# 자식 노드에서 자동으로 찾습니다.
@onready var anim_player: AnimationPlayer = $AnimationPlayer 

func _ready():
	# 만약 AnimationPlayer가 바로 아래에 없고 모델 안에 있다면 자동으로 찾습니다.
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
	# 죽었으면 중력만 받고 움직이지 않음 (시체 추락)
	if is_dead:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# 공통: 중력 적용
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# 자식 클래스(Warrior, Minion 등)에서 velocity.x, velocity.z를 설정하면 여기서 이동합니다.
	move_and_slide()

# [공통] 데미지 입는 함수
func take_damage(amount):
	if is_dead: return
	
	health -= amount
	# print(name, " 체력: ", health) # 디버그용 출력
	
	if health <= 0:
		die()
	else:
		# 피격 모션이 있다면 재생
		if anim_player and anim_player.has_animation("hit"):
			anim_player.play("hit")

# [공통] 사망 함수
func die():
	is_dead = true
	velocity = Vector3.ZERO # 이동 멈춤 (중력은 계속 적용됨)
	
	# 충돌 끄기 (시체에 걸리지 않게)
	# 충돌체가 여러 개일 수 있으므로 find_children으로 찾아서 끕니다.
	for child in find_children("*", "CollisionShape3D"):
		child.disabled = true
	
	# 사망 애니메이션 재생
	if anim_player and anim_player.has_animation("death"):
		anim_player.play("death")
		await anim_player.animation_finished
	
	queue_free() # 씬에서 삭제
