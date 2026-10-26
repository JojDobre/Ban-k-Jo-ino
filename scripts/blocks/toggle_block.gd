class_name ToggleBlock
extends StaticBody2D
## Modrý blok, ktorý prepína vypínač: raz je pevný, raz priehľadný a dá sa ním prejsť.

@export var starts_solid: bool = true

var _solid := true

@onready var _sprite: Sprite2D = $Sprite
@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group(&"toggle_block")
	_apply(starts_solid, false)


func toggle() -> void:
	_apply(not _solid, true)


func _apply(solid: bool, animate: bool) -> void:
	_solid = solid
	_shape.set_deferred("disabled", not solid)
	var alpha := 1.0 if solid else 0.25
	if animate:
		var tween := create_tween()
		tween.tween_property(_sprite, "modulate:a", alpha, 0.15)
		tween.parallel().tween_property(_sprite, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(_sprite, "scale", Vector2.ONE, 0.1)
	else:
		_sprite.modulate.a = alpha
