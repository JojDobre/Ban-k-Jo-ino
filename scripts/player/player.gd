class_name Player
extends CharacterBody2D
## Jožino – pohyb, skok a zranenie (GDD kap. 2.1, 2.3).
## O srdciach a odmenách nevie nič; zásah iba oznámi signálom `damaged`.

signal damaged

const BODY_SIZE := Vector2(40, 56)

@export_group("Pohyb")
@export var max_speed: float = 330.0
@export var ground_acceleration: float = 2400.0
@export var ground_deceleration: float = 2800.0
@export var air_acceleration: float = 1700.0
@export var air_deceleration: float = 1100.0

@export_group("Skok")
@export var jump_velocity: float = -760.0
@export var gravity: float = 2000.0
@export var fall_gravity_multiplier: float = 1.6
@export var max_fall_speed: float = 1150.0
## Násobič rýchlosti stúpania po pustení tlačidla skoku (1.0 = vždy plný skok).
@export var jump_cut_multiplier: float = 0.7
## Skok sa neskráti skôr ako po tomto čase – aj krátke ťuknutie dá ~80 % výšky.
@export var min_jump_hold_time: float = 0.15
## Ako dlho po zídení z hrany ešte možno skočiť.
@export var coyote_time: float = 0.10
## Ako dlho sa pamätá stlačenie skoku pred dopadom.
@export var jump_buffer_time: float = 0.12

@export_group("Nepriatelia")
@export var stomp_bounce_velocity: float = -520.0
## Odraz od nepriateľa pri držanom skoku.
@export var stomp_bounce_held_velocity: float = -800.0
@export var invulnerability_time: float = 1.2
@export var knockback: Vector2 = Vector2(280, -420)

var input_enabled: bool = true
## Dosah magnetu na mince; nastavuje level podľa Kováčskej dielne.
var magnet_radius: float = 0.0
var facing: int = 1

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _invulnerable_timer := 0.0
var _jump_held := false
var _jump_time := 0.0


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	var jump_pressed := input_enabled and Input.is_action_just_pressed("jump")
	var jump_down := input_enabled and Input.is_action_pressed("jump")

	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta
	_jump_buffer_timer = jump_buffer_time if jump_pressed else _jump_buffer_timer - delta

	_apply_horizontal(direction, delta)
	_apply_gravity(delta)

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		_jump()

	# Premenlivá výška skoku: pustenie tlačidla počas stúpania skok skráti.
	_jump_time += delta
	if _jump_held and not jump_down and _jump_time >= min_jump_hold_time:
		_jump_held = false
		if velocity.y < 0.0:
			velocity.y *= jump_cut_multiplier

	move_and_slide()
	_update_invulnerability(delta)


func _apply_horizontal(direction: float, delta: float) -> void:
	var on_floor := is_on_floor()
	var rate: float
	if direction != 0.0:
		rate = ground_acceleration if on_floor else air_acceleration
		var new_facing := int(signf(direction))
		if new_facing != facing:
			facing = new_facing
			queue_redraw()
	else:
		rate = ground_deceleration if on_floor else air_deceleration
	velocity.x = move_toward(velocity.x, direction * max_speed, rate * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return
	var multiplier := fall_gravity_multiplier if velocity.y > 0.0 else 1.0
	velocity.y = minf(velocity.y + gravity * multiplier * delta, max_fall_speed)


func _jump() -> void:
	velocity.y = jump_velocity
	_jump_held = true
	_jump_time = 0.0
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


## Volá nepriateľ, na ktorého Jožino skočil.
func stomp_bounce() -> void:
	var held := input_enabled and Input.is_action_pressed("jump")
	velocity.y = stomp_bounce_held_velocity if held else stomp_bounce_velocity
	_jump_held = held
	_coyote_timer = 0.0


func is_invulnerable() -> bool:
	return _invulnerable_timer > 0.0


## Zásah od nepriateľa. Vráti false, ak je Jožino práve chránený.
func take_damage(from_position: Vector2) -> bool:
	if is_invulnerable() or not input_enabled:
		return false
	_invulnerable_timer = invulnerability_time
	var away := signf(global_position.x - from_position.x)
	velocity = Vector2((away if away != 0.0 else -facing) * knockback.x, knockback.y)
	_jump_held = false
	damaged.emit()
	return true


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	_jump_held = false
	_invulnerable_timer = invulnerability_time * 0.5
	get_node("Camera2D").reset_smoothing()


## Výška chodidiel v globálnych súradniciach (pôvod je v strede tela).
func get_feet_y() -> float:
	return global_position.y + BODY_SIZE.y * 0.5


func _update_invulnerability(delta: float) -> void:
	if _invulnerable_timer <= 0.0:
		return
	_invulnerable_timer -= delta
	modulate.a = 1.0 if _invulnerable_timer <= 0.0 else (0.35 if fmod(_invulnerable_timer, 0.16) < 0.08 else 1.0)


# Dočasná grafika – nahradí ju AnimatedSprite2D (GDD kap. 10.2).
func _draw() -> void:
	var half := BODY_SIZE * 0.5
	draw_rect(Rect2(-half, BODY_SIZE), Color("e8553c"))
	draw_rect(Rect2(-half, Vector2(BODY_SIZE.x, 12)), Color("3a5fcd"))
	var eye_x := 8.0 * facing
	draw_circle(Vector2(eye_x - 6, -8), 5, Color.WHITE)
	draw_circle(Vector2(eye_x + 6, -8), 5, Color.WHITE)
	draw_circle(Vector2(eye_x - 6 + 2 * facing, -7), 2.2, Color.BLACK)
	draw_circle(Vector2(eye_x + 6 + 2 * facing, -7), 2.2, Color.BLACK)
