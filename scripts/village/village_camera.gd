class_name VillageCamera
extends Camera3D
## Šikmá kamera nad dedinou: posun ťahaním jedného prsta (myšou), priblíženie
## dvoma prstami (kolieskom). Pohyb je vyhladený a obmedzený na okraje dediny.

@export var pitch_degrees: float = 50.0
@export var distance: float = 26.0
@export var min_distance: float = 12.0
@export var max_distance: float = 34.0
## Povolená oblasť pre bod, na ktorý sa kamera pozerá (x, z).
@export var bounds: Rect2 = Rect2(-12, -8, 24, 14)
@export var smoothing: float = 10.0

var focus := Vector3.ZERO
var _target_focus := Vector3.ZERO
var _target_distance := 26.0


func _ready() -> void:
	_target_distance = distance
	_target_focus = focus
	_apply()


func _process(delta: float) -> void:
	var weight := 1.0 - exp(-smoothing * delta)
	focus = focus.lerp(_target_focus, weight)
	distance = lerpf(distance, _target_distance, weight)
	_apply()


## Okamžite nastaví pohľad (bez vyhladenia).
func snap_to(new_focus: Vector3, new_distance: float) -> void:
	_target_focus = _clamp(new_focus)
	_target_distance = clampf(new_distance, min_distance, max_distance)
	focus = _target_focus
	distance = _target_distance
	_apply()


## Posun o pohyb prsta v pixeloch – svet ide spolu s prstom.
func pan_pixels(relative: Vector2) -> void:
	var view_height := get_viewport().get_visible_rect().size.y
	var world_per_pixel := 2.0 * _target_distance * tan(deg_to_rad(fov) * 0.5) / view_height
	var pitch := deg_to_rad(pitch_degrees)
	_target_focus.x -= relative.x * world_per_pixel
	_target_focus.z -= relative.y * world_per_pixel / sin(pitch)
	_target_focus = _clamp(_target_focus)


## factor < 1 priblíži, > 1 oddiali.
func zoom_by(factor: float) -> void:
	_target_distance = clampf(_target_distance * factor, min_distance, max_distance)


func move_focus_to(new_focus: Vector3) -> void:
	_target_focus = _clamp(new_focus)


func _clamp(point: Vector3) -> Vector3:
	return Vector3(clampf(point.x, bounds.position.x, bounds.end.x), 0.0, clampf(point.z, bounds.position.y, bounds.end.y))


func _apply() -> void:
	var pitch := deg_to_rad(pitch_degrees)
	position = focus + Vector3(0, sin(pitch), cos(pitch)) * distance
	rotation = Vector3(-pitch, 0, 0)
