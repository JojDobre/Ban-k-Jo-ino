extends "res://tests/test_suite.gd"

const HOUR := 3600
const T0 := 1_700_000_000


func test_produces_by_rate() -> void:
	var r := MineProduction.calculate(T0, T0 + 2 * HOUR, 30, 8)
	check_eq(r.coins, 60, "2 hodiny × 30/h")
	check_eq(r.new_last_claim, T0 + 2 * HOUR, "čas sa posunie o vyplatený čas")


func test_respects_cap() -> void:
	var r := MineProduction.calculate(T0, T0 + 30 * HOUR, 30, 8)
	check_eq(r.coins, 240, "limit 8 hodín")
	check_eq(r.new_last_claim, T0 + 30 * HOUR, "po limite sa čas nastaví na teraz")


func test_negative_time_gives_nothing() -> void:
	var r := MineProduction.calculate(T0, T0 - 500, 30, 8)
	check_eq(r.coins, 0, "posun času dozadu")
	check_eq(r.new_last_claim, T0 - 500, "čas sa nastaví na teraz")


func test_partial_coin_is_kept() -> void:
	# 30/h = 1 minca za 120 s. Po 150 s: 1 minca, 30 s zostáva na ďalšiu.
	var r := MineProduction.calculate(T0, T0 + 150, 30, 8)
	check_eq(r.coins, 1, "jedna celá minca")
	check_eq(r.new_last_claim, T0 + 120, "zvyšok 30 s sa nestratí")
	var r2 := MineProduction.calculate(r.new_last_claim, T0 + 240, 30, 8)
	check_eq(r2.coins, 1, "druhá minca po ďalších 90 s")


func test_claim_twice_does_not_double() -> void:
	var r := MineProduction.calculate(T0, T0 + HOUR, 30, 8)
	var r2 := MineProduction.calculate(r.new_last_claim, T0 + HOUR, 30, 8)
	check_eq(r2.coins, 0, "druhé vyzdvihnutie v tom istom čase")


func test_debug_time_scale() -> void:
	# 60× zrýchlenie: 1 minúta = 1 herná hodina.
	var r := MineProduction.calculate(T0, T0 + 60, 30, 8, 60.0)
	check_eq(r.coins, 30, "1 minúta pri 60× = 1 hodina")
	var capped := MineProduction.calculate(T0, T0 + 3600, 30, 8, 60.0)
	check_eq(capped.coins, 240, "limit platí aj pri zrýchlení")


func test_no_production_without_mine() -> void:
	check_eq(MineProduction.calculate(T0, T0 + HOUR, 0, 8).coins, 0, "úroveň 0")
