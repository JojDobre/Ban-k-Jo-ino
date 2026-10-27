extends Node3D

func _ready() -> void:
	_run.call_deferred()

func _step(name: String) -> void:
	print("KROK: ", name)
	for i in 3:
		await get_tree().physics_frame

func _run() -> void:
	SaveManager.autosave_enabled = false
	for id in ["house", "mine", "blacksmith", "shop"]:
		for level in 4:
			add_child(VillageModels.build(id, level))
			await _step("%s %d" % [id, level])
	var root := Node3D.new(); add_child(root)
	VillageDecor._rng.seed = 7
	VillageDecor._ground(root); await _step("ground")
	VillageDecor._paths(root); await _step("paths")
	VillageDecor._plaza(root); await _step("plaza")
	VillageDecor._field(root); await _step("field")
	VillageDecor._windmill(root); await _step("windmill")
	VillageDecor._pond(root); await _step("pond")
	VillageDecor._props(root); await _step("props")
	VillageDecor._forest(root, []); await _step("forest")
	VillageDecor._scatter(root, []); await _step("scatter")
	var cart := MineCart.new(); add_child(cart); await _step("cart")
	var v := Villager.new(); add_child(v); await _step("villager")
	var b := VillageBuilding.new(); b.building_id = "mine"; add_child(b); await _step("building")
	add_child(load("res://scenes/village/village.tscn").instantiate()); await _step("village")
	print("BISECT KONIEC")
	get_tree().quit()
