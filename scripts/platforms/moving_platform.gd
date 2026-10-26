class_name MovingPlatform
extends AnimatableBody2D
## Plošina, ktorá sa plynulo hýbe tam a späť. Jožino na nej stojí a vezie sa.

## Posun od štartu do druhého krajného bodu (px).
@export var travel: Vector2 = Vector2(256, 0)
## Čas jednej cesty tam (s).
@export var duration: float = 2.5

var _origin: Vector2
var _time := 0.0


func _ready() -> void:
	_origin = position


func _physics_process(delta: float) -> void:
	_time += delta
	# Kosínus – na koncoch spomalí, v strede je najrýchlejšia.
	var t := 0.5 - 0.5 * cos(_time * PI / duration)
	position = _origin + travel * t
