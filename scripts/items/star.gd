class_name Star
extends Area2D
## Skrytá hviezda – v každom leveli sú tri (GDD kap. 2.5).
## Už nájdená hviezda je priesvitná, ale stále sa dá zobrať.

@export var star_id: String = "a"

var _already_found := false
var _time := 0.0

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var run := GameState.current_run
	if run != null:
		_already_found = GameState.progress.get_stars(run.level_id).has(star_id)
	if _already_found:
		modulate.a = 0.45


func _process(delta: float) -> void:
	_time += delta
	_sprite.position.y = sin(_time * 3.0) * 6.0
	_sprite.rotation = sin(_time * 2.0) * 0.15


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or GameState.current_run == null:
		return
	GameState.current_run.add_star(star_id)
	Audio.play(&"star")
	set_deferred("monitoring", false)
	set_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "rotation", TAU, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
