extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# 1. 플레이어가 떨어진 경우
	if body.is_in_group("player"):
		print("플레이어 낙사! 체력 -10 및 리스폰")
		
		# 데미지 주기 (Player 스크립트에 take_damage 함수가 있다고 가정)
		if body.has_method("take_damage"):
			body.take_damage(10)
		
		# 랜덤 리스폰
		respawn_body(body)
		
	# 2. 적군(Enemy)이 떨어진 경우
	elif body is Enemy:
		print("적군 낙사! 리스폰")
		# 데미지 없이 위치만 이동
		respawn_body(body)

# 공통 리스폰 함수
func respawn_body(body):
	# 'respawn_point' 그룹에 있는 모든 노드(Marker3D)를 가져옴
	var spawn_points = get_tree().get_nodes_in_group("respawn_point")
	
	if spawn_points.size() > 0:
		# 랜덤한 지점 하나 선택
		var random_point = spawn_points.pick_random()
		
		# 물리 엔진을 사용하는 바디(CharacterBody3D)는 global_position을 직접 바꾸면 안 될 수 있음.
		# 안전하게 이동시키기 위해 velocity를 초기화하고 위치를 변경.
		body.velocity = Vector3.ZERO
		body.global_position = random_point.global_position
	else:
		print("오류: 씬에 'respawn_point' 그룹을 가진 Marker3D가 없습니다!")
