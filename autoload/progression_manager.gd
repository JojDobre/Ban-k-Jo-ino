extends Node
## Odomykanie a dokončenie levelov, hviezdy a vyhodnotenie pokusu (GDD kap. 2.4, 4.2).

signal level_completed(level_id: String)

const STARS_PER_LEVEL := 3
const FAIL_COIN_SHARE := 0.5

## Explicitný zoznam – DirAccess nad res:// sa v exportovanom builde správa inak.
const LEVELS: Array[LevelDefinition] = [
	preload("res://data/levels/level_01.tres"),
]


func get_level(level_id: String) -> LevelDefinition:
	for level in LEVELS:
		if level.id == level_id:
			return level
	return null


func is_unlocked(level_id: String) -> bool:
	return GameState.progress.unlocked_levels.has(level_id)


func is_completed(level_id: String) -> bool:
	return GameState.progress.completed_levels.has(level_id)


## Pripíše výsledok pokusu do trvalého progresu a vráti súhrn pre obrazovku výsledkov.
func finish_run(run: LevelRun, success: bool, level: LevelDefinition) -> Dictionary:
	var result := {"success": success, "coins": 0, "gold": 0, "new_stars": 0, "first_clear": false}
	if not success:
		result.coins = int(floor(run.coins * FAIL_COIN_SHARE))
		EconomyManager.grant_reward("level_fail", result.coins, 0)
		return result

	var progress := GameState.progress
	var level_id := run.level_id

	result.coins = run.coins + level.completion_coins
	EconomyManager.grant_reward("level", result.coins, 0)

	if EconomyManager.claim_one_time(level_id + ":first_clear", 0, level.first_clear_gold):
		result.gold += level.first_clear_gold
		result.first_clear = true

	for item in run.collected_items:
		if item.begins_with("chest:") and EconomyManager.claim_one_time(level_id + ":" + item, 0, 1):
			result.gold += 1

	var known_stars := progress.get_stars(level_id)
	for star in run.stars:
		if not known_stars.has(star):
			known_stars.append(star)
			result.new_stars += 1
	progress.stars[level_id] = known_stars
	if known_stars.size() >= STARS_PER_LEVEL and EconomyManager.claim_one_time(level_id + ":all_stars", 0, 1):
		result.gold += 1

	if not progress.completed_levels.has(level_id):
		progress.completed_levels.append(level_id)
	_unlock_available_levels()

	level_completed.emit(level_id)
	SaveManager.request_save()
	return result


func _unlock_available_levels() -> void:
	var progress := GameState.progress
	for level in LEVELS:
		if progress.unlocked_levels.has(level.id):
			continue
		var can_unlock := true
		for required in level.unlock_requirements:
			if not progress.completed_levels.has(required):
				can_unlock = false
				break
		if can_unlock:
			progress.unlocked_levels.append(level.id)
