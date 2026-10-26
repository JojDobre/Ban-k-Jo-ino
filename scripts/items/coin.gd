class_name Coin
extends Area2D
## Minca – pripočíta sa do aktuálneho pokusu (GDD kap. 2.5).

@export var value: int = 1

const MAGNET_SPEED := 650.0

var _player: Player


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	if _player == null or _player.magnet_radius <= 0.0:
		return
	var target := _player.global_position
	if global_position.distance_to(target) < _player.magnet_radius:
		global_position = global_position.move_toward(target, MAGNET_SPEED * delta)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or GameState.current_run == null:
		return
	GameState.current_run.add_coins(value)
	set_deferred("monitoring", false)
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 30, 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 12, Color("f2b705"))
	draw_circle(Vector2.ZERO, 7, Color("ffd84d"))
