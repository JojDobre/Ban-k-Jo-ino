class_name Enemy
extends CharacterBody2D
## Spoločný základ nepriateľov (GDD kap. 2.3): kontakt s Jožinom, skok zhora,
## porazenie s efektom. Pohyb a „oživenie“ kresby dopĺňajú potomkovia v `_move()` a `_animate()`.
## Scéna musí mať uzly Sprite (AnimatedSprite2D s „walk“ a „dead“), Hitbox (Area2D) a CollisionShape2D.

signal defeated

@export var speed: float = 90.0
@export_enum("Doľava:-1", "Doprava:1") var direction: int = -1
@export var gravity: float = 2000.0
## Dá sa poraziť skokom zhora? (Ostnatý sliz nie.)
@export var stompable: bool = true
## Jožino ho porazí, ak padá a jeho chodidlá boli najviac o toľko pod vrchom
## nepriateľa. Väčšia hodnota = benevolentnejší zásah zhora.
@export var stomp_tolerance: float = 14.0

var _dead := false
## Neškodný stav (napr. neviditeľná mucha) – nezraňuje a nedá sa zasiahnuť.
var _harmless := false
var _time := 0.0
var _half_size: Vector2
var _base_sprite_position: Vector2

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	_half_size = ($CollisionShape2D.shape as RectangleShape2D).size * 0.5
	_base_sprite_position = sprite.position
	# Každý nepriateľ začne animáciu v inej fáze, aby sa skupiny nehýbali rovnako.
	_time = randf() * 10.0
	sprite.play(&"walk")
	sprite.frame = randi() % maxi(sprite.sprite_frames.get_frame_count(&"walk"), 1)
	_on_ready()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_time += delta
	_move(delta)
	_animate(delta)
	# Kenney nepriatelia sú nakreslení otočení doľava.
	sprite.flip_h = direction > 0
	if not _harmless:
		for body in hitbox.get_overlapping_bodies():
			if body is Player:
				_touch_player(body)


## Pre potomkov: príprava po načítaní.
func _on_ready() -> void:
	pass


## Pre potomkov: pohyb za jednu fyzikálnu snímku.
func _move(_delta: float) -> void:
	pass


## Pre potomkov: procedurálne „oživenie“ kresby (pohupovanie, stláčanie).
func _animate(_delta: float) -> void:
	pass


func is_dead() -> bool:
	return _dead


## Porazenie – skokom zhora alebo úderom do bloku pod nepriateľom.
func defeat() -> void:
	if _dead:
		return
	_dead = true
	defeated.emit()
	Audio.play(&"stomp")
	hitbox.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	if sprite.sprite_frames.has_animation(&"dead"):
		sprite.play(&"dead")
	sprite.position = _base_sprite_position
	Effects.poof(self, global_position)
	Effects.burst(self, global_position + Vector2(0, -_half_size.y), Color("ffe14d"), 6, 200.0, 0.5, 300.0)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.4, 0.6), 0.08)
	tween.tween_property(sprite, "scale", Vector2(1.0, 0.9), 0.12)
	tween.tween_interval(0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _touch_player(player: Player) -> void:
	var top := global_position.y - _half_size.y
	var from_above := player.velocity.y >= 0.0 and player.get_previous_feet_y() <= top + stomp_tolerance
	if from_above and stompable:
		player.stomp_bounce()
		defeat()
	elif from_above:
		# Ostne: Jožina odrazí a zraní.
		player.take_damage(global_position + Vector2(0, _half_size.y))
	else:
		player.take_damage(global_position)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 1200.0)


## Krátke zablikanie (napr. keď si nepriateľ všimne Jožina).
func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.8, 1.8, 1.8), 0.06)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player
