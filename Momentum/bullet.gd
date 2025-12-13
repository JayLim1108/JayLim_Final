extends Area3D

var speed = 20.0
var damage = 20 


@onready var mesh = $MeshInstance3D # 총알 본체
@onready var collision = $CollisionShape3D # 충돌체

func _ready():
	# 2초 뒤 자동 삭제 (안전장치)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	# 전방(-Z축)으로 이동
	position -= transform.basis.z * speed * delta

# [중요] CharacterBody3D (몸통)와 충돌 시
func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
		hit_target() # [수정] 충돌 처리 함수 호출
	elif body is StaticBody3D or body is CSGShape3D:
		hit_target() # [수정] 충돌 처리 함수 호출

# [중요] Area3D (헤드샷 히트박스 등)와 충돌 시
func _on_area_entered(area):
	if area.has_method("hit"):
		area.hit(damage)
		hit_target() # [수정] 충돌 처리 함수 호출

func hit_target():
	create_hit_effect()
	
	queue_free() # 진짜 삭제

func create_hit_effect():
	# 여기에 피격 파티클 생성 코드 추가 가능
	# print("Hit!")
	pass
