class_name VillageDecor
extends RefCounted
## Okolie dediny: tráva, chodníky, námestie so studňou, pole s plodinami, veterný mlyn,
## jazierko a les dookola. Náhodné rozmiestnenie má pevné semienko – dedina vyzerá
## pri každom otvorení rovnako.

const GRASS := Color("86c95a")
const PATH := Color("dcb77c")
const WATER := Color("5ec4e8")

## Chodníky ako lomené čiary (x, z) – od námestia k budovám.
const PATH_POINTS := [
	[Vector2(0, 1.6), Vector2(0, 5.0)],
	[Vector2(0, 5.0), Vector2(-4.5, 3.0), Vector2(-7.5, 0.5)],
	[Vector2(0, 5.0), Vector2(4.5, 3.5), Vector2(8.0, 0.0)],
	[Vector2(4.5, 3.5), Vector2(6.8, 4.6)],
	[Vector2(-4.5, 3.0), Vector2(-5.2, 5.5)],
	[Vector2(0, 5.0), Vector2(0, 11.0)],
	[Vector2(2.0, 0.5), Vector2(3.2, -5.6)],
]
const FIELD_CENTER := Vector3(-9.0, 0, 6.0)
const WINDMILL_POS := Vector3(3.2, 0, -7.6)
const POND_POS := Vector3(12.5, 0, 5.0)
const PLAZA_POS := Vector3(0, 0, 5.0)

static var _rng := RandomNumberGenerator.new()
static var _paths_cache: Array[PackedVector2Array] = []


## occupied = obdĺžniky (x, z), kde stoja budovy – dekorácie sa im vyhnú.
static func build(root: Node3D, occupied: Array[Rect2]) -> void:
	_rng.seed = 7
	var blocked := occupied.duplicate()
	_ground(root)
	_paths(root)
	_plaza(root)
	blocked.append(Rect2(PLAZA_POS.x - 3, PLAZA_POS.z - 3, 6, 6))
	_field(root)
	blocked.append(Rect2(FIELD_CENTER.x - 3.6, FIELD_CENTER.z - 2.6, 7.2, 5.2))
	var blades := _windmill(root)
	blocked.append(Rect2(WINDMILL_POS.x - 2.5, WINDMILL_POS.z - 1.5, 5, 3.5))
	_pond(root)
	blocked.append(Rect2(POND_POS.x - 3.2, POND_POS.z - 3.2, 6.4, 6.4))
	_props(root)
	_forest(root, blocked)
	_scatter(root, blocked)
	# Mlyn sa točí stále dokola.
	var tween := blades.create_tween().set_loops()
	tween.tween_property(blades, "rotation:z", -TAU, 7.0).from(0.0)


## Chodníky ako PackedVector2Array. Skladajú sa až za behu – konštanta typu
## Array[PackedVector2Array] sa na niektorých strojoch načítala poškodená.
static func paths() -> Array[PackedVector2Array]:
	if _paths_cache.is_empty():
		for points: Array in PATH_POINTS:
			_paths_cache.append(PackedVector2Array(points))
	return _paths_cache


static func _flat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


static func _ground(root: Node3D) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(110, 80)
	plane.material = _flat_material(GRASS)
	ground.mesh = plane
	ground.position = Vector3(0, -0.01, -5)
	root.add_child(ground)
	# Tmavšie fľaky trávy, aby plocha nebola jednoliata.
	var patch_material := _flat_material(GRASS.darkened(0.08))
	for i in 26:
		var patch := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = _rng.randf_range(1.2, 3.2)
		disc.bottom_radius = disc.top_radius
		disc.height = 0.01
		disc.radial_segments = 14
		disc.material = patch_material
		patch.mesh = disc
		patch.scale = Vector3(_rng.randf_range(1.0, 1.8), 1, 1)
		patch.rotation.y = _rng.randf() * TAU
		patch.position = Vector3(_rng.randf_range(-24, 24), 0.0, _rng.randf_range(-16, 12))
		root.add_child(patch)


static func _paths(root: Node3D) -> void:
	var material := _flat_material(PATH)
	for path in paths():
		for i in path.size():
			var point := path[i]
			_disc(root, Vector3(point.x, 0.012, point.y), 0.8, material)
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
			# Kamienky pri okraji chodníka.
			var pebbles := clampi(int(length / 1.6), 0, 12)
			for j in pebbles:
				var t := (j + 0.5) / pebbles
				var side := 1.0 if j % 2 == 0 else -1.0
				var normal := Vector2(point.y - from.y, -(point.x - from.x)).normalized()
				var spot := from.lerp(point, t) + normal * side * 1.0
				_no_shadow(VillageModels.add(root, "nature/rock_smallA", Vector3(spot.x, 0, spot.y), _rng.randf() * 360.0, _rng.randf_range(0.8, 1.3)))


static func _disc(root: Node3D, pos: Vector3, radius: float, material: Material) -> void:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	mesh.radial_segments = 20
	mesh.material = material
	disc.mesh = mesh
	disc.position = pos
	root.add_child(disc)


static func _plaza(root: Node3D) -> void:
	_disc(root, PLAZA_POS + Vector3(0, 0.014, 0), 2.6, _flat_material(PATH.lightened(0.15)))
	VillageModels.add(root, "town/fountain-round-detail", PLAZA_POS + Vector3(0, 0.02, 0), 0.0, 1.5)
	var water := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.25
	mesh.bottom_radius = 1.25
	mesh.height = 0.05
	var material := _flat_material(WATER)
	material.roughness = 0.1
	material.metallic_specular = 0.8
	mesh.material = material
	water.mesh = mesh
	water.position = PLAZA_POS + Vector3(0, 0.3, 0)
	root.add_child(water)
	for corner: Vector3 in [Vector3(-2.2, 0, -1.6), Vector3(2.2, 0, -1.6), Vector3(-2.2, 0, 1.8), Vector3(2.2, 0, 1.8)]:
		VillageModels.add(root, "town/lantern", PLAZA_POS + corner, 0.0, 1.1)
	VillageModels.add(root, "town/stall-bench", PLAZA_POS + Vector3(-1.5, 0, 2.2), 90.0, 1.6)
	VillageModels.add(root, "town/stall-bench", PLAZA_POS + Vector3(1.5, 0, 2.2), 90.0, 1.6)


static func _field(root: Node3D) -> void:
	var crops := ["nature/crops_cornStageD", "nature/crops_wheatStageB", "nature/crop_pumpkin",
		"nature/crop_carrot", "nature/crop_melon", "nature/crops_leafsStageB"]
	for col in 3:
		for row in 2:
			var center := FIELD_CENTER + Vector3((col - 1) * 2.2, 0, (row - 0.5) * 2.1)
			VillageModels.add(root, "nature/crops_dirtDoubleRow", center + Vector3(0, 0.03, 0), 0.0, 2.1)
			var crop: String = crops[row * 3 + col]
			for i in 3:
				for line in [-0.45, 0.45]:
					var spot := center + Vector3(-0.7 + i * 0.7, 0.05, line)
					VillageModels.add(root, crop, spot, _rng.randf() * 360.0, _rng.randf_range(1.5, 1.9))
	# Plot okolo poľa, vpredu s bránkou.
	var half := Vector2(3.5, 2.5)
	for i in 7:
		var x := FIELD_CENTER.x - half.x + 0.5 + i
		VillageModels.add(root, "nature/fence_simple", Vector3(x, 0, FIELD_CENTER.z - half.y), 0.0, 1.0)
		var front := "nature/fence_gate" if i == 3 else "nature/fence_simple"
		VillageModels.add(root, front, Vector3(x, 0, FIELD_CENTER.z + half.y), 0.0, 1.0)
	for i in 5:
		var z := FIELD_CENTER.z - half.y + 0.5 + i
		VillageModels.add(root, "nature/fence_simple", Vector3(FIELD_CENTER.x - half.x, 0, z), 90.0, 1.0)
		VillageModels.add(root, "nature/fence_simple", Vector3(FIELD_CENTER.x + half.x, 0, z), 90.0, 1.0)
	VillageModels.add(root, "survival/bucket", FIELD_CENTER + Vector3(3.9, 0, 2.9), 0.0, 1.6)
	VillageModels.add(root, "survival/tool-shovel", FIELD_CENTER + Vector3(4.1, 0, 2.6), 20.0, 2.0)


## Vráti uzol lopatiek (otáča sa okolo osi z).
static func _windmill(root: Node3D) -> Node3D:
	var mill := Node3D.new()
	mill.position = WINDMILL_POS
	mill.scale = Vector3.ONE * VillageModels.BUILDING_SCALE
	root.add_child(mill)
	VillageModels._cell(mill, Vector3.ZERO, {
		VillageModels.SOUTH: "town/wall-door", VillageModels.EAST: "town/wall-window-small",
		VillageModels.WEST: "town/wall", VillageModels.NORTH: "town/wall",
	})
	VillageModels._cell(mill, Vector3(0, 1, 0), {
		VillageModels.SOUTH: "town/wall-wood-window-small", VillageModels.EAST: "town/wall-wood",
		VillageModels.WEST: "town/wall-wood", VillageModels.NORTH: "town/wall-wood",
	})
	VillageModels.add(mill, "town/roof-high-point", Vector3(0, 2, 0))
	var hub := Node3D.new()
	hub.position = Vector3(0, 2.3, 0.62)
	mill.add_child(hub)
	var spinner := Node3D.new()
	hub.add_child(spinner)
	# Model má os otáčania v smere x; po otočení o 90° je to os z.
	VillageModels.add(spinner, "town/windmill", Vector3.ZERO, 90.0, 0.5)
	VillageModels.add(mill, "survival/box-large", Vector3(0.75, 0, 0.5), 30.0, 1.2)
	VillageModels.add(mill, "survival/box", Vector3(0.7, 0.25, 0.45), 10.0, 1.2)
	return spinner


static func _pond(root: Node3D) -> void:
	var water := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.6
	mesh.bottom_radius = 2.6
	mesh.height = 0.04
	mesh.radial_segments = 24
	var material := _flat_material(WATER)
	material.roughness = 0.1
	material.metallic_specular = 0.8
	mesh.material = material
	water.mesh = mesh
	water.scale = Vector3(1.25, 1, 0.9)
	water.position = POND_POS + Vector3(0, 0.02, 0)
	root.add_child(water)
	for i in 14:
		var angle := i * TAU / 14.0
		var spot := POND_POS + Vector3(cos(angle) * 3.3, 0, sin(angle) * 2.4)
		var stone := "nature/rock_largeA" if i % 3 == 0 else "nature/stone_smallA"
		VillageModels.add(root, stone, spot, _rng.randf() * 360.0, _rng.randf_range(1.0, 1.6))
	for spot: Vector3 in [Vector3(-1.0, 0.04, 0.4), Vector3(0.8, 0.04, -0.6), Vector3(1.6, 0.04, 0.8), Vector3(-0.2, 0.04, -1.2)]:
		VillageModels.add(root, "nature/lily_large", POND_POS + spot, _rng.randf() * 360.0, 2.2)
	VillageModels.add(root, "nature/plant_bushLarge", POND_POS + Vector3(-3.4, 0, -1.6), 0.0, 2.2)


## Menšie predmety pri chodníkoch, ktoré dedinu oživia.
static func _props(root: Node3D) -> void:
	VillageModels.add(root, "nature/log_stackLarge", Vector3(-3.6, 0, -2.6), 20.0, 2.2)
	VillageModels.add(root, "nature/sign", Vector3(-1.4, 0, 9.8), 10.0, 2.4)
	VillageModels.add(root, "survival/campfire-pit", Vector3(-3.0, 0, 7.4), 0.0, 2.4)
	VillageModels.add(root, "nature/stump_old", Vector3(-2.2, 0, 8.1), 0.0, 2.2)
	VillageModels.add(root, "nature/stump_round", Vector3(-3.9, 0, 8.2), 0.0, 2.2)
	VillageModels.add(root, "nature/plant_bushLarge", Vector3(-2.6, 0, -0.2), 0.0, 2.4)
	VillageModels.add(root, "survival/barrel", Vector3(5.4, 0, -1.0), 0.0, 1.6)


static func _forest(root: Node3D, blocked: Array) -> void:
	var trees := ["nature/tree_oak", "nature/tree_default", "nature/tree_pineRoundA", "nature/tree_fat",
		"nature/tree_detailed", "nature/tree_pineTallA", "nature/tree_simple", "nature/tree_pineDefaultA"]
	var placed := 0
	var attempts := 0
	while placed < 170 and attempts < 4000:
		attempts += 1
		var spot := Vector3(_rng.randf_range(-34, 34), 0, _rng.randf_range(-30, 18))
		# Les je hustý mimo dediny, vnútri iba pár stromov.
		var inside := absf(spot.x) < 16.5 and spot.z > -11.5 and spot.z < 11.0
		if inside and _rng.randf() > 0.06:
			continue
		if _is_blocked(spot, blocked, 1.6):
			continue
		VillageModels.add(root, trees[_rng.randi() % trees.size()], spot, _rng.randf() * 360.0, _rng.randf_range(2.3, 3.4))
		placed += 1


static func _scatter(root: Node3D, blocked: Array) -> void:
	var small := ["nature/flower_redA", "nature/flower_yellowA", "nature/flower_purpleA", "nature/flower_redB",
		"nature/flower_yellowB", "nature/grass", "nature/grass_large", "nature/grass_leafs", "nature/plant_bush",
		"nature/plant_bushSmall", "nature/mushroom_red", "nature/flower_redA", "nature/flower_yellowA"]
	var placed := 0
	var attempts := 0
	while placed < 110 and attempts < 3000:
		attempts += 1
		var spot := Vector3(_rng.randf_range(-17, 17), 0, _rng.randf_range(-11, 11))
		if _is_blocked(spot, blocked, 0.5) or _near_path(spot, 1.2):
			continue
		_no_shadow(VillageModels.add(root, small[_rng.randi() % small.size()], spot, _rng.randf() * 360.0, _rng.randf_range(1.8, 2.6)))
		placed += 1


## Drobnosti bez tieňa – menej práce pre grafiku telefónu.
static func _no_shadow(node: Node3D) -> void:
	for mesh: GeometryInstance3D in node.find_children("*", "GeometryInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _is_blocked(spot: Vector3, blocked: Array, margin: float) -> bool:
	for rect: Rect2 in blocked:
		if rect.grow(margin).has_point(Vector2(spot.x, spot.z)):
			return true
	return _near_path(spot, margin + 0.8)


static func _near_path(spot: Vector3, distance: float) -> bool:
	var point := Vector2(spot.x, spot.z)
	for path in paths():
		for i in range(1, path.size()):
			var closest := Geometry2D.get_closest_point_to_segment(point, path[i - 1], path[i])
			if closest.distance_to(point) < distance:
				return true
	return false
