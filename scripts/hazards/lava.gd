class_name Lava
extends Area2D
## Láva na dne jamy: ako pád do jamy – Jožino stratí srdce a vráti sa na checkpoint.
## Kresba sa vlní cez shader a z hladiny občas vyskočia bublinky.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		Effects.burst(self, body.global_position + Vector2(0, 30), Color("ff8a2a"), 16, 300.0, 1.0, 600.0)
		(body as Player).fall_into_hazard()
