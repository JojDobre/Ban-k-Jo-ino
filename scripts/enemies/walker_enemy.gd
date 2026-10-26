class_name WalkerEnemy
extends Enemy
## Chodí tam a späť, otáča sa pri stene a na okraji plošiny (sliz, ostnatý sliz, slimák).

enum Style { BOUNCE, WOBBLE }

## BOUNCE – sliz poskakuje a stláča sa; WOBBLE – slimák sa pomaly kolíše.
@export var style: Style = Style.BOUNCE

@onready var _floor_ray: RayCast2D = $FloorRay


func _on_ready() -> void:
	_update_ray()


func _move(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = direction * speed
	move_and_slide()
	if is_on_wall() or (is_on_floor() and not _floor_ray.is_colliding()):
		direction = -direction
		_update_ray()


func _animate(_delta: float) -> void:
	match style:
		Style.BOUNCE:
			# Sliz sa pri každom kroku stlačí a natiahne; spodok ostáva na zemi.
			var phase := sin(_time * 9.0)
			sprite.scale = Vector2(1.0 - phase * 0.08, 1.0 + phase * 0.1)
			sprite.position = _base_sprite_position + Vector2(0, -absf(phase) * 5.0 - phase * 3.0)
		Style.WOBBLE:
			sprite.rotation = sin(_time * 3.0) * 0.05
			sprite.position = _base_sprite_position + Vector2(0, -absf(sin(_time * 3.0)) * 2.0)


func _update_ray() -> void:
	_floor_ray.position.x = direction * (_half_size.x + 2.0)
