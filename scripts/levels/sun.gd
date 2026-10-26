extends Node2D
## Slnko na oblohe: pomaly sa otáčajúce lúče a jemne pulzujúca žiara.
## Drží sa pri pravom hornom rohu obrazovky aj pri inom pomere strán.

@export var ray_gradient: Gradient
@export var ray_count: int = 12
@export var ray_length: float = 230.0

const MARGIN := Vector2(240, 120)

var _time := 0.0

@onready var _glow: Sprite2D = $Glow


func _process(delta: float) -> void:
	_time += delta
	position = Vector2(get_viewport().get_visible_rect().size.x - MARGIN.x, MARGIN.y)
	_glow.scale = Vector2.ONE * (1.6 + sin(_time * 1.3) * 0.08)
	queue_redraw()


func _draw() -> void:
	if ray_gradient == null:
		return
	var inner := ray_gradient.sample(0.0)
	var outer := ray_gradient.sample(1.0)
	for i in ray_count:
		var angle := _time * 0.15 + TAU * i / ray_count
		var width := 0.09
		var points := PackedVector2Array([
			Vector2.ZERO,
			Vector2.from_angle(angle - width) * ray_length,
			Vector2.from_angle(angle + width) * ray_length,
		])
		draw_polygon(points, PackedColorArray([inner, outer, outer]))
