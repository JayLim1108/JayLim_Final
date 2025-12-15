extends CharacterBody3D

# [UPGRADES] Changed const to var to allow upgrades
var SPEED = 5.0
const CROUCH_SPEED = 2.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.005

# [MODIFIED] Attack speed, damage variables
var shoot_interval_rate = 0.5 # Current attack speed delay
var damage = 20.0			  # Current attack damage
const MAX_AMMO = 8

# [SHOTGUN SETUP]
const PELLET_COUNT = 5		# Number of pellets fired per shot
const SPREAD_ANGLE = 3.0	# Spread angle in degrees

# [BULLET SCENE] Must link the bullet scene file in the Godot Editor Inspector.
@export var bullet_scene: PackedScene 

# [LEVEL UP SYSTEM CONSTANTS]
const UPGRADE_MAX_HEALTH = "MAX HP INCREASE"
const UPGRADE_DAMAGE = "ATTACK DAMAGE INCREASE"
const UPGRADE_LIFESTEAL = "LIFESTEAL INCREASE"
const UPGRADE_ATTACK_SPEED = "ATTACK SPEED INCREASE"
const UPGRADE_MOVE_SPEED = "MOVEMENT SPEED INCREASE"
const UPGRADE_IGNORE = "IGNORE_SELECTION"  #New constant for skipping upgrade

const ALL_UPGRADES = [
	UPGRADE_MAX_HEALTH,
	UPGRADE_DAMAGE,
	UPGRADE_LIFESTEAL,
	UPGRADE_ATTACK_SPEED,
	UPGRADE_MOVE_SPEED,
]
# [REQUIRED] Level Up UI Scene path (Adjust the path to LevelUpMenu.tscn!)
const LEVEL_UP_MENU_SCENE = preload("res://level_up_menu.tscn") 

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var default_height = 0.0

# [ADDED] New Stats
var lifesteal_amount = 0.0 # Current lifesteal amount (0.0 to 1.0)

# Fire cooldown and ammo variables
var shoot_timer = 0.0
var current_ammo = MAX_AMMO

# Health system variables
var max_health = 250
var current_health = max_health

# [ADDED] Level, XP, Score variables
var level = 1
var current_xp = 0
var max_xp = 100 # XP required for the next level (example)
var score = 0

# Node Connections
@onready var camera = $Camera3D
@onready var anim_player = %AnimationPlayer
@onready var fire_point = $Camera3D/FirePoint 
@onready var hud = $UI_Layer/HUD 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_height = camera.position.y
	print("Ammo: ", current_ammo, " / HP: ", current_health)
	
	if hud:
		hud.init_health(max_health)
		hud.update_health(current_health, max_health)
		hud.update_ammo(current_ammo, MAX_AMMO)
		hud.update_level_xp(level, current_xp, max_xp)
		hud.update_score(score)
	
	if not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name):
	if anim_name == "reload":
		current_ammo = MAX_AMMO
		print("Reload Complete! Ammo: ", current_ammo)
		
		if hud:
			hud.update_ammo(current_ammo, MAX_AMMO)
			
		anim_player.play("stay")
	
	elif anim_name == "shoot":
		anim_player.play("stay")

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var current_speed = SPEED # [MODIFIED] Use var SPEED
	
	if Input.is_action_pressed("crouch") and is_on_floor():
		current_speed = CROUCH_SPEED
		camera.position.y = lerp(camera.position.y, default_height - 0.7, delta * 10)
	else:
		camera.position.y = lerp(camera.position.y, default_height, delta * 10)

	var input_dir = Vector3()
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	var direction = (transform.basis * input_dir).normalized()

	if is_on_floor():
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = lerp(velocity.x, direction.x * current_speed, 0.1)
		velocity.z = lerp(velocity.z, direction.z * current_speed, 0.1)

	move_and_slide()

func _process(delta):
	if shoot_timer > 0:
		shoot_timer -= delta

	# 1. Manual Reload (R key)
	if Input.is_action_just_pressed("reload"):
		if anim_player.current_animation != "reload" and current_ammo < MAX_AMMO:
			anim_player.play("reload")

	# 2. Fire (Hold mouse for rapid fire)
	if Input.is_action_pressed("attack"):
		if anim_player.current_animation != "reload":
			if (anim_player.current_animation != "shoot" or not anim_player.is_playing()) and shoot_timer <= 0:
				if current_ammo > 0:
					anim_player.play("shoot")
					shoot_timer = shoot_interval_rate # [MODIFIED] Use var shoot_interval_rate
					current_ammo -= 1
					
					# [CORE] Call actual shotgun firing function!
					shoot_shotgun()
					
					if hud:
						hud.update_ammo(current_ammo, MAX_AMMO)
					
					print("Bang! Ammo: ", current_ammo)
				else:
					anim_player.play("reload")
					
	if not anim_player.is_playing():
		if anim_player.current_animation != "stay":
			anim_player.play("stay")

# Shotgun Firing Function (fixed radial pattern)
func shoot_shotgun():
	if not bullet_scene:
		return
		
	# [ADDED] Lifesteal Logic: Health recovery upon firing (simple implementation)
	if lifesteal_amount > 0.0:
		# Recover health proportional to lifesteal amount
		var health_gain = damage * lifesteal_amount * 0.1 
		current_health = min(max_health, current_health + health_gain)
		if hud:
			hud.update_health(current_health, max_health)
	
	# Get the base Transform from the FirePoint or camera
	var base_transform = camera.global_transform
	if fire_point:
		base_transform = fire_point.global_transform

	var angle_step = TAU / PELLET_COUNT
	var spread_ratio = tan(deg_to_rad(SPREAD_ANGLE))

	# Spawn 5 pellets
	for i in range(PELLET_COUNT):
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		
		# [MODIFIED] Set bullet damage to player stats (damage variable must be exported in PlayerBullet.gd)
		if bullet.has_method("set_damage"):
			bullet.set_damage(damage)
			
		var current_angle = i * angle_step
		var local_x = cos(current_angle) * spread_ratio
		var local_y = sin(current_angle) * spread_ratio
		
		var final_direction = -base_transform.basis.z
		final_direction += base_transform.basis.x * local_x
		final_direction += base_transform.basis.y * local_y
		
		final_direction = final_direction.normalized()

		bullet.global_position = base_transform.origin
		bullet.look_at(bullet.global_position + final_direction, base_transform.basis.y)

# Damage intake function (called by enemies or DeathZone)
func take_damage(amount):
	current_health -= amount
	print("Ouch! HP: ", current_health)
	
	if hud:
		hud.update_health(current_health, max_health)
	
	if current_health <= 0:
		die()

# [MODIFIED] Added menu display function to Level Up logic
func on_enemy_killed(xp_amount: int, score_amount: int):
	current_xp += xp_amount
	score += score_amount
	
	# Level Up Check
	if current_xp >= max_xp:
		current_xp -= max_xp
		level += 1
		max_xp = int(max_xp * 1.2) # Increase XP required for next level
		
		# [CORE] Pause game and display choices upon level up
		print("Level Up! Level: ", level)
		show_level_up_menu()
		
	# UI Update
	if hud:
		hud.update_level_xp(level, current_xp, max_xp)
		hud.update_score(score)

# [NEW FUNCTION] Display Level Up Menu and Pause Game
func show_level_up_menu():
	# Pause game
	get_tree().paused = true
	
	# Get 3 choices
	var choices = get_unique_upgrades(3)
	
	if LEVEL_UP_MENU_SCENE and hud:
		var menu = LEVEL_UP_MENU_SCENE.instantiate()
		
		# Add the menu to the HUD's parent node (CanvasLayer).
		hud.get_parent().add_child(menu) 
		
		# set_choices call
		if menu.has_method("set_choices"):
			menu.set_choices(choices)
		
		# [CORE] Attempt signal connection and output success/failure (for debugging)
		if menu.has_signal("upgrade_selected"):
			var error = menu.upgrade_selected.connect(apply_upgrade)
			if error == OK:
				print("DEBUG: Signal connected successfully to apply_upgrade.")
			else:
				print("CRITICAL: Signal connection failed with error code: ", error)
		else:
			print("CRITICAL: LevelUpMenu does not have 'upgrade_selected' signal.")
	else:
		# Debug message on scene load failure
		print("--- LevelUpMenu Scene failed to load or HUD node not found. ---")
		print("1: ", choices[0])
		print("2: ", choices[1])
		print("3: ", choices[2])
		# Release game pause since UI failed (for debugging)
		get_tree().paused = false 


# [NEW FUNCTION] Get N unique upgrade choices
func get_unique_upgrades(count: int) -> Array:
	var upgrade_pool = ALL_UPGRADES.duplicate()
	upgrade_pool.shuffle()
	return upgrade_pool.slice(0, min(count, upgrade_pool.size()))

# [NEW FUNCTION] Apply upgrade after selection (function called when UI button is clicked)
# This function connects via signal from the LevelUpMenu UI to resume the game and update stats.
func apply_upgrade(upgrade_name: String):
	# Resume game
	get_tree().paused = false
	
	# Recapture mouse (center cursor on screen)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 

	# [MODIFIED] Handle Ignore case first
	if upgrade_name == UPGRADE_IGNORE:
		print("--- Upgrade selection ignored. Game resumed. ---")
		return # Exit immediately
	
	print("--- Applying Upgrade: ", upgrade_name, " ---")
	
	match upgrade_name:
		UPGRADE_MAX_HEALTH:
			max_health += 50
			current_health = max_health 
			if hud: hud.init_health(max_health)
			print("Max HP increased by 50.")
			
		UPGRADE_DAMAGE:
			damage += 5.0 # Increase damage by 5
			print("Attack damage increased by 5. Current damage: ", damage)
			
		UPGRADE_LIFESTEAL:
			lifesteal_amount = min(lifesteal_amount + 0.05, 0.5) # Increase by 5%, max 50%
			print("Lifesteal increased by 5%. Current: ", lifesteal_amount * 100, "%")
			
		UPGRADE_ATTACK_SPEED:
			shoot_interval_rate = max(shoot_interval_rate - 0.05, 0.1) # Decrease by 0.05 seconds, minimum 0.1 seconds
			print("Attack speed increased. Cooldown: ", shoot_interval_rate)
			
		UPGRADE_MOVE_SPEED:
			SPEED += 1.0 # Increase move speed by 1.0
			print("Movement speed increased by 1.0. Current speed: ", SPEED)

	# UI Update
	if hud:
		hud.update_health(current_health, max_health)
		hud.update_level_xp(level, current_xp, max_xp)

func die():
	print("Game Over!")
	get_tree().reload_current_scene()
