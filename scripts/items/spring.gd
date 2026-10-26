class_name Spring
extends Area2D
## Pružina – vystrelí Jožina vysoko, keď na ňu dopadne. Pôvod uzla je na zemi.

const TEXTURE_IDLE := preload("res://assets/items/spring.png")
const TEXTURE_OUT := preload("res://assets/items/spring_out.png")

@export var launch_velocity: float = -1450.0

@onready var _sprite: Sprite2D = $Sprite


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var player := body as Player
		# Pružina vystrelí pri dopade zhora aj pri nabehnutí zboku.
		if player != null and player.velocity.y >= 0.0:
			_launch(player)


func _launch(player: Player) -> void:
	player.launch(launch_velocity)
	Audio.play(&"spring")
	_sprite.texture = TEXTURE_OUT
	await get_tree().create_timer(0.25).timeout
	_sprite.texture = TEXTURE_IDLE
