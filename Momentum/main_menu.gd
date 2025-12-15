extends Control

# [설정] 게임 시작 시 이동할 메인 게임 씬 경로를 지정합니다.
const GAME_SCENE_PATH = "res://main.tscn"

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton # 새로 추가된 버튼
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

@onready var settings_panel: PanelContainer = $SettingsPanel # 설정 패널
@onready var sound_slider: HSlider = $SettingsPanel/VBoxContainer/SoundSlider
@onready var sensitivity_slider: HSlider = $SettingsPanel/VBoxContainer/SensitivitySlider
@onready var back_button: Button = $SettingsPanel/VBoxContainer/BackButton

# 오디오 버스 인덱스 (Master Bus는 보통 0번입니다.)
const MASTER_BUS_INDEX = 0
# 설정 저장 키
const SENSITIVITY_KEY = "User_Settings/camera_sensitivity"

func _ready():
	# UI 조작을 위해 마우스 커서를 보이게 합니다.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 초기 설정 로드 및 적용
	load_settings()
	
	# [버튼 신호 연결] (Null 오류 방지를 위해 유효성 검사 추가)
	if is_instance_valid(start_button):
		start_button.pressed.connect(_on_start_button_pressed)
	
	if is_instance_valid(quit_button):
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	if is_instance_valid(settings_button):
		settings_button.pressed.connect(_on_settings_button_pressed) 
	
	if is_instance_valid(back_button):
		back_button.pressed.connect(_on_back_button_pressed) # 뒤로 버튼 연결
	
	# [슬라이더 신호 연결]
	if is_instance_valid(sound_slider):
		sound_slider.value_changed.connect(_on_sound_slider_value_changed)
	
	if is_instance_valid(sensitivity_slider):
		sensitivity_slider.value_changed.connect(_on_sensitivity_slider_value_changed)

# --- 설정 로드/저장 로직 ---

func load_settings():
	# 1. 사운드 볼륨 로드
	if is_instance_valid(sound_slider):
		var current_volume_db = AudioServer.get_bus_volume_db(MASTER_BUS_INDEX)
		sound_slider.value = pow(10.0, current_volume_db / 20.0) # dB -> Linear 변환
	
	# 2. 감도 설정 로드
	if is_instance_valid(sensitivity_slider):
		var saved_sensitivity = ProjectSettings.get_setting(SENSITIVITY_KEY, 30.0)
		sensitivity_slider.value = saved_sensitivity

func save_settings():
	# 1. 감도 저장
	if is_instance_valid(sensitivity_slider): 
		ProjectSettings.set_setting(SENSITIVITY_KEY, sensitivity_slider.value)
		ProjectSettings.save()
		print("설정 저장됨: 감도=", sensitivity_slider.value)

# --- UI 이벤트 처리 ---

func _on_start_button_pressed():
	save_settings() # 시작 전 설정 저장
	print("--- [START] 게임 시작 버튼 클릭됨. ---")
	
	# 씬 전환
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_quit_button_pressed():
	save_settings() # 종료 전 설정 저장
	print("게임 종료 버튼 클릭!")
	get_tree().quit()

func _on_settings_button_pressed():
	# 설정 패널 표시
	if is_instance_valid(settings_panel):
		settings_panel.visible = true
	$CenterContainer.visible = false # 메인 버튼 숨김

func _on_back_button_pressed():
	# 설정 패널 숨김 및 메인 버튼 표시
	save_settings() # 돌아가기 전 설정 저장
	if is_instance_valid(settings_panel):
		settings_panel.visible = false
	$CenterContainer.visible = true

# --- 슬라이더 값 변경 처리 ---

func _on_sound_slider_value_changed(value):
	# 슬라이더 값(0.0 ~ 1.0)을 dB 값으로 변환하여 오디오 버스에 적용
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(MASTER_BUS_INDEX, db_value)

# 사용되지 않는 인자이므로 경고 방지를 위해 _value 사용
func _on_sensitivity_slider_value_changed(_value):
	# 감도 설정은 버튼을 누를 때(save_settings) 저장됩니다.
	pass
