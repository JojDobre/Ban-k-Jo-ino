extends Node
## Screenshot ľubovoľnej obrazovky (vyžaduje grafiku, v kontajneri cez xvfb):
## xvfb-run godot --path . res://tests/scene_shot.tscn -- <výstup.png> <res://scéna.tscn> [čakanie_s]
## Pred otvorením sa načíta ukážkový postup (mince, dokončený level), aby obrazovky neboli prázdne.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	var scene_path := args[1]
	var wait := float(args[2]) if args.size() > 2 else 1.0
	SaveManager.autosave_enabled = false
	var progress := PlayerProgress.new()
	progress.coins = 320
	progress.gold = 4
	progress.completed_levels.append("level_01")
	progress.unlocked_levels.append("level_02")
	progress.stars["level_01"] = ["a", "c"]
	progress.building_levels = {"house": 1, "mine": 1}
	progress.last_mine_claim = GameState.now() - 3 * 3600
	progress.owned_outfits.append("yellow")
	GameState.set_progress(progress)
	# Obrazovka sa vloží ako potomok – zmena scény by zrušila aj tento skript.
	add_child(load(scene_path).instantiate())
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()
