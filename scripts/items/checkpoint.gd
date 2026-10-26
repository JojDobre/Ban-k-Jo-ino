class_name Checkpoint
extends Area2D
## Po strate srdca pádom sa Jožino vráti na posledný dosiahnutý checkpoint (GDD kap. 2.4).
## Pôvod uzla je na zemi pod stožiarom. Červená vlajka = ešte nedosiahnutý, zelená = aktívny.

const FLAG_TEXTURES: Array[Texture2D] = [
	preload("res://assets/items/flag_green_a.png"),
	preload("res://assets/items/flag_green_b.png"),
]

var _active := false
var _time := 0.0

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_process(false)


func _process(delta: float) -> void:
	_time += delta
	_sprite.texture = FLAG_TEXTURES[int(_time * 4.0) % FLAG_TEXTURES.size()]


func _on_body_entered(body: Node2D) -> void:
	if _active or not body is Player or GameState.current_run == null:
		return
	_active = true
	GameState.current_run.checkpoint = global_position + Vector2(0, -Player.BODY_SIZE.y * 0.5 - 2)
	Audio.play(&"checkpoint")
	set_process(true)
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(_sprite, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
