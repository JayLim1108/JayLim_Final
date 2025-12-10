extends Node3D

# ▼▼▼ 인스펙터 설정 ▼▼▼
# 스폰 시간 (초)
@export var spawn_times: Array[float] = [0.0, 10.0, 20.0, 30.0]
# 스폰 적군 씬: 위 시간과 순서를 맞춰서 연결하세요 (예: 미니언, 워리어, 마법사, 레인저)
@export var spawn_enemies: Array[PackedScene]
# 플레이어 (바라보기용)
@export var player: Node3D
# [추가] 적군 스폰 포인트들이 모여있는 부모 노드 (SpawnPoints)
@export var spawn_points_parent: Node3D 

# 플레이어가 스폰될 위치 (Marker3D 등) - 사용하지 않는다면 비워두셔도 됩니다.
@export var player_spawn_point: Node3D

const GAME_DURATION = 600.0
const START_INTERVAL = 3.0 # 시작 스폰 주기 (3초마다 1마리)
const END_INTERVAL = 0.5   # 끝 스폰 주기 (0.5초마다 1마리 - 매우 빠름)

var time_elapsed = 0.0
var spawn_timer = 0.0
var current_interval = START_INTERVAL

# 현재 등장 가능한 적군 목록 (시간이 지나면 추가됨)
var available_enemies: Array[PackedScene] = []
var next_unlock_index = 0

# 적군 스폰 포인트 목록 (Marker3D들)
var spawn_markers: Array[Node] = []

func _ready():
	# 플레이어 스폰 위치 설정 (옵션)
	if player and player_spawn_point:
		player.global_position = player_spawn_point.global_position
		# player.global_rotation = player_spawn_point.global_rotation

	# 적군 스폰 포인트들을 미리 찾아둠
	if spawn_points_parent:
		spawn_markers = spawn_points_parent.get_children()
		print("적군 스폰 포인트 개수: ", spawn_markers.size())
	else:
		print("경고: 인스펙터에서 Spawn Points Parent를 연결해주세요!")

func _process(delta):
	time_elapsed += delta
	
	# 시간이 되면 새로운 적군 해금!
	check_unlock_enemies()
	
	# 게임 진행도에 따라 스폰 주기 조절 (점점 빨라짐)
	var t = clamp(time_elapsed / GAME_DURATION, 0.0, 1.0)
	current_interval = lerp(START_INTERVAL, END_INTERVAL, t)
	
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_wave() # 웨이브라기 보단 이제 한 마리씩 자주 나옴
		spawn_timer = current_interval

func check_unlock_enemies():
	# 아직 해금할 적이 남아있고, 시간이 되었다면?
	while next_unlock_index < spawn_times.size() and time_elapsed >= spawn_times[next_unlock_index]:
		# 짝꿍 적군 파일이 있는지 확인 (배열 크기 체크)
		if next_unlock_index < spawn_enemies.size():
			var new_enemy = spawn_enemies[next_unlock_index]
			if new_enemy and not available_enemies.has(new_enemy):
				available_enemies.append(new_enemy)
				print("새로운 적군 등장! (시간: ", spawn_times[next_unlock_index], "초)")
		
		next_unlock_index += 1

func spawn_wave():
	if not player or available_enemies.is_empty():
		return
		
	# 한 번에 한 마리씩만 소환 (종류는 랜덤)
	# 하지만 스폰 주기가 점점 빨라지므로 나중엔 엄청 많이 나옴
	spawn_one_enemy()

func spawn_one_enemy():
	# 해금된 적들 중 랜덤 선택
	var enemy_scene = available_enemies.pick_random()
	var enemy = enemy_scene.instantiate()
	var spawn_pos = Vector3.ZERO
	
	# 1. 스폰 마커가 있다면 그 중 하나 선택
	if not spawn_markers.is_empty():
		var random_marker = spawn_markers.pick_random()
		spawn_pos = random_marker.global_position
		
		# (선택) 마커 위치에서 약간 랜덤하게 퍼지게 하기 (겹침 방지)
		var random_offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
		spawn_pos += random_offset
		
	# 2. 스폰 마커가 없다면 현재 스포너 위치 사용 (비상용)
	else:
		spawn_pos = global_position
		var random_offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		spawn_pos += random_offset

	get_parent().add_child(enemy)
	
	# 바닥보다 약간 위에서 스폰
	spawn_pos.y += 0.1 
	enemy.global_position = spawn_pos
	
	# [수정] 안전한 look_at 처리 (오류 해결)
	if player:
		# Y축 높이를 맞춰서 바라보게 함 (기울어짐 방지)
		var target_pos = player.global_position
		target_pos.y = spawn_pos.y 
		
		# 거리가 너무 가까우면 look_at 실행 안 함 (오류 방지)
		if spawn_pos.distance_squared_to(target_pos) > 0.01:
			enemy.look_at(target_pos, Vector3.UP)
	
	# 모델이 뒤집혀 있다면 아래 주석 해제
	# enemy.rotate_object_local(Vector3.UP, PI)
