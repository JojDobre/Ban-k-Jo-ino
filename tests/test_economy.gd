extends "res://tests/test_suite.gd"

var economy: Node
var game_state: Node


func before_each() -> void:
	game_state = tree.root.get_node("GameState")
	economy = tree.root.get_node("EconomyManager")
	game_state.set_progress(PlayerProgress.new())


func test_grant_reward() -> void:
	check(economy.grant_reward("test", 10, 2), "odmena prijatá")
	check_eq(game_state.progress.coins, 10, "mince")
	check_eq(game_state.progress.gold, 2, "zlato")


func test_negative_reward_rejected() -> void:
	check(not economy.grant_reward("test", -5, 0), "záporná odmena odmietnutá")
	check_eq(game_state.progress.coins, 0, "mince sa nezmenili")


func test_spend_is_atomic() -> void:
	economy.grant_reward("test", 100, 0)
	check(not economy.spend(50, 1), "nedostatok zlata")
	check_eq(game_state.progress.coins, 100, "mince sa neodpočítali")
	economy.grant_reward("test", 0, 1)
	check(economy.spend(50, 1), "nákup prebehol")
	check_eq(game_state.progress.coins, 50, "mince po nákupe")
	check_eq(game_state.progress.gold, 0, "zlato po nákupe")


func test_spend_rejects_negative_cost() -> void:
	check(not economy.spend(-10, 0), "záporná cena")
	check_eq(game_state.progress.coins, 0, "mince sa nezmenili")


func test_one_time_reward_only_once() -> void:
	check(economy.claim_one_time("level_01:first_clear", 0, 1), "prvé vyzdvihnutie")
	check(not economy.claim_one_time("level_01:first_clear", 0, 1), "druhé vyzdvihnutie odmietnuté")
	check_eq(game_state.progress.gold, 1, "zlato pripísané iba raz")


func test_currency_changed_signal() -> void:
	var received: Array = []
	var callback := func(c: int, g: int) -> void: received.append([c, g])
	economy.currency_changed.connect(callback)
	economy.grant_reward("test", 5, 1)
	economy.currency_changed.disconnect(callback)
	check_eq(received, [[5, 1]], "signál so stavom meny")
