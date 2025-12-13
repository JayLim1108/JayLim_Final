extends Node3D

# ▼▼▼ 인스펙터 설정 ▼▼▼
# 스폰 시간 (초)
@export var spawn_times: Array[float] = [0.0, 10.0, 20.0, 30.0]
# 스폰 적군 씬
@export var spawn_enemies: Array[PackedScene]
# 플레이어 (바라보기용)
@export var player: Node3D
# [추가] 적군 스폰 포인트들이 모여있는 부모 노드 (SpawnPoints)
@export var spawn_points_parent: Node3D 

# 플레이어가 스폰될 위치 (Marker3D 등)
@export var player_spawn_point: Node3D

const GAME_DURATION = 600.0
const START_INTERVAL = 10.0 # 초기에는 천천히 나옵니다.
const END_INTERVAL = 5.0   # 후반에도 너무 빠르지 않게 조절 (한 번에 많이 나오므로)

var time_elapsed = 0.0
var spawn_timer = 0.0
var current_interval = START_INTERVAL

var available_enemies: Array[PackedScene] = []
var next_unlock_index = 0
var spawn_markers: Array[Node] = []

func _ready():
	if player and player_spawn_point:
		player.global_position = player_spawn_point.global_position
		# player.global_rotation = player_spawn_point.global_rotation

	if spawn_points_parent:
		spawn_markers = spawn_points_parent.get_children()
		print("적군 스폰 포인트 개수: ", spawn_markers.size())
	else:
		print("경고: 인스펙터에서 Spawn Points Parent를 연결해주세요!")

func _process(delta):
	time_elapsed += delta
	
	check_unlock_enemies()
	
	var t = clamp(time_elapsed / GAME_DURATION, 0.0, 1.0)
	current_interval = lerp(START_INTERVAL, END_INTERVAL, t)
	
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_wave()
		spawn_timer = current_interval

func check_unlock_enemies():
	while next_unlock_index < spawn_times.size() and time_elapsed >= spawn_times[next_unlock_index]:
		if next_unlock_index < spawn_enemies.size():
			var new_enemy = spawn_enemies[next_unlock_index]
			if new_enemy and not available_enemies.has(new_enemy):
				available_enemies.append(new_enemy)
				print("새로운 적군 등장! (시간: ", spawn_times[next_unlock_index], "초)")
		
		next_unlock_index += 1

func spawn_wave():
	if not player or available_enemies.is_empty() or spawn_markers.is_empty():
		return
		
	print("웨이브 시작! 주기: ", snapped(current_interval, 0.1), "초")
	
	# [수정] 해금된 모든 적 종류에 대해 반복
	for enemy_scene in available_enemies:
		# [수정] 모든 마커에서 각각 한 마리씩 생성
		for marker in spawn_markers:
			spawn_one_enemy_at_marker(enemy_scene, marker)

func spawn_one_enemy_at_marker(enemy_scene, marker):
	var enemy = enemy_scene.instantiate()
	var spawn_pos = marker.global_position
	
	# (선택) 마커 위치에서 아주 약간 랜덤하게 퍼지게 하기 (겹침 방지)
	var random_offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	spawn_pos += random_offset

	get_parent().add_child(enemy)
	
	spawn_pos.y += 0.1 
	enemy.global_position = spawn_pos
	
	# [수정] look_at 대신 atan2를 사용하여 Y축 회전 직접 계산 (오류 방지)
	if player:
		var target_pos = player.global_position
		var direction = target_pos - spawn_pos
		
		# 거리가 너무 가까우면 회전하지 않음
		if direction.length_squared() > 0.001:
			# atan2(x, z)를 사용하여 각도 계산 (Godot의 3D 회전은 Y축 기준)
			var angle = atan2(direction.x, direction.z)
			enemy.rotation.y = angle
	
	
	# 바닥보다 약간 위에서 스폰
	spawn_pos.y += 0.1
	enemy.global_position = spawn_pos
	
	# 플레이어 바라보기 (안전하게)
	if player:
		var target_pos = player.global_position
		target_pos.y = spawn_pos.y 
		
		if spawn_pos.distance_squared_to(target_pos) > 0.001:
			enemy.look_at(target_pos, Vector3.UP)
	
	enemy.rotate_object_local(Vector3.UP, PI)
