extends Control

@onready var health_container = $HealthBarContainer
@onready var ammo_label = $AmmoLabel
@onready var health_text_label = $HealthTextLabel

# [추가] 새로운 UI 요소 연결 (경로 확인 필수!)
# 이 노드들은 HUD.tscn 씬에 추가되어 있어야 합니다.
@onready var level_label = $LevelLabel
@onready var xp_bar = $XPBar # ProgressBar 노드여야 합니다.
@onready var score_label = $ScoreLabel

# 체력 한 칸당 값
const HEALTH_PER_UNIT = 25
const UNIT_MAX_WIDTH = 30.0

var health_units: Array[ColorRect] = []

func _ready():
	# 기존 체력 바 초기화
	for child in health_container.get_children():
		child.queue_free()
	
	# [추가] 라벨 배경색 설정 예시 (원하는 라벨에 적용)
	if health_text_label:
		add_background_to_label(health_text_label, Color(0, 0, 0, 0.5)) # 반투명 검정 배경
	if ammo_label:
		add_background_to_label(ammo_label, Color(0, 0, 0, 0.5))

func init_health(max_health):
	health_units.clear()
	var unit_count = int(max_health / HEALTH_PER_UNIT)
	for i in range(unit_count):
		var unit = ColorRect.new()
		unit.custom_minimum_size = Vector2(30, 10) 
		unit.color = Color.RED 
		health_container.add_child(unit)
		health_units.append(unit)

func update_health(current_health, max_health):
	if health_text_label:
		health_text_label.text = str(current_health) + " / " + str(max_health)
	
	for i in range(health_units.size()):
		var unit_min_health = i * HEALTH_PER_UNIT
		var unit_max_health = (i + 1) * HEALTH_PER_UNIT
		var unit = health_units[i]
		
		if current_health >= unit_max_health:
			unit.custom_minimum_size.x = UNIT_MAX_WIDTH
			unit.color = Color.RED
		elif current_health <= unit_min_health:
			unit.custom_minimum_size.x = UNIT_MAX_WIDTH
			unit.color = Color(0.2, 0.2, 0.2, 0.5) 
		else:
			var partial_amount = current_health - unit_min_health
			var ratio = float(partial_amount) / float(HEALTH_PER_UNIT)
			var new_width = UNIT_MAX_WIDTH * ratio
			unit.custom_minimum_size.x = max(new_width, 1.0)
			unit.color = Color.RED

func update_ammo(current_ammo, max_ammo):
	ammo_label.text = str(current_ammo) + " / " + str(max_ammo)

# [추가] 레벨 및 경험치 업데이트 함수
func update_level_xp(level, current_xp, max_xp):
	if level_label:
		level_label.text = "Lv. " + str(level)
	if xp_bar and is_instance_valid(xp_bar):
		xp_bar.max_value = max_xp
		xp_bar.value = current_xp
	elif not is_instance_valid(xp_bar):
		print("경고: HUD에서 XPBar 노드를 찾을 수 없습니다! 경로를 확인하세요.")

# [추가] 점수 업데이트 함수
func update_score(score):
	if score_label:
		score_label.text = "Score: " + str(score)

# [추가] 라벨에 배경색을 넣는 함수
func add_background_to_label(label: Label, bg_color: Color):
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = bg_color
	# 여백 설정 (선택 사항)
	style_box.expand_margin_left = 5
	style_box.expand_margin_right = 5
	style_box.expand_margin_top = 2
	style_box.expand_margin_bottom = 2
	
	label.add_theme_stylebox_override("normal", style_box)
