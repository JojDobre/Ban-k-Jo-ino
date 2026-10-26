extends Node
## Simulácia hrania prvého levelu bez grafiky (overí, že scéna beží a fyzika funguje):
## godot --headless --path . --fixed-fps 60 res://tests/smoke_level.tscn

var _level: LevelController
var _frame := 0
var _log: Array[String] = []


func _ready() -> void:
	SaveManager.save_path = "user://smoke_save.json"
	SaveManager.autosave_enabled = false
	GameState.set_progress(PlayerProgress.new())
	_level = load("res://scenes/levels/level_01.tscn").instantiate()
	add_child(_level)


func _physics_process(_delta: float) -> void:
	_frame += 1
	var p := _level.player
	match _frame:
		30:
			_log.append("na zemi: %s, y=%.1f" % [p.is_on_floor(), p.global_position.y])
			Input.action_press("move_right")
		70:
			_log.append("po behu x=%.1f vx=%.1f" % [p.global_position.x, p.velocity.x])
			Input.action_press("jump")
		72:
			Input.action_release("jump")
		76:
			_log.append("krátky skok vy=%.1f" % p.velocity.y)
		110:
			Input.action_press("jump")
		140:
			_log.append("dlhý skok y=%.1f" % p.global_position.y)
			Input.action_release("jump")
	# Potom stále beží doprava a pravidelne skáče.
	if _frame > 140 and _frame % 40 == 0:
		Input.action_press("jump")
	if _frame > 140 and _frame % 40 == 30:
		Input.action_release("jump")
	if _frame % 120 == 0:
		_log.append("  snímka %d: x=%.0f y=%.0f srdcia=%d mince=%d" % [_frame, p.global_position.x, p.global_position.y, _level.run.hearts, _level.run.coins])
	if _frame == 1800 or _level._finished:
		var run := _level.run
		_log.append("KONIEC snímka %d: x=%.0f, mince=%d, srdcia=%d, hviezdy=%s, ukončené=%s" % [_frame, p.global_position.x, run.coins, run.hearts, run.stars, _level._finished])
		_log.append("progres: mince=%d zlato=%d" % [GameState.progress.coins, GameState.progress.gold])
		print("\n".join(_log))
		_quit()


func _quit() -> void:
	set_physics_process(false)
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)
	_level.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
