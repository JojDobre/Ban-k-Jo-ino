class_name Coin
extends Area2D
## Minca – pripočíta sa do aktuálneho pokusu (GDD kap. 2.5).

const MAGNET_SPEED := 650.0
const SPIN_SPEED := 3.0

@export var value: int = 1

var _player: Player
var _time := 0.0
var _collected := false

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player") as Player
	# Každá minca sa točí v inej fáze, aby rad mincí pôsobil živo.
	_time = global_position.x * 0.01


func _physics_process(delta: float) -> void:
	_time += delta
	_sprite.scale.x = maxf(absf(cos(_time * SPIN_SPEED)), 0.12)
	if _collected or _player == null:
		return
	var radius := _player.get_magnet_radius()
	if radius <= 0.0:
		return
	var target := _player.global_position
	if global_position.distance_to(target) < radius:
		global_position = global_position.move_toward(target, MAGNET_SPEED * delta)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body is Player or GameState.current_run == null:
		return
	_collected = true
	GameState.current_run.add_coins(value)
	Audio.play(&"coin", 0.08)
	Effects.sparkle(self, global_position)
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 40, 0.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.4, 1.4), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
