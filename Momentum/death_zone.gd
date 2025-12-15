extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# 1. 플레이어가 떨어진 경우
	if body.is_in_group("player"):
		print("플레이어 낙사! 체력 -10 및 리스폰")
		
		if body.has_method("take_damage"):
			body.take_damage(10)
		
		# 플레이어 리스폰
		respawn_body(body)
		
	# 2. 적군(Enemy)이 떨어진 경우
	elif body is Enemy:
		print("적군 낙사! 리스폰")
		
		# [수정] 삭제(queue_free) 대신 리스폰(respawn_body) 호출!
		# body.queue_free()  <-- 이 줄을 삭제하거나 주석 처리했습니다.
		respawn_body(body)   # <-- 리스폰 함수 호출

# 공통 리스폰 함수
func respawn_body(body):
	# 'respawn_point' 그룹에 있는 모든 노드(Marker3D)를 가져옴
	var spawn_points = get_tree().get_nodes_in_group("respawn_point")
	
	if spawn_points.size() > 0:
		var random_point = spawn_points.pick_random()
		
		body.velocity = Vector3.ZERO
		# 리스폰 지점보다 약간 위에서 생성되도록 Y축 값을 더해줍니다.
		body.global_position = random_point.global_position + Vector3(0, 1.0, 0)
	else:
		print("오류: 씬에 'respawn_point' 그룹을 가진 Marker3D가 없습니다!")
