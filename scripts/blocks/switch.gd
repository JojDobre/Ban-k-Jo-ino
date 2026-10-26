class_name ToggleSwitch
extends Area2D
## Vypínač na zemi: keď naň Jožino skočí, prepne všetky modré bloky v leveli.
## Znova sa dá stlačiť až po zídení z neho. Pôvod uzla je na zemi.

const TEXTURE_UP := preload("res://assets/blocks/switch_blue.png")
const TEXTURE_DOWN := preload("res://assets/blocks/switch_blue_pressed.png")

var _armed := true

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_exited.connect(func(body: Node2D) -> void:
		if body is Player:
			_armed = true
			_sprite.texture = TEXTURE_UP)


func _physics_process(_delta: float) -> void:
	if not _armed:
		return
	for body in get_overlapping_bodies():
		var player := body as Player
		if player != null and player.velocity.y >= 0.0:
			_press()
			return


func _press() -> void:
	_armed = false
	_sprite.texture = TEXTURE_DOWN
	Audio.play(&"switch")
	Effects.burst(self, global_position + Vector2(0, -20), Color("4fa3ff"), 10, 160.0, 0.6, 200.0)
	get_tree().call_group(&"toggle_block", &"toggle")
