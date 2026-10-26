class_name Chest
extends Area2D
## Zlatý poklad (v GDD „truhlica“). Zlato sa pripíše iba pri úspešnom
## dokončení levelu, a iba raz – už vyzdvihnutý poklad je priesvitný.

@export var chest_id: String = "main"

var _taken := false
var _time := 0.0

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var run := GameState.current_run
	if run != null and GameState.progress.claimed_rewards.has(run.level_id + ":chest:" + chest_id):
		modulate.a = 0.45


func _process(delta: float) -> void:
	_time += delta
	_sprite.position.y = sin(_time * 2.5) * 5.0
	_sprite.scale = Vector2.ONE * (1.0 + sin(_time * 5.0) * 0.05)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Player or GameState.current_run == null:
		return
	if GameState.current_run.collect_item("chest:" + chest_id):
		_taken = true
		Audio.play(&"gold")
		set_process(false)
		var tween := create_tween()
		tween.tween_property(self, "position:y", position.y - 60, 0.4).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
		tween.tween_callback(queue_free)
