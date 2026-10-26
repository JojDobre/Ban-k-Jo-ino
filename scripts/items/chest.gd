class_name Chest
extends Area2D
## Truhlica so zlatom. Zlato sa pripíše iba pri úspešnom dokončení levelu, a iba raz.

@export var chest_id: String = "main"

var _opened := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var run := GameState.current_run
	if run != null and GameState.progress.claimed_rewards.has(run.level_id + ":chest:" + chest_id):
		_opened = true


func _on_body_entered(body: Node2D) -> void:
	if _opened or not body is Player or GameState.current_run == null:
		return
	if GameState.current_run.collect_item("chest:" + chest_id):
		_opened = true
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-22, -16, 44, 32), Color("8b5a2b"))
	draw_rect(Rect2(-22, -16, 44, 32), Color("4a2e12"), false, 3.0)
	if _opened:
		draw_rect(Rect2(-18, -24, 36, 8), Color("ffd84d"))
	else:
		draw_rect(Rect2(-4, -4, 8, 10), Color("ffd84d"))
