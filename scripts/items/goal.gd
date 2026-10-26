class_name Goal
extends Area2D
## Cieľová brána levelu.

signal reached


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		set_deferred("monitoring", false)
		reached.emit()


func _draw() -> void:
	draw_rect(Rect2(-40, -120, 10, 120), Color("6d4c41"))
	draw_rect(Rect2(30, -120, 10, 120), Color("6d4c41"))
	draw_rect(Rect2(-40, -130, 80, 14), Color("e8553c"))
