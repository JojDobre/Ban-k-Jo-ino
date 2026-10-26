class_name Crusher
extends AnimatableBody2D
## Drvič (nahnevaný blok): visí vo vzduchu, a keď je Jožino pod ním, spadne.
## Po dopade chvíľu počká a pomaly sa vráti hore. Na jeho vrchu sa dá stáť.

const TEXTURE_IDLE := preload("res://assets/enemies/block_idle.png")
const TEXTURE_FALL := preload("res://assets/enemies/block_fall.png")
const TEXTURE_REST := preload("res://assets/enemies/block_rest.png")

enum State { WAITING, SHAKING, FALLING, LANDED, RISING }

@export var fall_speed: float = 900.0
@export var rise_speed: float = 120.0
## Ako ďaleko pod sebou (px) hľadá zem.
@export var max_drop: float = 640.0

var _state := State.WAITING
var _state_time := 0.0
var _top_y: float
var _bottom_y: float
var _velocity := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _danger: Area2D = $Danger


func _ready() -> void:
	_top_y = global_position.y
	_bottom_y = _top_y + max_drop
	var query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, 33), global_position + Vector2(0, 33 + max_drop), 1)
	query.exclude = [get_rid()]
	# Fyzikálny priestor je dostupný až po prvej snímke.
	await get_tree().physics_frame
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_bottom_y = hit.position.y - 32.0


func _physics_process(delta: float) -> void:
	_state_time += delta
	match _state:
		State.WAITING:
			_sprite.texture = TEXTURE_IDLE
			_sprite.position = Vector2.ZERO
			if _player_below():
				_set_state(State.SHAKING)
		State.SHAKING:
			_sprite.texture = TEXTURE_FALL
			_sprite.position = Vector2(randf_range(-3, 3), randf_range(-2, 2))
			if _state_time > 0.3:
				_velocity = 0.0
				_set_state(State.FALLING)
		State.FALLING:
			_sprite.position = Vector2.ZERO
			_velocity = minf(_velocity + 3200.0 * delta, fall_speed)
			global_position.y = minf(global_position.y + _velocity * delta, _bottom_y)
			_hurt_player_below()
			if global_position.y >= _bottom_y:
				_land()
		State.LANDED:
			if _state_time > 1.0:
				_set_state(State.RISING)
		State.RISING:
			_sprite.texture = TEXTURE_REST
			global_position.y = maxf(global_position.y - rise_speed * delta, _top_y)
			if global_position.y <= _top_y:
				_set_state(State.WAITING)


func _land() -> void:
	_set_state(State.LANDED)
	Audio.play(&"slam")
	Effects.burst(self, global_position + Vector2(0, 32), Color(0.9, 0.82, 0.68, 0.9), 16, 200.0, 1.2, 300.0)
	var player := _player()
	if player != null and player.global_position.distance_to(global_position) < 700.0:
		player.shake_camera(8.0)


func _player_below() -> bool:
	var player := _player()
	if player == null:
		return false
	var dx := absf(player.global_position.x - global_position.x)
	return dx < 72.0 and player.global_position.y > global_position.y and player.global_position.y < _bottom_y + 80.0


func _hurt_player_below() -> void:
	for body in _danger.get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(global_position + Vector2(0, -40))


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _set_state(state: State) -> void:
	_state = state
	_state_time = 0.0
