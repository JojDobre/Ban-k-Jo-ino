class_name Pickup
extends Area2D
## Predmet, ktorý Jožino zoberie dotykom: srdce, kryštály s vylepšením, kľúč.
## Môže sa objaviť aj z bloku (`rise_from_block`).

enum Kind { HEART, SHIELD, SPEED, MAGNET, KEY }

## Čo predmet urobí (kryštály: modrý = štít, zelený = rýchlosť, červený = magnet).
@export var kind: Kind = Kind.HEART

const SPEED_DURATION := 8.0
const MAGNET_DURATION := 12.0
## Srdce pri plnom zdraví dá aspoň mince.
const FULL_HEALTH_COINS := 5

var _time := 0.0
var _taken := false
var _ready_to_take := true

@onready var _sprite: Sprite2D = $Sprite
@onready var _glow: Sprite2D = $Glow


func _ready() -> void:
	_time = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_sprite.position.y = sin(_time * 3.0) * 6.0
	_glow.scale = Vector2.ONE * (1.0 + sin(_time * 4.0) * 0.12)
	_glow.rotation += delta * 0.8


## Vyskočí z bloku nad neho; zobrať sa dá až po dopade animácie.
func rise_from_block() -> void:
	_ready_to_take = false
	z_index = -1
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 64.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func() -> void:
		z_index = 0
		_ready_to_take = true
		for body in get_overlapping_bodies():
			_on_body_entered(body))


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	var run := GameState.current_run
	if _taken or not _ready_to_take or player == null or run == null:
		return
	_taken = true
	var text := ""
	var color := Color.WHITE
	match kind:
		Kind.HEART:
			if run.hearts < run.max_hearts:
				run.heal()
				text = "+1 srdce"
			else:
				run.add_coins(FULL_HEALTH_COINS)
				text = "+%d" % FULL_HEALTH_COINS
			color = Color("ff6b7a")
			Audio.play(&"powerup")
		Kind.SHIELD:
			player.add_powerup(Player.POWERUP_SHIELD, INF)
			text = "Štít!"
			color = Color("7fd3ff")
		Kind.SPEED:
			player.add_powerup(Player.POWERUP_SPEED, SPEED_DURATION)
			text = "Rýchlosť!"
			color = Color("6fe36f")
		Kind.MAGNET:
			player.add_powerup(Player.POWERUP_MAGNET, MAGNET_DURATION)
			text = "Magnet!"
			color = Color("ffd84d")
		Kind.KEY:
			run.add_key()
			Audio.play(&"key")
			text = "Kľúč!"
			color = Color("ffd84d")
			var locks := get_tree().get_nodes_in_group(&"lock_block")
			for i in locks.size():
				(locks[i] as LockBlock).unlock(0.25 + i * 0.12)
	Effects.floating_text(self, global_position + Vector2(0, -30), text, color)
	Effects.sparkle(self, global_position, color)
	set_deferred("monitoring", false)
	set_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
