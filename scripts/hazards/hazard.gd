class_name Hazard
extends Area2D
## Nebezpečenstvo, ktoré zraní pri dotyku (ostne, píla). Píla sa môže aj hýbať tam a späť.

## Vzdialenosť pohybu od štartu na každú stranu (0 = stojí).
@export var move_range: Vector2 = Vector2.ZERO
@export var move_speed: float = 1.2
## Rýchlosť otáčania kresby (píla).
@export var spin_speed: float = 0.0

var _origin: Vector2
var _time := 0.0

@onready var _sprite: Node2D = $Sprite


func _ready() -> void:
	_origin = position


func _physics_process(delta: float) -> void:
	_time += delta
	if move_range != Vector2.ZERO:
		position = _origin + move_range * sin(_time * move_speed)
	if spin_speed != 0.0:
		_sprite.rotation += spin_speed * delta
	for body in get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(global_position + Vector2(0, 40))
