extends Node
## Uloží screenshoty levelu na zadaných miestach (vyžaduje grafiku, nie --headless):
## xvfb-run godot --path . res://tests/screenshots.tscn -- <výstupný_priečinok> [x1,y1 x2,y2 ... win]
## „win“ ukončí level úspechom a odfotí obrazovku výsledkov.

var _level: LevelController
var _spots: Array[Vector2] = [Vector2(200, 540)]
var _out_dir := "user://screenshots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = args[0]
	if args.size() > 1:
		_spots.clear()
		for arg in args.slice(1):
			if arg == "win":
				_spots.append(Vector2.INF)
				continue
			var parts := arg.split(",")
			_spots.append(Vector2(float(parts[0]), float(parts[1])))
	DirAccess.make_dir_recursive_absolute(_out_dir)
	SaveManager.autosave_enabled = false
	GameState.set_progress(PlayerProgress.new())
	_level = load("res://scenes/levels/level_01.tscn").instantiate()
	add_child(_level)
	_level.get_node("Hud/TouchControls").visible = true
	_capture.call_deferred()


func _capture() -> void:
	for i in _spots.size():
		if _spots[i] == Vector2.INF:
			_level._finish(true)
			await get_tree().create_timer(LevelController.RESULTS_DELAY + 0.5).timeout
		else:
			_level.player.respawn(_spots[i])
			for f in 40:
				await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("%s/shot_%02d.png" % [_out_dir, i])
	get_tree().quit()
