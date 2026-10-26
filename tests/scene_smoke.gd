extends Node
## Otvorí každú obrazovku hry na pár snímok a vypíše „OBRAZOVKY: OK“ (chyby skriptov vidno vo výstupe):
## godot --headless --path . --fixed-fps 60 res://tests/scene_smoke.tscn

const SCENES := [
	"res://scenes/menus/main_menu.tscn",
	"res://scenes/world_map/world_map.tscn",
	"res://scenes/village/village.tscn",
	"res://scenes/menus/shop.tscn",
	"res://scenes/menus/settings.tscn",
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
]


func _ready() -> void:
	SaveManager.autosave_enabled = false
	_run.call_deferred()


func _run() -> void:
	var progress := PlayerProgress.new()
	progress.coins = 500
	progress.gold = 5
	progress.building_levels = {"house": 1, "mine": 2, "blacksmith": 1}
	progress.last_mine_claim = GameState.now() - 3600
	progress.items = {"start_shield": 1, "start_magnet": 1}
	GameState.set_progress(progress)
	for path: String in SCENES:
		var scene: Node = load(path).instantiate()
		add_child(scene)
		for i in 30:
			await get_tree().physics_frame
		print("otvorené: ", path)
		scene.queue_free()
		await get_tree().process_frame
	print("OBRAZOVKY: OK")
	get_tree().quit()
