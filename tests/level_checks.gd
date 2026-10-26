extends Node
## Overí kľúčové miesta level_01 reálnou fyzikou hráča (dosiahnuteľnosť, bloky, kľúč, vypínač…):
## godot --headless --path . --fixed-fps 60 res://tests/level_checks.tscn
## Výstup „VÝSLEDOK: OK“ alebo zoznam chýb; návratový kód 0/1.
## Súradnice zodpovedajú mape v tools/build_level_01.gd – pri zmene mapy ich uprav.

const TILE := 64.0
const GROUND_SURFACE := 9 * TILE

var _level: LevelController
var _failures: Array[String] = []


func _ready() -> void:
	SaveManager.autosave_enabled = false
	GameState.set_progress(PlayerProgress.new())
	_level = load("res://scenes/levels/level_01.tscn").instantiate()
	add_child(_level)
	_run.call_deferred()


func _run() -> void:
	var p := _level.player
	await _frames(5)

	# 1. Skrytý blok (stĺpec 22, riadok 5) sa objaví po údere zospodu a dá mincu.
	var hidden := _node_at("Blocks", 22, 5) as BumpBlock
	var coins_before := _level.run.coins
	await _place(_cell_center(22, 8))
	await _jump_and_wait(40)
	_check(hidden != null and hidden.get_node("Sprite").visible, "skrytý blok sa neobjavil")
	_check(_level.run.coins > coins_before, "skrytý blok nedal mincu")

	# 2. Tehla (stĺpec 11) sa úderom rozbije.
	var brick := _node_at("Blocks", 11, 5)
	await _place(_cell_center(11, 8))
	await _jump_and_wait(40)
	_check(not is_instance_valid(brick), "tehla sa nerozbila")

	# 3. Podzemná tajná miestnosť: Jožino sa prepadne a pružina ho vystrelí späť nad zem.
	await _place(Vector2(66.5 * TILE, GROUND_SURFACE - 40))
	var fell_in := false
	var escaped := false
	for i in 240:
		await get_tree().physics_frame
		if p.global_position.y > 10 * TILE:
			fell_in = true
		if fell_in and p.get_feet_y() < GROUND_SURFACE - 40:
			escaped = true
			break
	_check(fell_in, "podzemná miestnosť: Jožino sa neprepadol")
	_check(escaped, "podzemná miestnosť: pružina ho nevystrelila von")
	_check(_level.run.secrets_found >= 1, "podzemná miestnosť sa nezapočítala ako tajné miesto")

	# 4. Pružina pri trezore vynesie Jožina na oblak s kľúčom (povrch riadku 2).
	await _place(Vector2(80.5 * TILE, 6 * TILE))
	var top := await _track_min_feet(90)
	_check(top < 2 * TILE, "pružina ku kľúču: najvyšší bod chodidiel %.0f, treba nad %.0f" % [top, 2 * TILE])

	# 5. Kľúč otvorí zámky trezoru.
	await _place(_cell_center(82, 1) + Vector2(0, -4))
	await _frames(60)
	_check(get_tree().get_nodes_in_group(&"lock_block").is_empty(), "kľúč neotvoril zámky")

	# 6. Vypínač prepne modré bloky: stena zmizne, schodík k hviezde B sa objaví.
	var wall := _node_at("Blocks", 111, 7)
	var step := _node_at("Blocks", 114, 7)
	await _place(Vector2(107.5 * TILE, GROUND_SURFACE - 80))
	await _frames(30)
	_check(wall != null and wall.get_node("CollisionShape2D").disabled, "vypínač nevypol modrú stenu")
	_check(step != null and not step.get_node("CollisionShape2D").disabled, "vypínač nezapol schodík")

	# 7. Pohyblivá plošina nad lávou odvezie Jožina doprava.
	var platform: MovingPlatform
	for node in _level.get_node("Platforms").get_children():
		if node is MovingPlatform and (node as MovingPlatform).travel.y == 0.0:
			platform = node
	await _place(platform.global_position + Vector2(0, -40), 2)
	var start_x := p.global_position.x
	await _frames(170)
	# Plošina môže byť práve v ktorejkoľvek fáze cesty – stačí, že sa s ňou Jožino viezol a nespadol.
	_check(absf(p.global_position.x - start_x) > 100.0 and p.get_feet_y() < 9 * TILE, "pohyblivá plošina Jožina neodviezla (posun %.0f)" % (p.global_position.x - start_x))

	# 8. Hviezda C (riadok 3) – bežným skokom nie (skúša sa mimo dosahu včely), odrazom od včely áno.
	var star_bottom := 3 * TILE + 32 + 24
	await _place(_cell_center(210, 8))
	_hold(&"jump", true)
	var plain := await _track_min_y(60)
	_hold(&"jump", false)
	_check(plain - 36 > star_bottom, "hviezda C je dosiahnuteľná aj bez včely (vrch hlavy %.0f)" % (plain - 36))
	var bee := _nearest_enemy(Vector2(205.5 * TILE, 6.5 * TILE))
	# Myš z predchádzajúceho úseku sa môže rozbehnúť až sem – pre tento test ju odstránime.
	for node in _level.get_node("Enemies").get_children():
		if node != bee and (node as Node2D).global_position.x > 180 * TILE:
			node.queue_free()
	# Test overuje výšku odrazu, nie mierenie: Jožino počas pádu kopíruje polohu včely
	# a skok drží až počas pádu (inak by ešte platil coyote time a skočil by vo vzduchu).
	await _place(bee.global_position + Vector2(0, -150), 1)
	for i in 60:
		await get_tree().physics_frame
		if not is_instance_valid(bee) or bee.is_dead():
			break
		p.global_position.x = bee.global_position.x
		if p.velocity.y > 0.0:
			_hold(&"jump", true)
	var bounced := await _track_min_y(50)
	_hold(&"jump", false)
	# Porazená včela sa po chvíli zruší – zrušený objekt znamená, že bola porazená.
	_check(not is_instance_valid(bee) or bee.is_dead(), "hviezda C: včelu sa nepodarilo poraziť skokom zhora")
	_check(bounced - 36 < star_bottom, "hviezda C: odraz od včely nestačí (vrch hlavy %.0f)" % (bounced - 36))

	print("VÝSLEDOK: OK" if _failures.is_empty() else "VÝSLEDOK: CHYBY\n  " + "\n  ".join(_failures))
	_level.queue_free()
	await _frames(2)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _cell_center(col: int, row: int) -> Vector2:
	return Vector2((col + 0.5) * TILE, (row + 0.5) * TILE)


## Objekt v skupine levelu, ktorého pôvod leží v danej bunke mapy.
func _node_at(group: String, col: int, row: int) -> Node:
	for node in _level.get_node(group).get_children():
		var pos := (node as Node2D).position
		if int(pos.x / TILE) == col and int((pos.y - 0.01) / TILE) in [row, row - 1, row + 1] and absf(pos.y - (row + 0.5) * TILE) <= TILE:
			return node
	return null


func _nearest_enemy(at: Vector2) -> Enemy:
	var best: Enemy
	for node in _level.get_node("Enemies").get_children():
		var enemy := node as Enemy
		if enemy != null and (best == null or enemy.global_position.distance_to(at) < best.global_position.distance_to(at)):
			best = enemy
	return best


func _place(at: Vector2, settle_frames: int = 20) -> void:
	_level.run.hearts = _level.run.max_hearts
	_level.player.respawn(at)
	_level.player.input_enabled = true
	await _frames(settle_frames)


func _jump_and_wait(frames: int) -> void:
	_hold(&"jump", true)
	await _frames(frames)
	_hold(&"jump", false)
	await _frames(10)


func _track_min_y(frames: int) -> float:
	var min_y := _level.player.global_position.y
	for i in frames:
		await get_tree().physics_frame
		min_y = minf(min_y, _level.player.global_position.y)
	return min_y


func _track_min_feet(frames: int) -> float:
	return await _track_min_y(frames) + Player.BODY_SIZE.y * 0.5


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _hold(action: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
