class_name SecretArea
extends Area2D
## Tajné miesto za falošnou stenou. Stena (TileMapLayer bez kolízie, kreslený pred Jožinom)
## sa pri vstupe zprehľadní. Prvé nájdenie sa započíta do pokusu.

const HIDDEN_ALPHA := 0.25

var _found := false
var _tween: Tween

@onready var _wall: CanvasItem = $Wall


func _ready() -> void:
	add_to_group(&"secret_area")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	_fade_to(HIDDEN_ALPHA)
	if not _found:
		_found = true
		var run := GameState.current_run
		if run != null:
			run.add_secret()
		Audio.play(&"secret")
		Effects.floating_text(self, body.global_position + Vector2(0, -70), "Tajné miesto!", Color("ffe14d"), 34)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_fade_to(1.0)


func _fade_to(alpha: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_wall, "modulate:a", alpha, 0.3)
