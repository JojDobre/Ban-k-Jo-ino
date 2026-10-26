class_name TouchControls
extends Control
## Multitouch ovládanie (GDD kap. 2.2). Každý prst sa sleduje samostatne,
## takže hráč môže súčasne držať smer a skákať. Posun prsta medzi
## tlačidlami (doľava -> doprava) zmení smer bez zdvihnutia.

## Aktívna plocha je o toľko väčšia ako vizuál tlačidla.
@export var touch_padding: float = 28.0
## Zobraziť aj bez dotykovej obrazovky (ladenie na počítači).
@export var always_visible: bool = false

## index prsta -> TouchButton
var _touches: Dictionary = {}
var _buttons: Array[TouchButton] = []


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	for child in find_children("*", "TouchButton"):
		_buttons.append(child as TouchButton)
	visible = always_visible or DisplayServer.is_touchscreen_available()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_assign(touch.index, _button_at(touch.position) if touch.pressed else null)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_assign(drag.index, _button_at(drag.position))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		release_all()


func release_all() -> void:
	var held := _touches.values()
	_touches.clear()
	for button: TouchButton in held:
		_refresh(button)


func _button_at(pos: Vector2) -> TouchButton:
	for button in _buttons:
		if button.is_visible_in_tree() and button.get_global_rect().grow(touch_padding).has_point(pos):
			return button
	return null


func _assign(index: int, button: TouchButton) -> void:
	var previous: TouchButton = _touches.get(index)
	if previous == button:
		return
	if button == null:
		_touches.erase(index)
	else:
		_touches[index] = button
	_refresh(previous)
	_refresh(button)


## Akcia je stlačená, kým ju drží aspoň jeden prst.
func _refresh(button: TouchButton) -> void:
	if button == null:
		return
	var held := _touches.values().has(button)
	if held == button.pressed:
		return
	button.pressed = held
	if held:
		Input.action_press(button.action)
	else:
		Input.action_release(button.action)
