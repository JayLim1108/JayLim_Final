extends Node3D

# ▼▼▼ 인스펙터에서 설정하기 쉬운 배열 방식 ▼▼▼
# 스폰 시간 (초): 작은 숫자부터 순서대로 입력하세요 (예: 0, 5, 60)
@export var spawn_times: Array[float] = [0.0, 5.0, 60.0]
# 스폰 적군 씬: 위 시간과 순서를 맞춰서 연결하세요 (예: 미니언, 미니언, 워리어)
@export var spawn_enemies: Array[PackedScene]

@export var player: Node3D

const GAME_DURATION = 600.0
const START_INTERVAL = 10.0
const END_INTERVAL = 2.0
const SPAWN_COUNT_PER_TYPE = 5 # 종류당 소환 개수
const SPAWN_RADIUS_MIN = 10.0
const SPAWN_RADIUS_MAX = 20.0

var time_elapsed = 0.0
var spawn_timer = 0.0
var current_interval = START_INTERVAL

# 현재 등장 가능한 적군 목록 (시간이 지나면 추가됨)
var available_enemies: Array[PackedScene] = []
# 이미 해금된 인덱스를 추적
var next_unlock_index = 0

func _process(delta):
	time_elapsed += delta
	
	# 시간이 되면 새로운 적군 해금!
	check_unlock_enemies()
	
	# 게임 진행도에 따라 스폰 주기 조절 (점점 빨라짐)
	var t = clamp(time_elapsed / GAME_DURATION, 0.0, 1.0)
	current_interval = lerp(START_INTERVAL, END_INTERVAL, t)
	
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_wave()
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
		
	print("웨이브 시작! 주기: ", snapped(current_interval, 0.1), "초")
	
	# 해금된 모든 적 종류에 대해 반복
	for enemy_scene in available_enemies:
		# 종류당 5마리씩 생성
		for i in range(SPAWN_COUNT_PER_TYPE):
			spawn_one_enemy(enemy_scene)

func spawn_one_enemy(enemy_scene):
	var enemy = enemy_scene.instantiate()
	
	# 안전한 스폰 위치 찾기 (최대 10번 시도)
	var spawn_pos = Vector3.ZERO
	var valid_spawn = false
	
	for i in range(10):
		var angle = randf() * PI * 2
		var distance = randf_range(SPAWN_RADIUS_MIN, SPAWN_RADIUS_MAX)
		var offset = Vector3(cos(angle), 0, sin(angle)) * distance
		var potential_pos = player.global_position + offset
		
		# 위에서 아래로 레이캐스트를 쏴서 바닥 확인
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(potential_pos + Vector3(0, 50, 0), potential_pos + Vector3(0, -50, 0))
		var result = space_state.intersect_ray(query)
		
		if result:
			# 충돌한 물체가 바닥(StaticBody3D)인지 확인
			if result.collider is StaticBody3D:
				spawn_pos = result.position
				valid_spawn = true
				break
	
	if valid_spawn:
		get_parent().add_child(enemy)
		
		# [수정] 바닥보다 약간 위에서 스폰되도록 조정 (바닥에 묻히지 않게)
		# 캐릭터의 발바닥 위치(Origin)가 바닥에 닿아야 합니다.
		spawn_pos.y += 0.1 
		enemy.global_position = spawn_pos
		
		# 플레이어 바라보기 (Y축 기준)
		enemy.look_at(player.global_position, Vector3.UP)
		# 만약 모델이 뒤집혀 있다면 아래 줄의 주석을 해제하세요.
		# enemy.rotate_object_local(Vector3.UP, PI) 
		
	else:
		print("유효한 스폰 위치를 찾지 못했습니다.")
		enemy.queue_free()
