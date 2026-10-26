class_name Star
extends Area2D
## Skrytá hviezda – v každom leveli sú tri (GDD kap. 2.5).
## Už nájdená hviezda je priesvitná, ale stále sa dá zobrať.

@export var star_id: String = "a"

var _already_found := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var run := GameState.current_run
	if run != null:
		_already_found = GameState.progress.get_stars(run.level_id).has(star_id)
	if _already_found:
		modulate.a = 0.4


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or GameState.current_run == null:
		return
	GameState.current_run.add_star(star_id)
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)


func _draw() -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := 18.0 if i % 2 == 0 else 8.0
		var angle := -PI / 2 + i * PI / 5
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color("ffe14d"))
	points.append(points[0])
	draw_polyline(points, Color("c98a00"), 2.0)
