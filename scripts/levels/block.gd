@tool
class_name Block
extends StaticBody2D
## Dočasný blok terénu pre prototyp (pôvod vľavo hore).
## Vo fáze 2 ho nahradí TileMapLayer s tilesetom.

@export var size: Vector2 = Vector2(256, 64):
	set(value):
		size = value
		_update()
## Plošina, na ktorú sa dá vyskočiť zospodu.
@export var one_way: bool = false:
	set(value):
		one_way = value
		_update()
@export var color: Color = Color("8d6e4a")
@export var top_color: Color = Color("5ec26a")

var _shape: CollisionShape2D


func _ready() -> void:
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_update()


func _update() -> void:
	if _shape == null:
		return
	(_shape.shape as RectangleShape2D).size = size
	_shape.position = size * 0.5
	_shape.one_way_collision = one_way
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_rect(Rect2(0, 0, size.x, minf(14.0, size.y)), top_color)
