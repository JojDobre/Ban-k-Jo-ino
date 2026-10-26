class_name BasicEnemy
extends CharacterBody2D
## Základný nepriateľ: chodí tam a späť, otáča sa pri stene a na okraji (GDD kap. 2.3).
## Vzhľad (SpriteFrames s animáciami „walk“ a „dead“) a veľkosť určuje scéna.

@export var speed: float = 90.0
@export_enum("Doľava:-1", "Doprava:1") var direction: int = -1
@export var gravity: float = 2000.0
## Jožino ho porazí, ak padá a jeho chodidlá boli najviac o toľko pod vrchom
## nepriateľa. Väčšia hodnota = benevolentnejší zásah zhora.
@export var stomp_tolerance: float = 14.0

var _dead := false
var _half_width: float
var _half_height: float

@onready var _hitbox: Area2D = $Hitbox
@onready var _floor_ray: RayCast2D = $FloorRay
@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	var size := ($CollisionShape2D.shape as RectangleShape2D).size
	_half_width = size.x * 0.5
	_half_height = size.y * 0.5
	_sprite.play(&"walk")
	_update_direction()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = direction * speed
	move_and_slide()

	if is_on_wall() or (is_on_floor() and not _floor_ray.is_colliding()):
		direction = -direction
		_update_direction()

	for body in _hitbox.get_overlapping_bodies():
		if body is Player:
			_touch_player(body)


func _touch_player(player: Player) -> void:
	var falling := player.velocity.y >= 0.0
	if falling and player.get_previous_feet_y() <= global_position.y - _half_height + stomp_tolerance:
		player.stomp_bounce()
		_die()
	else:
		player.take_damage(global_position)


func _die() -> void:
	_dead = true
	Audio.play(&"stomp")
	_hitbox.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	_sprite.play(&"dead")
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.25, 0.8), 0.08)
	tween.tween_property(_sprite, "scale", Vector2.ONE, 0.1)
	tween.tween_interval(0.35)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _update_direction() -> void:
	_floor_ray.position.x = direction * (_half_width + 2.0)
	# Kenney nepriatelia sú nakreslení otočení doľava.
	_sprite.flip_h = direction > 0
