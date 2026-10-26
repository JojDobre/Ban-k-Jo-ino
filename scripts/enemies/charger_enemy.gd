class_name ChargerEnemy
extends Enemy
## Myš: pomaly sa prechádza, a keď zbadá Jožina pred sebou, poskočí a rozbehne sa naňho.

enum State { PATROL, ALERT, CHARGE, REST }

@export var charge_speed: float = 430.0
## Ako ďaleko (v px) vidí pred seba.
@export var sight_range: float = 448.0
@export var charge_time: float = 2.0

var _state := State.PATROL
var _state_time := 0.0

@onready var _floor_ray: RayCast2D = $FloorRay
@onready var _dust: CPUParticles2D = $Dust


func _on_ready() -> void:
	_update_ray()


func _move(delta: float) -> void:
	_apply_gravity(delta)
	_state_time += delta
	match _state:
		State.PATROL:
			velocity.x = direction * speed
			if _sees_player():
				_set_state(State.ALERT)
				velocity = Vector2(0, -320)
				_flash()
				Audio.play(&"alert")
				Effects.floating_text(self, global_position + Vector2(0, -50), "!", Color("ff5a3c"), 40)
		State.ALERT:
			velocity.x = 0.0
			if _state_time > 0.45 and is_on_floor():
				_set_state(State.CHARGE)
		State.CHARGE:
			velocity.x = move_toward(velocity.x, direction * charge_speed, 2400.0 * delta)
			if _state_time > charge_time:
				_set_state(State.REST)
		State.REST:
			velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
			if _state_time > 1.0:
				_set_state(State.PATROL)
	move_and_slide()
	if is_on_wall() or (is_on_floor() and not _floor_ray.is_colliding()):
		if _state == State.CHARGE:
			# Na okraji zabrzdí a otočí sa – nespadne.
			velocity.x = 0.0
			_set_state(State.REST)
		direction = -direction
		_update_ray()
	_dust.emitting = _state == State.CHARGE and is_on_floor()


func _animate(_delta: float) -> void:
	match _state:
		State.CHARGE:
			sprite.play(&"walk")
			sprite.speed_scale = 3.0
			sprite.rotation = direction * -0.08
		State.REST, State.ALERT:
			sprite.play(&"rest" if _state == State.REST else &"walk")
			sprite.speed_scale = 1.0
			sprite.rotation = 0.0
		_:
			sprite.play(&"walk")
			sprite.speed_scale = 1.0
			sprite.rotation = 0.0
	sprite.position = _base_sprite_position + Vector2(0, -absf(sin(_time * (20.0 if _state == State.CHARGE else 8.0))) * 3.0)


func _sees_player() -> bool:
	var player := _player()
	if player == null or not player.input_enabled:
		return false
	var offset := player.global_position - global_position
	if absf(offset.y) > 80.0 or absf(offset.x) > sight_range:
		return false
	if signf(offset.x) != direction:
		# Otočí sa, ak je Jožino blízko za ním.
		if absf(offset.x) < sight_range * 0.4:
			direction = int(signf(offset.x))
			_update_ray()
			return true
		return false
	return true


func _set_state(state: State) -> void:
	_state = state
	_state_time = 0.0


func _update_ray() -> void:
	_floor_ray.position.x = direction * (_half_size.x + 2.0)
