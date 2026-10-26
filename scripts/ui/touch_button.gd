class_name TouchButton
extends Control
## Vizuál jedného dotykového tlačidla. Dotyky spracúva TouchControls.

enum Icon { LEFT, RIGHT, JUMP }

@export var action: StringName = &"move_left"
@export var icon: Icon = Icon.LEFT

var pressed: bool = false:
	set(value):
		pressed = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	draw_circle(center, radius, Color(1, 1, 1, 0.45 if pressed else 0.22))
	draw_arc(center, radius - 2, 0, TAU, 48, Color(1, 1, 1, 0.6), 3.0, true)
	var s := radius * 0.4
	var points: PackedVector2Array
	match icon:
		Icon.LEFT:
			points = [center + Vector2(-s, 0), center + Vector2(s * 0.7, -s), center + Vector2(s * 0.7, s)]
		Icon.RIGHT:
			points = [center + Vector2(s, 0), center + Vector2(-s * 0.7, -s), center + Vector2(-s * 0.7, s)]
		Icon.JUMP:
			points = [center + Vector2(0, -s), center + Vector2(-s, s * 0.7), center + Vector2(s, s * 0.7)]
	draw_colored_polygon(points, Color(1, 1, 1, 0.85))
