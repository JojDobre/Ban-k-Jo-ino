extends Node
## Ovládanie 3D dediny bez grafiky: ťuknutie na budovu otvorí panel, ťuknutie na vozík
## vyberie produkciu bane, ťahanie posunie kameru a dva prsty ju priblížia.
## godot --headless --path . --fixed-fps 60 res://tests/village_input.tscn  -> „DEDINA: OK“

var _failed := 0
var _village: Node3D
var _camera: VillageCamera


func _ready() -> void:
	SaveManager.autosave_enabled = false
	_run.call_deferred()


func _run() -> void:
	var progress := PlayerProgress.new()
	progress.coins = 500
	progress.gold = 5
	progress.building_levels = {"house": 1, "mine": 1}
	progress.last_mine_claim = GameState.now() - 2 * 3600
	GameState.set_progress(progress)
	_village = load(GameState.SCENE_VILLAGE).instantiate()
	add_child(_village)
	_camera = _village.get_node("%Camera")
	await _frames(90)
	_camera.snap_to(Vector3.ZERO, 26.0)
	await _frames(5)

	var panel: Control = _village.get_node("%Panel")
	await _tap(_village.get_node("%House").global_position + Vector3(0, 2, 0))
	_check(panel.visible, "ťuknutie na dom otvorí panel")
	_check(_village.get_node("%PanelTitle").text == "Jožinov dom", "panel ukazuje dom")
	_village.get_node("%CloseButton").pressed.emit()
	_check(not panel.visible, "panel sa zavrie")

	await _tap(_village.get_node("%Mine").global_position + Vector3(0, 1.5, 0))
	_check(panel.visible and _village.get_node("%PanelTitle").text == "Baňa", "ťuknutie na baňu otvorí jej panel")
	var buy: Button = _village.get_node("%BuyButton")
	_check(not buy.disabled, "baňu sa dá vylepšiť")
	_village.get_node("%CloseButton").pressed.emit()

	var coins := GameState.progress.coins
	await _tap((_village.get_node("%Cart") as MineCart).global_position + Vector3(0, 0.6, 0))
	_check(GameState.progress.coins > coins, "ťuknutie na vozík pridá mince (%d -> %d)" % [coins, GameState.progress.coins])
	_check(not panel.visible, "vozík neotvára panel")

	var focus := _camera.focus
	await _drag(Vector2(640, 400), Vector2(-200, 0))
	await _frames(40)
	_check(_camera.focus.x > focus.x + 1.0, "ťahanie doľava posunie pohľad doprava")
	_check(not panel.visible, "ťahanie neotvorí panel")

	var distance := _camera.distance
	await _pinch(120.0, 360.0)
	await _frames(40)
	_check(_camera.distance < distance - 2.0, "roztiahnutie dvoch prstov priblíži (%.1f -> %.1f)" % [distance, _camera.distance])

	print("modelov v dedine: ", _village.find_children("*", "MeshInstance3D", true, false).size())
	print("DEDINA: OK" if _failed == 0 else "DEDINA: %d chýb" % _failed)
	get_tree().quit(1 if _failed > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: ", message)
	else:
		_failed += 1
		print("  CHYBA: ", message)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _screen(point: Vector2) -> Vector2:
	return get_viewport().get_screen_transform() * point


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	await _frames(2)


func _touch(index: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var touch := InputEventScreenTouch.new()
	touch.index = index
	touch.position = _screen(pos)
	touch.pressed = pressed
	return touch


func _tap(world: Vector3) -> void:
	# Kamera sa po výbere budovy ešte presúva – počkáme, kým zastane.
	await _frames(60)
	var pos := _camera.unproject_position(world)
	await _send(_touch(0, pos, true))
	await _send(_touch(0, pos, false))
	await _frames(3)


func _drag(start: Vector2, offset: Vector2) -> void:
	await _send(_touch(0, start, true))
	for i in 10:
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = _screen(start + offset * (i + 1) / 10.0)
		drag.relative = offset / 10.0
		await _send(drag)
	await _send(_touch(0, start + offset, false))


func _pinch(from_gap: float, to_gap: float) -> void:
	var center := Vector2(640, 400)
	await _send(_touch(0, center - Vector2(from_gap, 0), true))
	await _send(_touch(1, center + Vector2(from_gap, 0), true))
	for i in 10:
		var gap := lerpf(from_gap, to_gap, (i + 1) / 10.0)
		var drag := InputEventScreenDrag.new()
		drag.index = 1
		drag.position = _screen(center + Vector2(gap, 0))
		await _send(drag)
	await _send(_touch(1, center + Vector2(to_gap, 0), false))
	await _send(_touch(0, center - Vector2(from_gap, 0), false))
