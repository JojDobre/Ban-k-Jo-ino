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
			await _step("%s %d" % [id, level])
			await _plane(root, "plane")
	print("BISECT KONIEC")
	get_tree().quit()
