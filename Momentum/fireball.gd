extends Area3D

var speed = 10.0
var damage = 30
var direction = Vector3.FORWARD

func _ready():
	# 3초 뒤 자동 소멸 (메모리 낭비 방지)
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	# 로컬 좌표계의 전방(-Z)으로 이동
	# look_at()으로 방향을 돌렸으므로, 로컬 -Z축이 곧 발사 방향입니다.
	position += -transform.basis.z * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Player Hit!")
		# 나중에 플레이어에게 데미지 함수가 생기면 주석 해제하세요
		# if body.has_method("take_damage"):
		# 	body.take_damage(damage)
		queue_free() # 맞으면 사라짐
		
	# 벽(StaticBody)이나 맵(CSGShape)에 닿아도 사라짐
	elif body is StaticBody3D or body is CSGShape3D:
		queue_free()
