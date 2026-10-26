class_name Player
extends CharacterBody2D
## Jožino – pohyb, skok, zranenie a animácie (GDD kap. 2.1, 2.3).
## O srdciach a odmenách nevie nič; zásah iba oznámi signálom `damaged`,
## pád do lávy signálom `fell_into_hazard`.

signal damaged
signal fell_into_hazard
## Zmena aktívnych vylepšení: {názov: zostávajúci čas v s, INF = do zásahu}.
signal powerups_changed(powerups: Dictionary)

## Kolízny obdĺžnik (menší ako kresba, GDD kap. 2.1). Pôvod uzla je v jeho strede.
const BODY_SIZE := Vector2(36, 72)
## Ako ďaleko pred Jožina sa pozerá kamera.
const CAMERA_LOOK_AHEAD := 110.0
## Kamera sa pozerá trochu nad Jožina, aby bolo vidno viac oblohy a menej zeme.
const CAMERA_LIFT := -120.0
## Vylepšenia z kryštálov (GDD kap. 2.5).
const POWERUP_SHIELD := &"shield"
const POWERUP_SPEED := &"speed"
const POWERUP_MAGNET := &"magnet"
const SPEED_BOOST := 1.35
const SPEED_JUMP_BOOST := 1.08
const POWERUP_MAGNET_RADIUS := 260.0

@export_group("Pohyb")
@export var max_speed: float = 340.0
@export var ground_acceleration: float = 2400.0
@export var ground_deceleration: float = 2800.0
@export var air_acceleration: float = 1700.0
@export var air_deceleration: float = 1100.0

@export_group("Skok")
@export var jump_velocity: float = -900.0
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
@export var stomp_bounce_velocity: float = -560.0
## Odraz od nepriateľa pri držanom skoku – dostane Jožina vyššie ako bežný skok.
@export var stomp_bounce_held_velocity: float = -1150.0
@export var invulnerability_time: float = 1.2
@export var knockback: Vector2 = Vector2(280, -420)

var input_enabled: bool = true
## Dosah magnetu na mince; nastavuje level podľa Kováčskej dielne.
var magnet_radius: float = 0.0
var facing: int = 1

var _powerups: Dictionary = {}

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _invulnerable_timer := 0.0
var _jump_held := false
var _jump_time := 0.0
var _was_on_floor := true
var _hurt_timer := 0.0
var _dead := false
var _shake := 0.0
var _look := 0.0
var _previous_feet_y := 0.0
var _older_feet_y := 0.0
var _visual_tween: Tween

@onready var _visual: Node2D = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/Sprite
@onready var _sprite_offset_x: float = _sprite.position.x
@onready var _dust: CPUParticles2D = $Dust
@onready var _camera: Camera2D = $Camera2D
@onready var _shield: Sprite2D = $Shield
@onready var _speed_trail: CPUParticles2D = $SpeedTrail
@onready var _magnet_sparks: CPUParticles2D = $MagnetSparks


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
	var rising := velocity.y < 0.0

	# Premenlivá výška skoku: pustenie tlačidla počas stúpania skok skráti.
	_jump_time += delta
	if _jump_held and not jump_down and _jump_time >= min_jump_hold_time:
		_jump_held = false
		if velocity.y < 0.0:
			velocity.y *= jump_cut_multiplier

	var fall_speed := velocity.y
	_older_feet_y = _previous_feet_y
	_previous_feet_y = get_feet_y()
	move_and_slide()

	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		_on_landed(fall_speed)
	_was_on_floor = on_floor
	if rising:
		_bump_ceiling()

	_update_powerups(delta)
	_update_invulnerability(delta)
	_update_animation(delta)
	_update_camera(delta)


func _apply_horizontal(direction: float, delta: float) -> void:
	var on_floor := is_on_floor()
	var rate: float
	if direction != 0.0:
		rate = ground_acceleration if on_floor else air_acceleration
		facing = int(signf(direction))
	else:
		rate = ground_deceleration if on_floor else air_deceleration
	velocity.x = move_toward(velocity.x, direction * get_max_speed(), rate * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return
	var multiplier := fall_gravity_multiplier if velocity.y > 0.0 else 1.0
	velocity.y = minf(velocity.y + gravity * multiplier * delta, max_fall_speed)


func _jump() -> void:
	velocity.y = jump_velocity * (SPEED_JUMP_BOOST if has_powerup(POWERUP_SPEED) else 1.0)
	_jump_held = true
	_jump_time = 0.0
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_squash(Vector2(0.8, 1.2))
	_dust.restart()
	Audio.play(&"jump", 0.05)


## Volá nepriateľ, na ktorého Jožino skočil.
func stomp_bounce() -> void:
	var held := input_enabled and Input.is_action_pressed("jump")
	velocity.y = stomp_bounce_held_velocity if held else stomp_bounce_velocity
	_jump_held = false
	_coyote_timer = 0.0
	_squash(Vector2(0.8, 1.2))


## Vystrelenie nahor (pružina). Skok sa nedá skrátiť.
func launch(launch_velocity: float) -> void:
	velocity.y = launch_velocity
	_jump_held = false
	_coyote_timer = 0.0
	_squash(Vector2(0.7, 1.3))


func is_invulnerable() -> bool:
	return _invulnerable_timer > 0.0


## Zásah od nepriateľa. Vráti false, ak je Jožino práve chránený.
func take_damage(from_position: Vector2) -> bool:
	if is_invulnerable() or not input_enabled:
		return false
	if has_powerup(POWERUP_SHIELD):
		# Štít zachytí jeden zásah.
		_remove_powerup(POWERUP_SHIELD)
		_invulnerable_timer = invulnerability_time * 0.6
		velocity.y = minf(velocity.y, -380.0)
		Audio.play(&"shield_pop")
		Effects.burst(self, global_position, Color("7fd3ff"), 18, 260.0, 0.9, 0.0)
		return false
	_invulnerable_timer = invulnerability_time
	_hurt_timer = 0.35
	var away := signf(global_position.x - from_position.x)
	velocity = Vector2((away if away != 0.0 else -facing) * knockback.x, knockback.y)
	_jump_held = false
	shake_camera(10.0)
	Audio.play(&"hurt")
	damaged.emit()
	return true


## Láva alebo iná smrteľná plocha – rieši sa rovnako ako pád do jamy.
func fall_into_hazard() -> void:
	if input_enabled:
		fell_into_hazard.emit()


func respawn(at: Vector2) -> void:
	global_position = at
	_previous_feet_y = get_feet_y()
	_older_feet_y = _previous_feet_y
	velocity = Vector2.ZERO
	_jump_held = false
	# Bez vynulovania by po návrate z výšky ešte platil coyote time a dal sa skok vo vzduchu.
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_invulnerable_timer = invulnerability_time * 0.5
	_camera.reset_smoothing()


## Koniec pokusu po strate všetkých sŕdc.
func play_death() -> void:
	_dead = true
	input_enabled = false
	_invulnerable_timer = 0.0
	modulate.a = 1.0
	_sprite.play(&"die")


## Koniec levelu – Jožino zastaví a čaká.
func celebrate() -> void:
	input_enabled = false
	_squash(Vector2(0.85, 1.15))


func get_max_speed() -> float:
	return max_speed * (SPEED_BOOST if has_powerup(POWERUP_SPEED) else 1.0)


## Aktivuje vylepšenie na `duration` sekúnd (INF = kým ho nezruší zásah).
func add_powerup(powerup: StringName, duration: float) -> void:
	_powerups[powerup] = duration
	Audio.play(&"powerup")
	_squash(Vector2(1.2, 1.2))
	_refresh_powerup_visuals()
	powerups_changed.emit(_powerups.duplicate())


func get_powerups() -> Dictionary:
	return _powerups.duplicate()


func has_powerup(powerup: StringName) -> bool:
	return _powerups.has(powerup)


## Dosah magnetu: väčší z Kováčskej dielne a z dočasného vylepšenia.
func get_magnet_radius() -> float:
	return maxf(magnet_radius, POWERUP_MAGNET_RADIUS if has_powerup(POWERUP_MAGNET) else 0.0)


func shake_camera(strength: float) -> void:
	_shake = maxf(_shake, strength)


## Výška chodidiel v globálnych súradniciach (pôvod je v strede tela).
func get_feet_y() -> float:
	return global_position.y + BODY_SIZE.y * 0.5


## Najvyššia poloha chodidiel za posledné dve snímky. Area2D hlási prekrytie s oneskorením –
## pri rýchlom páde sú chodidlá v čase hlásenia už nižšie, ako keď sa nepriateľa dotkli.
func get_previous_feet_y() -> float:
	return minf(minf(_older_feet_y, _previous_feet_y), get_feet_y())


## Náraz hlavou zospodu do bloku (blok s mincou, tehla…). Blok má metódu `bump(player)`.
func _bump_ceiling() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_normal().y > 0.7:
			var block := collision.get_collider() as Node
			if block != null and block.has_method(&"bump"):
				block.call(&"bump", self)
				_squash(Vector2(1.15, 0.85))
				return


func _update_powerups(delta: float) -> void:
	if _powerups.is_empty():
		return
	var expired: Array[StringName] = []
	for powerup: StringName in _powerups:
		_powerups[powerup] -= delta
		if _powerups[powerup] <= 0.0:
			expired.append(powerup)
	for powerup in expired:
		_remove_powerup(powerup)


func _remove_powerup(powerup: StringName) -> void:
	_powerups.erase(powerup)
	_refresh_powerup_visuals()
	powerups_changed.emit(_powerups.duplicate())


func _refresh_powerup_visuals() -> void:
	_shield.visible = has_powerup(POWERUP_SHIELD)
	_speed_trail.emitting = has_powerup(POWERUP_SPEED)
	_magnet_sparks.emitting = has_powerup(POWERUP_MAGNET)


func _on_landed(fall_speed: float) -> void:
	_squash(Vector2(1.2, 0.8))
	if fall_speed > 500.0:
		_dust.restart()


## Krátke „stlačenie“ kresby – postava pôsobí pružne. Mení sa uzol Visual, ktorého pôvod je pri chodidlách.
func _squash(amount: Vector2) -> void:
	if _visual_tween:
		_visual_tween.kill()
	_visual.scale = amount
	_visual_tween = create_tween()
	_visual_tween.tween_property(_visual, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_animation(delta: float) -> void:
	_sprite.flip_h = facing < 0
	_sprite.position.x = _sprite_offset_x * facing
	if _dead:
		return
	_hurt_timer -= delta
	var anim: StringName
	if _hurt_timer > 0.0:
		anim = &"hurt"
	elif not is_on_floor():
		anim = &"jump" if velocity.y < 0.0 else &"fall"
	elif absf(velocity.x) > 20.0:
		anim = &"run"
	else:
		anim = &"idle"
	if _sprite.animation != anim:
		_sprite.play(anim)
	_sprite.speed_scale = clampf(absf(velocity.x) / max_speed, 0.5, 1.6) if anim == &"run" else 1.0
	if _shield.visible:
		_shield.scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.04)


func _update_camera(delta: float) -> void:
	if absf(velocity.x) > 10.0:
		_look = move_toward(_look, facing * CAMERA_LOOK_AHEAD, 160.0 * delta)
	_shake = move_toward(_shake, 0.0, 40.0 * delta)
	var jitter := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	_camera.offset = Vector2(_look, CAMERA_LIFT) + jitter


func _update_invulnerability(delta: float) -> void:
	if _invulnerable_timer <= 0.0:
		return
	_invulnerable_timer -= delta
	modulate.a = 1.0 if _invulnerable_timer <= 0.0 else (0.35 if fmod(_invulnerable_timer, 0.16) < 0.08 else 1.0)
