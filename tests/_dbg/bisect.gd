extends Node3D

func _ready() -> void:
	_run.call_deferred()

func _step(name: String) -> void:
	print("KROK: ", name)
	for i in 3:
		await get_tree().physics_frame

func _run() -> void:
	var root := Node3D.new(); add_child(root)
	var mat := StandardMaterial3D.new()
	VillageDecor._disc(root, Vector3.ZERO, 0.8, mat); await _step("disc")
	var strip := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = Vector3(1.6, 0.02, 3.0); box.material = mat; strip.mesh = box; root.add_child(strip); await _step("box")
	for k in 5:
		VillageModels.add(root, "nature/rock_smallA", Vector3(k, 0, 0), 0.0, 1.0); await _step("rock %d" % k)
	var big := MeshInstance3D.new(); var b2 := BoxMesh.new(); b2.size = Vector3(1.6, 0.02, 9.2); strip.mesh = b2; root.add_child(big); await _step("box2")
	for path in VillageDecor.PATHS:
		print(path)
	print("BISECT KONIEC")
	get_tree().quit()
