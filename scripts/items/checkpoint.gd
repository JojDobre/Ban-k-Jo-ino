class_name Checkpoint
extends Area2D
## Po strate srdca pádom sa Jožino vráti na posledný dosiahnutý checkpoint (GDD kap. 2.4).

var _active := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _active or not body is Player or GameState.current_run == null:
		return
	_active = true
	# Checkpoint stojí na zemi, Jožino sa objaví tesne nad ním.
	GameState.current_run.checkpoint = global_position + Vector2(0, -Player.BODY_SIZE.y * 0.5 - 2)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-3, -80, 6, 80), Color("5a4630"))
	var flag_color := Color("4caf50") if _active else Color("bdbdbd")
	draw_colored_polygon(PackedVector2Array([Vector2(3, -80), Vector2(40, -68), Vector2(3, -56)]), flag_color)
