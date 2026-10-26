class_name LevelNode
extends Control
## Uzol levelu na mape sveta: číslo, zámok alebo hviezdy. Kreslí sa kódom.

signal selected(level: LevelDefinition)

const STAR := preload("res://assets/items/star.png")
const LOCK := preload("res://assets/icons/locked.png")
const RADIUS := 56.0
const OUTLINE := Color("3b2b24")

var level: LevelDefinition
var number: int = 1
var _time := randf() * TAU


func setup(level_definition: LevelDefinition, level_number: int) -> void:
	level = level_definition
	number = level_number
	custom_minimum_size = Vector2(RADIUS * 2 + 20, RADIUS * 2 + 50)
	size = custom_minimum_size
	pivot_offset = Vector2(size.x * 0.5, RADIUS + 10)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	# Aktuálny (odomknutý, nedokončený) uzol jemne pulzuje.
	if _is_unlocked() and not _is_completed():
		scale = Vector2.ONE * (1.0 + sin(_time * 3.0) * 0.04)


func _gui_input(event: InputEvent) -> void:
	var released: bool = (event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and not event.pressed)
	if released:
		selected.emit(level)
		accept_event()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, RADIUS + 10)
	var unlocked := _is_unlocked()
	var fill := Color("9aa3ad")
	if _is_completed():
		fill = Color("4cb84a")
	elif unlocked:
		fill = Color("ff9e33")
	draw_circle(center + Vector2(0, 6), RADIUS, Color(0, 0, 0, 0.2))
	draw_circle(center, RADIUS, OUTLINE)
	draw_circle(center, RADIUS - 6, fill)
	draw_arc(center + Vector2(0, -8), RADIUS - 22, PI * 1.15, PI * 1.85, 16, Color(1, 1, 1, 0.35), 8.0, true)
	if unlocked:
		var font := get_theme_default_font()
		var text := str(number)
		var font_size := 52
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pos := center + Vector2(-text_size.x * 0.5, text_size.y * 0.3)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, OUTLINE)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
		var found := GameState.progress.get_stars(level.id).size()
		for i in ProgressionManager.STARS_PER_LEVEL:
			var star_pos := center + Vector2((i - 1) * 34, RADIUS + 14)
			var rect := Rect2(star_pos - Vector2(18, 18), Vector2(36, 36))
			draw_texture_rect(STAR, rect, false, Color.WHITE if i < found else Color(0.2, 0.15, 0.1, 0.45))
	else:
		draw_texture_rect(LOCK, Rect2(center - Vector2(26, 26), Vector2(52, 52)), false, Color(1, 1, 1, 0.95))


func _is_unlocked() -> bool:
	return level != null and ProgressionManager.is_unlocked(level.id)


func _is_completed() -> bool:
	return level != null and ProgressionManager.is_completed(level.id)
