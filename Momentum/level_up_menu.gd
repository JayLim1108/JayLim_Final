extends CanvasLayer

# [핵심] 플레이어에게 선택된 업그레이드를 전달하기 위한 시그널 선언
signal upgrade_selected(upgrade_name: String)

@onready var title_label: Label = $Background/CenterContainer/VBoxContainer/TitleLabel
@onready var buttons_container: HBoxContainer = $Background/CenterContainer/VBoxContainer/HBoxContainer
# [핵심] 이 3가지 버튼 경로가 정확해야 합니다!
@onready var choice_buttons: Array[Button] = [
	$Background/CenterContainer/VBoxContainer/HBoxContainer/ChoiceButton1,
	$Background/CenterContainer/VBoxContainer/HBoxContainer/ChoiceButton2,
	$Background/CenterContainer/VBoxContainer/HBoxContainer/ChoiceButton3
]

# 버튼에 저장될 업그레이드 이름 배열
var current_choices: Array # <--- [수정] Array[String]에서 Array로 변경

func _ready():
	# [핵심 수정] 렌더링 레이어를 높여 HUD 위에 표시되도록 강제합니다. (일반 HUD 레이어보다 높게 설정)
	self.layer = 10
	
	# UI 조작을 위해 마우스 커서를 보이게 합니다.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# [오류 방지 수정] 버튼 연결 전 유효성 검사 추가
	for i in range(choice_buttons.size()):
		var button = choice_buttons[i]
		
		# 버튼 노드가 null이 아닌지 확인합니다.
		if is_instance_valid(button):
			# 버튼이 눌렸을 때 _on_choice_button_pressed 함수를 호출하고
			# 추가 인자로 버튼의 인덱스를 전달합니다.
			button.pressed.connect(Callable(self, "_on_choice_button_pressed").bind(i))
			# 버튼 텍스트 초기화
			button.text = "선택지 " + str(i + 1)
			
			# [추가] 버튼이 눌러지지 않을 때 대비: Input_mode를 Stop에서 Pass로 변경 (선택 사항)
			button.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			# 노드를 찾지 못했을 경우 콘솔에 경고를 출력합니다.
			print("오류: LevelUpMenu.tscn에서 ChoiceButton", i + 1, " 노드를 찾을 수 없습니다! 경로를 확인하세요.")
	
	# [핵심 수정] title_label이 유효한지 확인합니다.
	if is_instance_valid(title_label):
		title_label.text = "LEVEL UP!"
	else:
		print("오류: LevelUpMenu.tscn에서 TitleLabel 노드를 찾을 수 없습니다! 경로를 확인하세요.")
		
	# [중요 참고] 씬의 Background (ColorRect) 노드의 mouse_filter 속성을 'Ignore'로 설정해야
	# 버튼을 가리지 않습니다. 이 스크립트에서 직접 설정할 수 없어 주석으로 남깁니다.

# player.gd의 show_level_up_menu 함수에서 호출될 함수
func set_choices(choices: Array): # <--- Array로 설정되어 일반 배열을 받습니다.
	if choices.size() != 3:
		print("경고: 선택지 개수가 3개가 아닙니다!")
		return
	
	current_choices = choices
	
	for i in range(3):
		if i < choice_buttons.size() and is_instance_valid(choice_buttons[i]):
			choice_buttons[i].text = choices[i]

func _on_choice_button_pressed(index: int):
	# [DEBUG] 버튼이 눌렸는지 확인합니다. 이 메시지가 안 뜨면 입력이 차단된 것입니다.
	print("DEBUG: Upgrade button pressed, index: ", index)
	
	if index >= 0 and index < current_choices.size():
		var selected_upgrade = current_choices[index]
		
		# [DEBUG] 시그널을 보내기 전에 확인
		print("DEBUG: Emitting signal 'upgrade_selected' with value: ", selected_upgrade)
		
		# [핵심] 시그널을 통해 player.gd에 선택된 업그레이드 이름 전달
		emit_signal("upgrade_selected", selected_upgrade)
		
		# [추가] 시그널이 성공적으로 연결되었는지 확인하는 로직 (경고만 띄움)
		# 만약 이 시그널이 player.gd에 연결되지 않았다면, 게임은 멈춰 있을 것입니다.
		if not is_connected("upgrade_selected", Callable(get_tree().get_first_node_in_group("player"), "apply_upgrade")):
			print("--- CRITICAL WARNING: 'upgrade_selected' signal is NOT connected to player.gd's 'apply_upgrade'. ---")
			print("--- 게임이 멈춰 있을 수 있습니다. player.gd의 show_level_up_menu 함수를 확인하세요. ---")
			# 시그널 연결이 실패했더라도 메뉴는 닫아야 하므로, 일시 정지를 수동 해제합니다.
			get_tree().paused = false 
		
		# [추가] 마우스 잠금 해제와 씬 제거는 시그널이 성공했든 아니든 메뉴를 닫기 위해 수행합니다.
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		# 이 메뉴 씬을 제거합니다.
		queue_free()
	
	# [진단] 만약 메뉴가 닫힌 후에도 게임이 멈춰 있다면, 
	# player.gd의 apply_upgrade 함수에서 get_tree().paused = false를
	# 호출하지 못한 것이 원인입니다.
