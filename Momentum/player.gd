extends CharacterBody3D

const SPEED = 5.0
const CROUCH_SPEED = 2.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.005

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var default_height = 0.0

@onready var camera = $Camera3D
@onready var anim_player = %AnimationPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_height = camera.position.y

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	if Input.is_action_just_pressed("attack"):
		if anim_player.current_animation != "reload":
			anim_player.play("shoot")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var current_speed = SPEED
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

func _process(_delta):
	if (anim_player.current_animation == "shoot" or anim_player.current_animation == "reload") and \
	   (not anim_player.is_playing()):
		anim_player.play("stay")
	elif anim_player.current_animation == "stay" and not anim_player.is_playing():
		anim_player.play("stay")
	elif not anim_player.is_playing():
		anim_player.play("stay")
