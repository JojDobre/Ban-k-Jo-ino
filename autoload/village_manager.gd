extends Node
## Dedina: budovy, ich vylepšovanie a produkcia bane (GDD kap. 5).
## Mince a zlato mení iba cez EconomyManager.

signal building_upgraded(building_id: String, level: int)
signal mine_claimed(coins: int)

const HOUSE := "house"
const MINE := "mine"
const BLACKSMITH := "blacksmith"
## Maximálna akumulácia produkcie bane (GDD kap. 5.3).
const MINE_CAP_HOURS := 8.0

const BUILDINGS: Array[BuildingDefinition] = [
	preload("res://data/buildings/house.tres"),
	preload("res://data/buildings/mine.tres"),
	preload("res://data/buildings/blacksmith.tres"),
]


func get_definition(building_id: String) -> BuildingDefinition:
	for building in BUILDINGS:
		if building.id == building_id:
			return building
	return null


func get_level(building_id: String) -> int:
	return GameState.progress.get_building_level(building_id)


## Opravený Jožinov dom odomkne stavebné miesta pre ostatné budovy.
func is_available(building_id: String) -> bool:
	return building_id == HOUSE or get_level(HOUSE) >= 1


func is_max_level(building_id: String) -> bool:
	var definition := get_definition(building_id)
	return definition == null or get_level(building_id) >= definition.max_level


## Cena ďalšej úrovne {"coins", "gold"}; prázdny slovník pri maximálnej úrovni.
func get_upgrade_cost(building_id: String) -> Dictionary:
	var definition := get_definition(building_id)
	if definition == null:
		return {}
	return definition.get_upgrade_cost(get_level(building_id))


## Koľko mincí a zlata chýba na ďalšiu úroveň (pre panel budovy).
func get_missing(building_id: String) -> Dictionary:
	var cost := get_upgrade_cost(building_id)
	if cost.is_empty():
		return {"coins": 0, "gold": 0}
	var progress := GameState.progress
	return {"coins": maxi(cost.coins - progress.coins, 0), "gold": maxi(cost.gold - progress.gold, 0)}


func can_upgrade(building_id: String) -> bool:
	var cost := get_upgrade_cost(building_id)
	return is_available(building_id) and not cost.is_empty() and EconomyManager.can_afford(cost.coins, cost.gold)


func upgrade(building_id: String) -> bool:
	if not can_upgrade(building_id):
		return false
	var level := get_level(building_id)
	if building_id == MINE and level > 0:
		# Produkcia doteraz sa vyplatí ešte podľa starej úrovne (GDD kap. 5.3).
		claim_mine()
	var cost := get_upgrade_cost(building_id)
	if not EconomyManager.spend(cost.coins, cost.gold):
		return false
	var progress := GameState.progress
	progress.building_levels[building_id] = level + 1
	if building_id == MINE and level == 0:
		# Nová baňa začne ťažiť až od postavenia.
		progress.last_mine_claim = GameState.now()
	SaveManager.request_save()
	building_upgraded.emit(building_id, level + 1)
	return true


func get_mine_rate() -> int:
	return get_definition(MINE).get_production(get_level(MINE))


func get_mine_capacity() -> int:
	return int(get_mine_rate() * MINE_CAP_HOURS)


func get_pending_mine_coins() -> int:
	return _mine_result().coins


## Naplnenie vozíka 0–1.
func get_mine_fill() -> float:
	var capacity := get_mine_capacity()
	return 0.0 if capacity <= 0 else clampf(float(get_pending_mine_coins()) / capacity, 0.0, 1.0)


## Vyzdvihne produkciu bane. Mena aj čas sa zmenia spolu a hneď sa uložia.
func claim_mine() -> int:
	var result := _mine_result()
	var progress := GameState.progress
	progress.last_mine_claim = result.new_last_claim
	if result.coins > 0:
		EconomyManager.grant_reward("mine", result.coins, 0)
		mine_claimed.emit(result.coins)
	SaveManager.request_save()
	return result.coins


func _mine_result() -> Dictionary:
	return MineProduction.calculate(GameState.progress.last_mine_claim, GameState.now(), get_mine_rate(), MINE_CAP_HOURS, GameState.get_time_scale())
