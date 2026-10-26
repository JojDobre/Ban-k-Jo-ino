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
		# Pružina vystrelí pri dopade zhora aj pri nabehnutí zboku. Poloha sa overí ešte raz –
		# zoznam prekrytí je o snímku starší (napr. po návrate Jožina na checkpoint).
		if player != null and player.velocity.y >= 0.0 and _is_on_spring(player):
			_launch(player)


func _is_on_spring(player: Player) -> bool:
	var feet := player.get_feet_y()
	return absf(player.global_position.x - global_position.x) < 44.0 and feet > global_position.y - 70.0 and feet <= global_position.y + 4.0


func _launch(player: Player) -> void:
	player.launch(launch_velocity)
	Audio.play(&"spring")
	_sprite.texture = TEXTURE_OUT
	await get_tree().create_timer(0.25).timeout
	_sprite.texture = TEXTURE_IDLE
