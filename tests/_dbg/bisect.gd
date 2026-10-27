extends Node3D

func _ready() -> void:
	_run.call_deferred()

func _step(name: String) -> void:
	print("KROK: ", name)
	for i in 3:
		await get_tree().physics_frame

func _run() -> void:
	var root := Node3D.new(); add_child(root)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(110, 80)
	plane.material = VillageDecor._flat_material(Color.GREEN)
	ground.mesh = plane
	root.add_child(ground); await _step("plane")
	var patch := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 2.0
	disc.bottom_radius = 2.0
	disc.height = 0.01
	disc.radial_segments = 14
	patch.mesh = disc
	root.add_child(patch); await _step("patch")
	patch.scale = Vector3(1.5, 1, 1); await _step("patch scale")
	VillageDecor._rng.seed = 7
	VillageDecor._ground(root); await _step("ground")
	VillageDecor._paths(root); await _step("paths")
	print("BISECT KONIEC")
	get_tree().quit()
