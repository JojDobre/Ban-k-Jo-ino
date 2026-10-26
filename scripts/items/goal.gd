class_name Goal
extends Area2D
## Cieľové dvere levelu. Pôvod uzla je na zemi pod dverami.

signal reached


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		set_deferred("monitoring", false)
		reached.emit()
