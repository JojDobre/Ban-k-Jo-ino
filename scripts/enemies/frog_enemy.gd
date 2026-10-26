class_name FrogEnemy
extends Enemy
## Žaba: sedí, prikrčí sa a skočí oblúkom – smerom k Jožinovi, ak je blízko.
## Nevyskočí cez okraj plošiny.

@export var jump_interval: float = 1.6
@export var jump_velocity: Vector2 = Vector2(220, -720)
@export var notice_range: float = 512.0

var _wait := 0.0
var _crouch := false

@onready var _ledge_ray: RayCast2D = $FloorRay


func _on_ready() -> void:
	_wait = randf_range(0.5, jump_interval)


func _move(delta: float) -> void:
	var was_in_air := not is_on_floor()
	_apply_gravity(delta)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 3000.0 * delta)
		_wait -= delta
		_crouch = _wait < 0.25
		if _wait <= 0.0:
			_jump()
	move_and_slide()
	if is_on_wall():
		direction = -direction
	if was_in_air and is_on_floor():
		_wait = jump_interval
		sprite.scale = Vector2(1.3, 0.75)


func _jump() -> void:
	var player := _player()
	if player != null and global_position.distance_to(player.global_position) < notice_range:
		direction = int(signf(player.global_position.x - global_position.x)) if player.global_position.x != global_position.x else direction
	# Nad okrajom neskáče von – radšej sa otočí.
	_ledge_ray.position.x = direction * 110.0
	_ledge_ray.force_raycast_update()
	if not _ledge_ray.is_colliding():
		direction = -direction
	velocity = Vector2(direction * jump_velocity.x, jump_velocity.y)
	_crouch = false
	sprite.scale = Vector2(0.8, 1.25)
	Audio.play(&"jump", 0.1)


func _animate(delta: float) -> void:
	sprite.scale = sprite.scale.move_toward(Vector2.ONE, 3.0 * delta)
	if not is_on_floor():
		sprite.play(&"jump")
	elif _crouch:
		sprite.play(&"rest")
		sprite.scale = Vector2(1.12, 0.88)
	else:
		sprite.play(&"walk")
		# Dýchanie.
		sprite.scale.y = 1.0 + sin(_time * 4.0) * 0.04
