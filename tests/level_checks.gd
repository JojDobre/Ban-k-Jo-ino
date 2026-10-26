extends Node
## Overí, že kľúčové miesta level_01 sú dosiahnuteľné reálnou fyzikou hráča:
## godot --headless --path . --fixed-fps 60 res://tests/level_checks.tscn
## Výstup „VÝSLEDOK: OK“ alebo zoznam chýb; návratový kód 0/1.

const TILE := 64.0

var _level: LevelController
var _failures: Array[String] = []


func _ready() -> void:
	SaveManager.autosave_enabled = false
	GameState.set_progress(PlayerProgress.new())
	_level = load("res://scenes/levels/level_01.tscn").instantiate()
	add_child(_level)
	_run.call_deferred()


func _run() -> void:
	var p := _level.player

	# 1. Pružina vynesie Jožina na oblak s pokladom (riadok 3).
	await _place(Vector2(58.5 * TILE, 4 * TILE))
	var top := await _track_min_y(90)
	_check(top < 3 * TILE - 36, "pružina: najvyšší bod %.0f, treba nad %.0f" % [top, 3 * TILE - 36])

	# 2. Z oblaku v tajnej jame sa dá vyskočiť doprava na zem (riadok 8).
	await _place(Vector2(78.5 * TILE, 10 * TILE - 40))
	_hold(&"move_right", true)
	_hold(&"jump", true)
	await _frames(70)
	_hold(&"jump", false)
	await _frames(40)
	_hold(&"move_right", false)
	_check(p.global_position.x > 80 * TILE and p.is_on_floor() and p.global_position.y < 9 * TILE, "tajná jama: Jožino sa nedostal von (%s)" % p.global_position)

	# 3. Hviezda C (riadok 3) sa nedá dosiahnuť bežným skokom zo zeme...
	await _place(Vector2(112.5 * TILE, 9 * TILE - 40))
	_hold(&"jump", true)
	var plain := await _track_min_y(60)
	_hold(&"jump", false)
	_check(plain - 36 > 3 * TILE + 56, "hviezda C je dosiahnuteľná aj bez nepriateľa (vrch hlavy %.0f)" % (plain - 36))

	# ...ale odrazom od nepriateľa s držaným skokom áno.
	var enemy := _level.get_node("Enemies").get_child(_level.get_node("Enemies").get_child_count() - 1) as Node2D
	await _place(enemy.global_position + Vector2(0, -200), 8)
	_hold(&"jump", true)
	var bounced := await _track_min_y(60)
	_hold(&"jump", false)
	_check(not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.modulate.a < 1.0, "hviezda C: nepriateľ nebol porazený skokom zhora")
	_check(bounced - 36 < 3 * TILE + 56, "hviezda C: odraz od nepriateľa nestačí (vrch hlavy %.0f)" % (bounced - 36))

	# 4. Hviezda A (riadok 1) je dosiahnuteľná z horného oblaku (riadok 4).
	await _place(Vector2(30.5 * TILE, 4 * TILE - 40))
	_hold(&"jump", true)
	var star_a := await _track_min_y(60)
	_hold(&"jump", false)
	_check(star_a - 36 < 1 * TILE + 56, "hviezda A: nedosiahnuteľná (vrch hlavy %.0f)" % (star_a - 36))

	print("VÝSLEDOK: OK" if _failures.is_empty() else "VÝSLEDOK: CHYBY\n  " + "\n  ".join(_failures))
	_hold(&"jump", false)
	_level.queue_free()
	await _frames(2)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _place(at: Vector2, settle_frames: int = 20) -> void:
	var run := _level.run
	run.hearts = run.max_hearts
	_level.player.respawn(at)
	_level.player.input_enabled = true
	await _frames(settle_frames)


func _track_min_y(frames: int) -> float:
	var min_y := _level.player.global_position.y
	for i in frames:
		await get_tree().physics_frame
		min_y = minf(min_y, _level.player.global_position.y)
	return min_y


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _hold(action: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
