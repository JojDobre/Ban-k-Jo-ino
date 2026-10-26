extends "res://tests/test_suite.gd"

var shop: Node
var game_state: Node
var economy: Node


func before_each() -> void:
	game_state = tree.root.get_node("GameState")
	shop = tree.root.get_node("ShopManager")
	economy = tree.root.get_node("EconomyManager")
	game_state.set_progress(PlayerProgress.new())


func test_default_outfit_owned() -> void:
	check(shop.owns_outfit("green"), "zelený oblek je od začiatku")
	check_eq(game_state.progress.outfit, "green", "zvolený oblek")


func test_buy_outfit() -> void:
	check(not shop.buy_outfit("yellow"), "bez mincí sa nekúpi")
	economy.grant_reward("test", 150, 0)
	check(shop.buy_outfit("yellow"), "kúpa")
	check_eq(game_state.progress.coins, 0, "mince odpočítané")
	check_eq(game_state.progress.outfit, "yellow", "kúpený oblek sa hneď oblečie")
	check(not shop.buy_outfit("yellow"), "druhýkrát sa nekúpi")
	check(shop.equip_outfit("green"), "prepnutie späť")


func test_cannot_equip_unowned() -> void:
	check(not shop.equip_outfit("old"), "nekúpený oblek")
	check_eq(game_state.progress.outfit, "green", "oblek sa nezmenil")


func test_items_limit_and_use() -> void:
	economy.grant_reward("test", 500, 0)
	for i in 3:
		check(shop.buy_item("start_shield"), "kúpa %d" % i)
	check(not shop.buy_item("start_shield"), "maximum 3 kusy")
	check_eq(game_state.progress.get_item_count("start_shield"), 3, "počet")
	check(shop.use_item("start_shield"), "použitie")
	check_eq(game_state.progress.get_item_count("start_shield"), 2, "po použití")
	check(not shop.use_item("start_magnet"), "nemá magnet")
