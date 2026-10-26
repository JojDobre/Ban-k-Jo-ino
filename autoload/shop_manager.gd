extends Node
## Obchod v dedine: obleky pre Jožina a predmety na začiatok levelu.
## Nakupuje sa iba za herné mince a zlato (žiadne skutočné peniaze, GDD kap. 2.5).

signal purchased(item_id: String)
signal outfit_changed(outfit_id: String)

## Obleky – id zodpovedajú priečinkom v assets/player/.
const OUTFITS := [
	{"id": "green", "name": "Zelený baník", "coins": 0, "gold": 0},
	{"id": "yellow", "name": "Žltá prilba", "coins": 150, "gold": 0},
	{"id": "blue", "name": "Modré nohavice", "coins": 200, "gold": 1},
	{"id": "red_shirt", "name": "Červená košeľa", "coins": 250, "gold": 1},
	{"id": "old", "name": "Starý majster", "coins": 400, "gold": 3},
]
## Predmety sa automaticky použijú na začiatku ďalšieho levelu (jeden kus z každého).
const ITEMS := [
	{"id": "start_shield", "name": "Štít na štart", "description": "Level začneš so štítom.", "coins": 40, "gold": 0, "max": 3},
	{"id": "start_magnet", "name": "Magnet na štart", "description": "Prvých 20 s priťahuješ mince.", "coins": 30, "gold": 0, "max": 3},
]


func get_outfit(outfit_id: String) -> Dictionary:
	for outfit: Dictionary in OUTFITS:
		if outfit.id == outfit_id:
			return outfit
	return {}


func get_item(item_id: String) -> Dictionary:
	for item: Dictionary in ITEMS:
		if item.id == item_id:
			return item
	return {}


func owns_outfit(outfit_id: String) -> bool:
	return GameState.progress.owned_outfits.has(outfit_id)


func buy_outfit(outfit_id: String) -> bool:
	var outfit := get_outfit(outfit_id)
	if outfit.is_empty() or owns_outfit(outfit_id):
		return false
	if not EconomyManager.spend(outfit.coins, outfit.gold):
		return false
	GameState.progress.owned_outfits.append(outfit_id)
	purchased.emit(outfit_id)
	equip_outfit(outfit_id)
	return true


func equip_outfit(outfit_id: String) -> bool:
	if not owns_outfit(outfit_id):
		return false
	GameState.progress.outfit = outfit_id
	SaveManager.request_save()
	outfit_changed.emit(outfit_id)
	return true


func can_buy_item(item_id: String) -> bool:
	var item := get_item(item_id)
	return not item.is_empty() and GameState.progress.get_item_count(item_id) < item.max \
		and EconomyManager.can_afford(item.coins, item.gold)


func buy_item(item_id: String) -> bool:
	if not can_buy_item(item_id):
		return false
	var item := get_item(item_id)
	if not EconomyManager.spend(item.coins, item.gold):
		return false
	var progress := GameState.progress
	progress.items[item_id] = progress.get_item_count(item_id) + 1
	SaveManager.request_save()
	purchased.emit(item_id)
	return true


## Spotrebuje jeden kus predmetu. Vráti false, ak žiadny nie je.
func use_item(item_id: String) -> bool:
	var progress := GameState.progress
	var count := progress.get_item_count(item_id)
	if count <= 0:
		return false
	if count == 1:
		progress.items.erase(item_id)
	else:
		progress.items[item_id] = count - 1
	SaveManager.request_save()
	return true
