extends Area3D

# 플레이어 스폰 포인트 (Main 씬에서 직접 연결하거나 코드로 찾음)
@export var player_spawn_point: Node3D

func _ready():
	# 시그널이 에디터에서 연결되지 않았을 경우를 대비해 코드로 연결
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# 안전장치: 플레이어 스폰 포인트가 연결 안 되어 있으면 찾기
	if not player_spawn_point:
		# "PlayerSpawnPoint"라는 이름의 노드를 찾거나, 
		# EnemySpawner가 가지고 있는 player_spawn_point를 참조할 수도 있음
		player_spawn_point = get_tree().get_first_node_in_group("player_spawn_point")

func _on_body_entered(body):
	print("DeathZone에 무언가 닿음: ", body.name) # 디버그 출력
	
	# 1. 플레이어가 떨어진 경우
	if body.is_in_group("player") or body.name == "Player":
		print("플레이어 낙사 감지!")
		
		# 데미지 주기 (10)
		if body.has_method("take_damage"):
			body.take_damage(10)
		
		# 플레이어 리스폰 (강제 이동)
		respawn_player(body)
		
	# 2. 적군(Enemy)이 떨어진 경우
	elif body is Enemy or body.is_in_group("enemy"):
		print("적군 낙사! 삭제")
		body.queue_free()

func respawn_player(player_body):
	# 지정된 스폰 포인트로 이동
	if player_spawn_point:
		# 물리 엔진 간섭을 피하기 위해 velocity 초기화
		player_body.velocity = Vector3.ZERO
		player_body.global_position = player_spawn_point.global_position
		print("플레이어 리스폰 완료: ", player_spawn_point.global_position)
	else:
		# 스폰 포인트가 없으면 원점(0, 10, 0)으로 비상 리스폰
		print("오류: 플레이어 스폰 포인트를 찾을 수 없습니다! 원점으로 이동합니다.")
		player_body.velocity = Vector3.ZERO
		player_body.global_position = Vector3(0, 10, 0)
