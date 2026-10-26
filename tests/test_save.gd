extends "res://tests/test_suite.gd"

var save_manager: Node


func before_each() -> void:
	save_manager = tree.root.get_node("SaveManager")
	save_manager.delete_save()


func test_roundtrip() -> void:
	var p := PlayerProgress.new()
	p.coins = 123
	p.gold = 4
	p.completed_levels.append("level_01")
	p.stars["level_01"] = ["a", "c"]
	p.claimed_rewards.append("level_01:first_clear")
	p.building_levels["mine"] = 2
	p.last_mine_claim = 1_700_000_000
	check(save_manager.save_progress(p), "uloženie prebehlo")
	var loaded: PlayerProgress = save_manager.load_progress()
	check_eq(loaded.to_dict(), p.to_dict(), "načítané dáta sa zhodujú")


func test_missing_file_gives_new_game() -> void:
	var loaded: PlayerProgress = save_manager.load_progress()
	check_eq(loaded.coins, 0, "nová hra")
	check_eq(loaded.unlocked_levels, ["level_01"] as Array[String], "prvý level odomknutý")
	check(loaded.last_mine_claim > 0, "čas bane nastavený")


func test_corrupted_file_falls_back_to_backup() -> void:
	var p := PlayerProgress.new()
	p.coins = 50
	save_manager.save_progress(p)
	p.coins = 80
	save_manager.save_progress(p)  # predchádzajúce uloženie (50) je teraz záloha
	var file := FileAccess.open(save_manager.save_path, FileAccess.WRITE)
	file.store_string("{ poškodené")
	file.close()
	check_eq(save_manager.load_progress().coins, 50, "použila sa záloha")


func test_invalid_values_are_sanitized() -> void:
	var loaded := PlayerProgress.from_dict({
		"coins": -40,
		"gold": "veľa",
		"unlocked_levels": "level_01",
		"stars": {"level_01": ["a", 5, "a"]},
		"building_levels": {"mine": -3},
	})
	check_eq(loaded.coins, 0, "záporné mince orezané")
	check_eq(loaded.gold, 0, "neplatné zlato")
	check_eq(loaded.unlocked_levels, ["level_01"] as Array[String], "predvolené odomknuté levely")
	check_eq(loaded.get_stars("level_01"), ["a"] as Array[String], "hviezdy bez duplicít a neplatných hodnôt")
	check_eq(loaded.get_building_level("mine"), 0, "záporná úroveň budovy")


func test_save_contains_version() -> void:
	save_manager.save_progress(PlayerProgress.new())
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_manager.save_path))
	check_eq(int(data.save_version), PlayerProgress.SAVE_VERSION, "verzia dát")


func test_migration_from_version_1() -> void:
	var file := FileAccess.open(save_manager.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 1, "coins": 42, "completed_levels": ["level_01"]}))
	file.close()
	var loaded: PlayerProgress = save_manager.load_progress()
	check_eq(loaded.coins, 42, "mince zo starej verzie")
	check_eq(loaded.owned_outfits, ["green"] as Array[String], "predvolený oblek")
	check_eq(loaded.outfit, "green", "zvolený oblek")
	check(loaded.items.is_empty(), "žiadne predmety")


func test_invalid_outfit_falls_back() -> void:
	var loaded := PlayerProgress.from_dict({"owned_outfits": ["yellow"], "outfit": "old", "items": {"start_shield": -2}})
	check(loaded.owned_outfits.has("green"), "zelený oblek vždy vlastnený")
	check_eq(loaded.outfit, "green", "nevlastnený oblek sa nepoužije")
	check(loaded.items.is_empty(), "záporné predmety sa zahodia")
