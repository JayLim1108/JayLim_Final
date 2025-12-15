extends Area3D

var speed = 20.0
var damage = 20

# [수정] 파티클 및 메쉬 참조 제거 (불필요)
# 만약 총알 자체의 MeshInstance3D나 CollisionShape3D를 제어해야 한다면 남겨두세요.
# 여기서는 단순히 충돌 후 사라지는 기능만 남깁니다.

func _ready():
	# 2초 뒤 자동 삭제 (안전장치)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	# 전방(-Z축)으로 이동
	position -= transform.basis.z * speed * delta

# [중요] CharacterBody3D (적군 본체)와 충돌 시
func _on_body_entered(body):
	# 적군(Enemy) 그룹에 속해 있는지 확인
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			# 적군에게 데미지 전달
			# (이펙트 처리는 Enemy.gd의 take_damage 함수 내부에서 처리)
			body.take_damage(damage) 
			queue_free() # 총알 삭제
	
	# 벽이나 바닥과 충돌했는지 확인
	elif body is StaticBody3D or body is CSGShape3D:
		queue_free() # 총알 삭제

# [중요] Area3D (적군 히트박스)와 충돌 시
func _on_area_entered(area):
	# 적군 히트박스인지 확인 (Hitbox.gd의 hit 함수가 있는지)
	if area.has_method("hit"):
		area.hit(damage)
		queue_free() # 총알 삭제
