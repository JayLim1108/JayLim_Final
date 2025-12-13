class_name Enemy extends CharacterBody3D

# [공통 변수 설정]
# 인스펙터에서 적군 종류별로 체력을 다르게 설정할 수 있습니다.
@export var health: int = 10 
var speed = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dead = false

# [애니메이션 플레이어 자동 연결]
# 자식 노드나 모델 내부에서 자동으로 찾습니다.
@onready var anim_player: AnimationPlayer = $AnimationPlayer 

func _ready():
	# 만약 AnimationPlayer가 바로 아래에 없고 모델 안에 깊숙이 있다면 자동으로 찾습니다.
	if not anim_player:
		for child in get_children():
			if child is AnimationPlayer:
				anim_player = child
				break
			# 모델 노드 안쪽도 확인 (한 단계 더 깊이)
			for grandchild in child.get_children():
				if grandchild is AnimationPlayer:
					anim_player = grandchild
					break

func _physics_process(delta):
	# 죽었을 때는 중력만 받고 움직이지 않음 (시체 추락)
	if is_dead:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# [공통] 중력 적용
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# [중요] 자식 클래스(Warrior, Minion)에서 계산한 velocity로 실제 이동을 수행합니다.
	move_and_slide()

# [공통] 데미지 입는 함수 (플레이어 총알이 이 함수를 호출함)
func take_damage(amount):
	if is_dead: return
	
	health -= amount
	# print(name, " 체력: ", health) # 디버그용
	
	if health <= 0:
		die()
	else:
		# 피격 모션이 있다면 재생
		if anim_player and anim_player.has_animation("hit"):
			anim_player.play("hit")

# [공통] 사망 함수
func die():
	is_dead = true
	velocity = Vector3.ZERO # 이동 멈춤
	
	# 시체에 플레이어가 걸리지 않도록 충돌체 끄기
	for child in find_children("*", "CollisionShape3D"):
		child.disabled = true
	
	# 사망 애니메이션 재생
	if anim_player and anim_player.has_animation("death"):
		anim_player.play("death")
		await anim_player.animation_finished
	
	queue_free() # 씬에서 완전히 삭제
