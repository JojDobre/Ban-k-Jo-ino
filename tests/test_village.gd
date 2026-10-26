extends "res://tests/test_suite.gd"

const HOUR := 3600

var village: Node
var game_state: Node
var economy: Node


func before_each() -> void:
	game_state = tree.root.get_node("GameState")
	village = tree.root.get_node("VillageManager")
	economy = tree.root.get_node("EconomyManager")
	game_state.set_progress(PlayerProgress.new())
	game_state.debug_time_scale = 1.0


func test_house_unlocks_other_buildings() -> void:
	check(not village.is_available("mine"), "baňa nie je dostupná pred opravou domu")
	check(village.upgrade("house"), "oprava domu je zadarmo")
	check(village.is_available("mine"), "po oprave domu je baňa dostupná")
	check(village.is_max_level("house"), "dom má jednu úroveň")


func test_upgrade_costs_and_missing() -> void:
	village.upgrade("house")
	economy.grant_reward("test", 30, 0)
	check(not village.can_upgrade("mine"), "na baňu chýbajú mince")
	check_eq(village.get_missing("mine"), {"coins": 20, "gold": 0}, "chýbajúca suma")
	economy.grant_reward("test", 20, 0)
	check(village.upgrade("mine"), "baňa postavená")
	check_eq(game_state.progress.coins, 0, "mince odpočítané")
	check_eq(village.get_level("mine"), 1, "úroveň bane")


func test_mine_production_and_claim() -> void:
	village.upgrade("house")
	economy.grant_reward("test", 50, 0)
	village.upgrade("mine")
	# Simulácia: baňa bola postavená pred dvoma hodinami.
	game_state.progress.last_mine_claim = game_state.now() - 2 * HOUR
	check_eq(village.get_pending_mine_coins(), 60, "2 h × 30/h")
	check_eq(village.claim_mine(), 60, "vyzdvihnuté")
	check_eq(game_state.progress.coins, 60, "mince pripísané")
	check_eq(village.claim_mine(), 0, "druhé vyzdvihnutie nič nedá")


func test_mine_upgrade_claims_old_rate_first() -> void:
	village.upgrade("house")
	economy.grant_reward("test", 50 + 120, 1)
	village.upgrade("mine")
	game_state.progress.last_mine_claim = game_state.now() - HOUR
	check(village.upgrade("mine"), "baňa úroveň 2")
	check_eq(game_state.progress.coins, 30, "pred vylepšením sa vyplatilo 30 mincí podľa starej úrovne")
	check_eq(village.get_mine_rate(), 60, "nová produkcia")


func test_blacksmith_adds_heart() -> void:
	village.upgrade("house")
	check_eq(game_state.get_max_hearts(), 3, "bez dielne 3 srdcia")
	economy.grant_reward("test", 100, 1)
	check(village.upgrade("blacksmith"), "dielňa postavená")
	check_eq(game_state.get_max_hearts(), 4, "s dielňou 4 srdcia")
