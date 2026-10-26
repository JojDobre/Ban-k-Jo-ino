class_name FallingPlatform
extends AnimatableBody2D
## Drevený mostík, ktorý sa chvíľu po tom, čo naň Jožino stúpi, roztrasie a spadne.
## Po chvíli sa vráti na pôvodné miesto.

@export var shake_time: float = 0.5
@export var respawn_time: float = 3.0

enum State { IDLE, SHAKING, FALLING, GONE }

var _state := State.IDLE
var _state_time := 0.0
var _origin: Vector2
var _fall_speed := 0.0

@onready var _visual: Node2D = $Visual
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _sensor: Area2D = $Sensor


func _ready() -> void:
	_origin = position


func _physics_process(delta: float) -> void:
	_state_time += delta
	match _state:
		State.IDLE:
			for body in _sensor.get_overlapping_bodies():
				var player := body as Player
				if player != null and player.is_on_floor():
					_set_state(State.SHAKING)
					Audio.play(&"break", 0.2)
		State.SHAKING:
			_visual.position = Vector2(randf_range(-3, 3), randf_range(-1, 2))
			if _state_time > shake_time:
				_fall_speed = 0.0
				_set_state(State.FALLING)
		State.FALLING:
			_visual.position = Vector2.ZERO
			_fall_speed = minf(_fall_speed + 1800.0 * delta, 900.0)
			position.y += _fall_speed * delta
			_visual.modulate.a = maxf(1.0 - _state_time / 0.9, 0.0)
			if _state_time > 0.9:
				_shape.set_deferred("disabled", true)
				_set_state(State.GONE)
		State.GONE:
			if _state_time > respawn_time:
				position = _origin
				_shape.set_deferred("disabled", false)
				_set_state(State.IDLE)
				var tween := create_tween()
				tween.tween_property(_visual, "modulate:a", 1.0, 0.3)


func _set_state(state: State) -> void:
	_state = state
	_state_time = 0.0
