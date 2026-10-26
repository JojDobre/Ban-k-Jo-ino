class_name PlayerProgress
extends RefCounted
## Trvalý stav hráča (GDD kap. 7.1). Jedinú inštanciu vlastní GameState.

const SAVE_VERSION := 2
const DEFAULT_OUTFIT := "green"

var coins: int = 0
var gold: int = 0
var unlocked_levels: Array[String] = ["level_01"]
var completed_levels: Array[String] = []
## level_id -> Array[String] nájdených hviezd
var stars: Dictionary = {}
var claimed_rewards: Array[String] = []
## building_id -> int
var building_levels: Dictionary = {}
var last_mine_claim: int = 0
var settings: Dictionary = {"music_volume": 0.8, "sfx_volume": 1.0, "vibration": true}
## Verzia 2: obleky z obchodu, spotrebné predmety a posledný hraný level.
var owned_outfits: Array[String] = [DEFAULT_OUTFIT]
var outfit: String = DEFAULT_OUTFIT
## item_id -> počet kusov (napr. "start_shield")
var items: Dictionary = {}
var last_level: String = ""


func to_dict() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"coins": coins,
		"gold": gold,
		"unlocked_levels": unlocked_levels.duplicate(),
		"completed_levels": completed_levels.duplicate(),
		"stars": stars.duplicate(true),
		"claimed_rewards": claimed_rewards.duplicate(),
		"building_levels": building_levels.duplicate(),
		"last_mine_claim": last_mine_claim,
		"settings": settings.duplicate(),
		"owned_outfits": owned_outfits.duplicate(),
		"outfit": outfit,
		"items": items.duplicate(),
		"last_level": last_level,
	}


## Vytvorí progres z načítaných dát. Každé pole sa validuje, chybné hodnoty
## sa nahradia predvolenými – poškodené uloženie nesmie zhodiť hru.
static func from_dict(data: Dictionary) -> PlayerProgress:
	var p := PlayerProgress.new()
	p.coins = maxi(_int(data.get("coins"), 0), 0)
	p.gold = maxi(_int(data.get("gold"), 0), 0)
	var unlocked := _string_array(data.get("unlocked_levels"))
	if not unlocked.is_empty():
		p.unlocked_levels = unlocked
	p.completed_levels = _string_array(data.get("completed_levels"))
	p.claimed_rewards = _string_array(data.get("claimed_rewards"))
	p.last_mine_claim = maxi(_int(data.get("last_mine_claim"), 0), 0)

	var raw_stars: Variant = data.get("stars")
	if raw_stars is Dictionary:
		for level_id: Variant in raw_stars:
			p.stars[str(level_id)] = _string_array(raw_stars[level_id])

	var raw_buildings: Variant = data.get("building_levels")
	if raw_buildings is Dictionary:
		for building_id: Variant in raw_buildings:
			p.building_levels[str(building_id)] = maxi(_int(raw_buildings[building_id], 0), 0)

	var raw_settings: Variant = data.get("settings")
	if raw_settings is Dictionary:
		for key: Variant in raw_settings:
			if p.settings.has(key) and typeof(raw_settings[key]) == typeof(p.settings[key]):
				p.settings[key] = raw_settings[key]

	var outfits := _string_array(data.get("owned_outfits"))
	if not outfits.has(DEFAULT_OUTFIT):
		outfits.push_front(DEFAULT_OUTFIT)
	p.owned_outfits = outfits
	var chosen: Variant = data.get("outfit")
	p.outfit = chosen if chosen is String and outfits.has(chosen) else DEFAULT_OUTFIT
	var raw_items: Variant = data.get("items")
	if raw_items is Dictionary:
		for item_id: Variant in raw_items:
			var count := maxi(_int(raw_items[item_id], 0), 0)
			if count > 0:
				p.items[str(item_id)] = count
	var last: Variant = data.get("last_level")
	p.last_level = last if last is String else ""
	return p


func get_building_level(building_id: String) -> int:
	return building_levels.get(building_id, 0)


func get_item_count(item_id: String) -> int:
	return items.get(item_id, 0)


func get_stars(level_id: String) -> Array[String]:
	var result: Array[String] = []
	result.assign(stars.get(level_id, []))
	return result


static func _int(value: Variant, fallback: int) -> int:
	# JSON vracia všetky čísla ako float.
	if value is int or value is float:
		return int(value)
	return fallback


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value:
			if item is String and not result.has(item):
				result.append(item)
	return result
