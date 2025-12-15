extends Area3D

var speed = 10.0
var damage = 30
var direction = Vector3.FORWARD

func _ready():
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	position += -transform.basis.z * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body is StaticBody3D or body is CSGShape3D:
		queue_free()

func _on_area_entered(area):
	if area.has_method("hit"):
		area.hit(damage)
		queue_free()
