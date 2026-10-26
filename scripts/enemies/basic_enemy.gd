class_name BasicEnemy
extends CharacterBody2D
## Základný nepriateľ: chodí tam a späť, otáča sa pri stene a na okraji (GDD kap. 2.3).

const BODY_SIZE := Vector2(44, 36)

@export var speed: float = 90.0
@export_enum("Doľava:-1", "Doprava:1") var direction: int = -1
@export var gravity: float = 2000.0
## Jožino ho porazí, ak padá a jeho chodidlá sú nad touto hranicou
## (meraná od stredu nepriateľa). Väčšia hodnota = benevolentnejší zásah zhora.
@export var stomp_tolerance: float = 6.0

var _dead := false

@onready var _hitbox: Area2D = $Hitbox
@onready var _floor_ray: RayCast2D = $FloorRay


func _ready() -> void:
	_update_ray()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = direction * speed
	move_and_slide()

	if is_on_wall() or (is_on_floor() and not _floor_ray.is_colliding()):
		direction = -direction
		_update_ray()

	for body in _hitbox.get_overlapping_bodies():
		if body is Player:
			_touch_player(body)


func _touch_player(player: Player) -> void:
	var falling := player.velocity.y >= 0.0
	if falling and player.get_feet_y() <= global_position.y + stomp_tolerance:
		player.stomp_bounce()
		_die()
	else:
		player.take_damage(global_position)


func _die() -> void:
	_dead = true
	_hitbox.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 0.2), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)


func _update_ray() -> void:
	_floor_ray.position.x = direction * (BODY_SIZE.x * 0.5 + 2)
	queue_redraw()


func _draw() -> void:
	var half := BODY_SIZE * 0.5
	draw_rect(Rect2(-half, BODY_SIZE), Color("7b3fa0"))
	draw_circle(Vector2(direction * 10, -6), 5, Color.WHITE)
	draw_circle(Vector2(direction * 12, -6), 2.2, Color.BLACK)
