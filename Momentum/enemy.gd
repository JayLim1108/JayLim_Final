class_name Enemy extends CharacterBody3D

@export var health: int = 10 
var speed = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dead = false

@onready var anim_player: AnimationPlayer = $AnimationPlayer 

# [추가] 네비게이션 에이전트 연결 (없으면 코드에서 생성하지 않고 경고 출력)
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

# 플레이어 참조 (모든 적군이 공유)
var player_target: Node3D = null

func _ready():
	# AnimationPlayer 찾기 (기존 로직)
	if not anim_player:
		for child in get_children():
			if child is AnimationPlayer:
				anim_player = child
				break
			for grandchild in child.get_children():
				if grandchild is AnimationPlayer:
					anim_player = grandchild
					break
	
	# 플레이어 찾기
	player_target = get_tree().get_first_node_in_group("player")
	
	# 네비게이션 설정 (중요: 첫 프레임에는 맵 동기화가 안 될 수 있으므로 대기)
	await get_tree().physics_frame
	if nav_agent:
		# 목표 지점 도달 허용 오차
		nav_agent.path_desired_distance = 1.0
		nav_agent.target_desired_distance = 1.0

func _physics_process(delta):
	if is_dead:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# 공통: 중력 적용
	if not is_on_floor():
		velocity.y -= gravity * delta

	# [수정] 네비게이션 이동 로직 (자식 클래스에서 호출하도록 변경하거나 여기서 처리)
	# 여기서는 자식 클래스가 move_to_target()을 호출하여 이동하도록 구조를 잡습니다.
	# 하지만 편의상 기본 이동 로직을 여기에 구현하고 자식에서 오버라이드 하지 않게 할 수도 있습니다.
	# 지금은 Warrior/Minion/Mage가 각자 이동 로직을 가지고 있으므로,
	# 각 자식 스크립트를 수정하는 것이 더 정확합니다.
	
	move_and_slide()

# [추가] 공통 이동 함수 (자식들이 사용)
# delta를 사용하지 않으므로 _delta로 이름 변경
func move_towards_point(target_position: Vector3, _delta: float):
	if not nav_agent:
		# 네비게이션이 없으면 기존 방식(직선 이동) 사용
		# 변수 이름을 target_direction으로 변경하여 중복 경고 방지
		var target_direction = (target_position - global_position).normalized()
		velocity.x = target_direction.x * speed
		velocity.z = target_direction.z * speed
		return

	# 1. 목표 지점 설정 (매 프레임 호출해도 되지만, 성능을 위해 타이머 사용 권장)
	nav_agent.target_position = target_position
	
	# 2. 다음 이동 지점 가져오기
	var next_path_position = nav_agent.get_next_path_position()
	
	# 3. 이동 방향 계산
	# 변수 이름을 path_direction으로 변경
	var path_direction = (next_path_position - global_position).normalized()
	
	# 4. 속도 적용
	velocity.x = path_direction.x * speed
	velocity.z = path_direction.z * speed
	
	# 5. 바라보기 (Y축 회전만)
	var look_target = Vector3(next_path_position.x, global_position.y, next_path_position.z)
	look_at(look_target, Vector3.UP)
	rotate_y(PI) # 모델이 뒤집혀 있다면
	
	# [추가] 장애물 점프 로직 (간단한 버전)
	# 만약 이동 중인데 벽에 막혀서 속도가 느려지면 점프 시도
	if is_on_wall() and is_on_floor():
		velocity.y = 4.0 # 점프 힘
