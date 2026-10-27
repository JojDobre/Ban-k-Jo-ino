class_name Villager
extends AnimatedSprite3D
## Obyvateľ dediny: plochá postavička (rovnaké animácie ako hráč) otočená ku kamere,
## ktorá sa pomaly prechádza okolo svojho domova.

## Oblek z assets/player/<oblek>/frames.tres.
@export var outfit: String = "old"
@export var height: float = 2.3
@export var wander_radius: float = 1.8
@export var speed: float = 1.4

var home := Vector3.ZERO


func _ready() -> void:
	sprite_frames = load("res://assets/player/%s/frames.tres" % outfit)
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shaded = false
	var frame := sprite_frames.get_frame_texture(&"idle", 0)
	pixel_size = height / frame.get_height()
	centered = true
	offset.y = frame.get_height() * 0.5
	home = position
	play(&"idle")
	_wander()


func set_outfit(new_outfit: String) -> void:
	outfit = new_outfit
	sprite_frames = load("res://assets/player/%s/frames.tres" % outfit)
	play(&"idle")


func _wander() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(1.5, 4.0)).timeout
		if not is_inside_tree():
			return
		var angle := randf() * TAU
		var target := home + Vector3(cos(angle), 0, sin(angle)) * randf_range(0.3, wander_radius)
		if absf(target.x - position.x) > 0.05:
			flip_h = target.x < position.x
		play(&"run")
		speed_scale = 0.55
		var tween := create_tween()
		tween.tween_property(self, "position", target, position.distance_to(target) / speed)
		await tween.finished
		speed_scale = 1.0
		play(&"idle")
