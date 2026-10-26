extends "res://tests/test_suite.gd"

var progression: Node
var game_state: Node
var level: LevelDefinition


func before_each() -> void:
	game_state = tree.root.get_node("GameState")
	progression = tree.root.get_node("ProgressionManager")
	game_state.set_progress(PlayerProgress.new())
	level = progression.get_level("level_01")


func _run(coins: int, items: Array[String] = []) -> LevelRun:
	var run := LevelRun.new("level_01", 3, Vector2.ZERO)
	run.add_coins(coins)
	for item in items:
		if item.begins_with("star:"):
			run.add_star(item.trim_prefix("star:"))
		else:
			run.collect_item(item)
	return run


func test_fail_keeps_half_coins() -> void:
	var result: Dictionary = progression.finish_run(_run(15, ["chest:main", "star:a"]), false, level)
	check_eq(result.coins, 7, "polovica zaokrúhlená nadol")
	check_eq(game_state.progress.coins, 7, "mince v progrese")
	check_eq(game_state.progress.gold, 0, "pri neúspechu žiadne zlato")
	check(game_state.progress.get_stars("level_01").is_empty(), "pri neúspechu žiadne hviezdy")
	check(not progression.is_completed("level_01"), "level nie je dokončený")


func test_success_rewards() -> void:
	var result: Dictionary = progression.finish_run(_run(10, ["chest:main"]), true, level)
	check_eq(result.coins, 10 + level.completion_coins, "mince + odmena za dokončenie")
	check_eq(result.gold, 2, "prvý priechod + truhlica")
	check(progression.is_completed("level_01"), "level dokončený")


func test_repeat_does_not_duplicate_one_time_rewards() -> void:
	progression.finish_run(_run(10, ["chest:main"]), true, level)
	var second: Dictionary = progression.finish_run(_run(10, ["chest:main"]), true, level)
	check_eq(second.gold, 0, "zlato iba raz")
	check_eq(game_state.progress.gold, 2, "celkové zlato")
	check_eq(second.coins, 10 + level.completion_coins, "mince sa pri opakovaní dávajú")


func test_all_stars_bonus_across_runs() -> void:
	progression.finish_run(_run(0, ["star:a", "star:b"]), true, level)
	var second: Dictionary = progression.finish_run(_run(0, ["star:a", "star:c"]), true, level)
	check_eq(second.new_stars, 1, "iba jedna nová hviezda")
	check_eq(second.gold, 1, "bonus za všetky hviezdy")
	check_eq(game_state.progress.get_stars("level_01").size(), 3, "tri hviezdy uložené")
