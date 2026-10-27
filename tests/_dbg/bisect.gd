extends Node3D

func _ready() -> void:
	_run.call_deferred()

func _step(name: String) -> void:
	print("KROK: ", name)
	for i in 3:
		await get_tree().physics_frame

func _plane(root: Node3D, name: String) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(110, 80)
	ground.mesh = plane
	root.add_child(ground); await _step(name)
	ground.queue_free(); await _step(name + " pryc")

func _run() -> void:
	var root := Node3D.new(); add_child(root)
	for id in ["shop", "house", "mine", "blacksmith"]:
		for level in 4:
			add_child(VillageModels.build(id, level))
	await _step("modely")
	print("uzly ", Performance.get_monitor(Performance.OBJECT_NODE_COUNT), " objekty ", Performance.get_monitor(Performance.OBJECT_COUNT), " zdroje ", Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	VillageDecor._rng.seed = 7
	VillageDecor._ground(root); await _step("ground")
	var material := VillageDecor._flat_material(VillageDecor.PATH)
	for path in VillageDecor.PATHS:
		for i in path.size():
			var point := path[i]
			VillageDecor._disc(root, Vector3(point.x, 0.012, point.y), 0.8, material)
			await _step("disc %s" % point)
			if i == 0:
				continue
			var from := path[i - 1]
			var length := from.distance_to(point)
			var strip := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(1.6, 0.02, length)
			box.material = material
			strip.mesh = box
			strip.position = Vector3((from.x + point.x) * 0.5, 0.012, (from.y + point.y) * 0.5)
			strip.rotation.y = atan2(point.x - from.x, point.y - from.y)
			root.add_child(strip)
			await _step("strip %s" % point)
			for j in int(length / 1.6):
				VillageModels.add(root, "nature/rock_smallA", Vector3(j, 0, 0), 0.0, 1.0)
				await _step("rock %d" % j)
	print("BISECT KONIEC")
	get_tree().quit()
