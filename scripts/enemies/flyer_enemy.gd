class_name FlyerEnemy
extends Enemy
## Včela: lieta tam a späť vo vzduchu a vlní sa hore-dole. Nepadá a prechádza cez steny.

## Vzdialenosť letu od štartu na každú stranu (px).
@export var patrol_range: float = 192.0
@export var wave_height: float = 28.0
@export var wave_speed: float = 2.6

var _origin: Vector2


func _on_ready() -> void:
	_origin = global_position


func _move(delta: float) -> void:
	var x := global_position.x + direction * speed * delta
	if absf(x - _origin.x) > patrol_range:
		direction = -direction
		x = clampf(x, _origin.x - patrol_range, _origin.x + patrol_range)
	global_position = Vector2(x, _origin.y + sin(_time * wave_speed) * wave_height)


func _animate(_delta: float) -> void:
	# Krídla mávajú rýchlo; telo sa pri lete mierne nakláňa.
	sprite.speed_scale = 1.6
	sprite.rotation = direction * -0.12 + cos(_time * wave_speed) * 0.08
