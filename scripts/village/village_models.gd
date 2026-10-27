class_name VillageModels
extends RefCounted
## Skladanie 3D modelov dediny z dielov Kenney (Fantasy Town, Survival, Nature Kit).
## Budovy sa skladajú v bunkách 1×1 (stena = okraj bunky) a celý model sa zväčší
## cez BUILDING_SCALE. Každá úroveň budovy má vlastný vzhľad.

const BASE := "res://assets/village3d/"
const BUILDING_SCALE := 2.0
const GOLD := Color("ffcc33")

## Strany bunky -> otočenie dielu steny (diel leží na okraji +X).
const EAST := 0.0
const NORTH := 90.0
const WEST := 180.0
const SOUTH := -90.0

## Nature Kit má pastelové farby – v dedine ich nahradíme sýtejšími (podľa názvu materiálu).
const NATURE_COLORS := {
	"grass": Color("6cc04a"), "leafsGreen": Color("5cb848"), "leafsDark": Color("3e9a45"),
	"woodBark": Color("a46d48"), "woodBarkDark": Color("6b4430"), "wood": Color("c98d55"),
	"woodDark": Color("9a6438"), "woodInner": Color("e8c890"), "woodBirch": Color("f0e8dc"),
	"stone": Color("b9b6ad"), "dirt": Color("8d7765"), "dirtDark": Color("7a4f30"),
	"corn": Color("f2c94c"), "leafsFall": Color("ee8f32"), "colorRed": Color("e84c4c"),
	"colorYellow": Color("ffd23f"), "colorPurple": Color("a070e0"), "colorTan": Color("e0b080"),
	"water": Color("5ec4e8"),
}

static var _cache: Dictionary = {}
static var _nature_materials: Dictionary = {}
static var _gold_material: StandardMaterial3D


## Vloží diel „kit/názov“ (napr. „town/wall-door“) do rodiča.
static func add(parent: Node3D, piece: String, pos: Vector3 = Vector3.ZERO, rot_y: float = 0.0, scale: float = 1.0) -> Node3D:
	var scene: PackedScene = _cache.get(piece)
	if scene == null:
		scene = load(BASE + piece + ".glb")
		_cache[piece] = scene
	var node := scene.instantiate() as Node3D
	if piece.begins_with("nature/"):
		_recolor(node)
	node.position = pos
	node.rotation_degrees.y = rot_y
	node.scale = Vector3.ONE * scale
	parent.add_child(node)
	return node


static func _recolor(node: Node3D) -> void:
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for i in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(i) as StandardMaterial3D
			if original == null or not NATURE_COLORS.has(original.resource_name):
				continue
			var replaced: StandardMaterial3D = _nature_materials.get(original.resource_name)
			if replaced == null:
				replaced = original.duplicate() as StandardMaterial3D
				replaced.albedo_color = NATURE_COLORS[original.resource_name]
				_nature_materials[original.resource_name] = replaced
			mesh.set_surface_override_material(i, replaced)


## Model budovy podľa id a úrovne. Pôvod je v strede pôdorysu na zemi.
static func build(building_id: String, level: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	var body := Node3D.new()
	body.scale = Vector3.ONE * BUILDING_SCALE
	root.add_child(body)
	match building_id:
		"house":
			_house(body, level)
		"mine":
			_mine(body, level)
		"blacksmith":
			_blacksmith(body, level)
		"shop":
			_shop(body)
	return root


## Štyri steny bunky; walls = {strana: diel}.
static func _cell(parent: Node3D, center: Vector3, walls: Dictionary) -> void:
	for side: float in walls:
		add(parent, walls[side], center, side)


# --- Jožinov dom ---------------------------------------------------------------

static func _house(p: Node3D, level: int) -> void:
	if level == 0:
		# Ruina: kamenné zvyšky múrov, porozhadzované dosky, žiadna strecha.
		_cell(p, Vector3.ZERO, {
			SOUTH: "town/wall-broken", WEST: "town/wall-broken", NORTH: "town/wall", EAST: "town/wall-broken",
		})
		add(p, "town/wall-wood-broken", Vector3(0, 1, 0), NORTH)
		add(p, "town/planks", Vector3(0.9, 0.02, 0.3), 25.0, 0.6)
		add(p, "survival/resource-planks", Vector3(1.0, 0, -0.3), 40.0, 1.0)
		add(p, "survival/resource-planks", Vector3(-0.9, 0, 0.5), -20.0, 0.9)
		add(p, "town/rock-small", Vector3(-0.85, 0, -0.45), 0.0, 0.3)
		add(p, "survival/signpost-single", Vector3(0.5, 0, 0.8), -15.0, 1.2)
		add(p, "nature/grass_large", Vector3(-0.3, 0, 0.75), 0.0, 1.0)
		add(p, "nature/grass", Vector3(0.75, 0, -0.75), 0.0, 1.0)
		return
	# Opravený dom: kamenné prízemie, drevené poschodie, vysoká strecha a prístavok.
	_cell(p, Vector3.ZERO, {
		SOUTH: "town/wall-door", WEST: "town/wall-window-shutters", NORTH: "town/wall", EAST: "town/wall",
	})
	_cell(p, Vector3(0, 1, 0), {
		SOUTH: "town/wall-wood-window-shutters", WEST: "town/wall-wood-window-small",
		NORTH: "town/wall-wood", EAST: "town/wall-wood-window-small",
	})
	add(p, "town/roof-high-point", Vector3(0, 2, 0))
	add(p, "town/chimney", Vector3(-0.15, 2.0, -0.2))
	smoke(p, Vector3(0.05, 3.05, -0.03))
	# Prístavok vpravo.
	_cell(p, Vector3(1, 0, 0), {
		SOUTH: "town/wall-wood-window-shutters", EAST: "town/wall-wood-window-small", NORTH: "town/wall-wood",
	})
	add(p, "town/roof-point", Vector3(1, 1, 0))
	add(p, "town/lantern", Vector3(-0.35, 0, 0.65), 0.0, 0.6)
	add(p, "town/banner-green", Vector3(0, 1.0, 0), SOUTH, 1.0)
	add(p, "survival/barrel", Vector3(1.4, 0, 0.75), 0.0, 1.4)
	add(p, "survival/box", Vector3(1.05, 0, 0.8), 20.0, 1.3)
	# Predzáhradka s plotom a kvetmi.
	for i in 3:
		add(p, "nature/fence_simple", Vector3(-1.0, 0, -0.5 + i * 0.5), 90.0, 0.5)
	for flower: Array in [
		["nature/flower_redA", Vector3(-0.75, 0, 0.7)], ["nature/flower_yellowA", Vector3(-0.85, 0, 0.35)],
		["nature/flower_purpleA", Vector3(-0.7, 0, 0.0)], ["nature/flower_redB", Vector3(0.45, 0, 0.75)],
		["nature/plant_bush", Vector3(1.75, 0, -0.3)],
	]:
		add(p, flower[0], flower[1], flower[1].x * 97.0, 1.2)


# --- Baňa ------------------------------------------------------------------------

static func _mine(p: Node3D, level: int) -> void:
	# Skalný kopec z balvanov, navrchu stromy, vpredu tmavý vchod do štôlne.
	add(p, "survival/rock-b", Vector3(0, 0, -0.9), 0.0, 3.6)
	add(p, "survival/rock-c", Vector3(-1.05, 0, -0.55), 40.0, 2.8)
	add(p, "survival/rock-a", Vector3(1.1, 0, -0.45), -30.0, 2.6)
	add(p, "town/rock-large", Vector3(0.35, 0, -1.5), 20.0, 1.4)
	add(p, "nature/tree_pineRoundA", Vector3(-0.9, 1.3, -1.1), 0.0, 1.0)
	add(p, "nature/tree_pineTallA", Vector3(-0.45, 1.4, -1.0), 0.0, 0.8)
	add(p, "nature/tree_pineDefaultA", Vector3(1.2, 0.9, -0.8), 0.0, 0.9)
	add(p, "nature/grass_large", Vector3(1.4, 0, 0.3), 0.0, 1.2)
	add(p, "nature/rock_smallA", Vector3(-1.5, 0, 0.6), 30.0, 1.4)
	var entrance := MeshInstance3D.new()
	var hole := BoxMesh.new()
	hole.size = Vector3(0.72, 0.8, 0.3)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("2a1d14")
	hole.material = dark
	entrance.mesh = hole
	entrance.position = Vector3(0, 0.4, 0.32)
	p.add_child(entrance)
	if level == 0:
		# Zatarasený vchod.
		var boards := add(p, "town/planks", Vector3(0, 0.45, 0.5), 0.0, 0.75)
		boards.rotation_degrees = Vector3(90, 0, 8)
		add(p, "town/rock-small", Vector3(0.45, 0, 0.75), 0.0, 0.3)
		add(p, "town/rock-small", Vector3(-0.4, 0, 0.8), 70.0, 0.25)
		add(p, "survival/signpost", Vector3(0.9, 0, 0.9), -20.0, 1.2)
		return
	# Drevená výstuž vchodu a koľaje.
	add(p, "town/pillar-wood", Vector3(-0.38, 0, 0.55), 0.0, 0.8)
	add(p, "town/pillar-wood", Vector3(0.38, 0, 0.55), 0.0, 0.8)
	var beam := add(p, "town/pillar-wood", Vector3(-0.45, 0.8, 0.55), 0.0, 0.8)
	beam.rotation_degrees = Vector3(0, 0, -90)
	beam.scale = Vector3(0.8, 1.15, 0.8)
	add(p, "town/lantern", Vector3(0.55, 0, 0.75), 0.0, 0.45)
	for i in 3:
		var rail := add(p, "survival/floor-hole", Vector3(0, 0, 0.75 + i * 0.5), 0.0, 1.0)
		rail.scale = Vector3(0.6, 0.4, 1.0)
	if level >= 2:
		add(p, "survival/structure", Vector3(1.3, 0, 0.55), 0.0, 1.0)
		add(p, "survival/barrel", Vector3(1.25, 0, 0.95), 0.0, 1.3)
		add(p, "survival/box-large", Vector3(-1.25, 0, 0.6), 80.0, 1.3)
		add(p, "survival/tool-pickaxe", Vector3(-0.9, 0, 0.8), 30.0, 1.5)
		add(p, "town/lantern", Vector3(-0.55, 0, 0.75), 0.0, 0.45)
	if level >= 3:
		add(p, "town/banner-red", Vector3(1, 0, 0), SOUTH, 1.0)
		add(p, "town/banner-red", Vector3(-1, 0, 0), SOUTH, 1.0)
		add(p, "survival/chest", Vector3(-1.3, 0, 1.05), 20.0, 1.4)
		for i in 3:
			gold_nugget(p, Vector3(-1.0 + i * 0.15, 0, 1.1 + (i % 2) * 0.12), 0.9)


# --- Kováčska dielňa -------------------------------------------------------------

static func _blacksmith(p: Node3D, level: int) -> void:
	if level == 0:
		# Stavenisko: lešenie, dosky a tabuľa.
		add(p, "survival/structure", Vector3(0, 0, 0), 0.0, 1.6)
		add(p, "survival/resource-planks", Vector3(0.75, 0, 0.5), 10.0, 1.4)
		add(p, "survival/resource-planks", Vector3(0.75, 0.09, 0.5), -5.0, 1.4)
		add(p, "survival/resource-stone-large", Vector3(-0.75, 0, 0.55), 0.0, 1.4)
		add(p, "survival/signpost", Vector3(0.1, 0, 0.85), 10.0, 1.2)
		return
	# Otvorená vyhňa: stĺpy, strecha, nákova a oheň.
	for corner: Vector3 in [Vector3(-0.42, 0, 0.42), Vector3(0.42, 0, 0.42)]:
		add(p, "town/pillar-wood", corner)
	add(p, "town/wall", Vector3.ZERO, NORTH)
	add(p, "town/wall-wood-half", Vector3.ZERO, WEST)
	add(p, "town/roof-point", Vector3(0, 1, 0))
	add(p, "survival/workbench-anvil", Vector3(0.15, 0, 0.1), -20.0, 1.5)
	add(p, "survival/campfire-pit", Vector3(-0.25, 0, -0.2), 0.0, 1.4)
	fire(p, Vector3(-0.25, 0.08, -0.2))
	add(p, "survival/tool-hammer", Vector3(0.3, 0.34 * 1.5, 0.05), 40.0, 1.3)
	add(p, "survival/barrel-open", Vector3(0.62, 0, 0.62), 0.0, 1.3)
	if level >= 2:
		# Kamenná dielňa vedľa vyhne s komínom.
		_cell(p, Vector3(1, 0, 0), {
			SOUTH: "town/wall-door", EAST: "town/wall-window-shutters", NORTH: "town/wall", WEST: "town/wall",
		})
		add(p, "town/roof-high-point", Vector3(1, 1, 0))
		add(p, "town/chimney", Vector3(0.85, 1.0, -0.2))
		smoke(p, Vector3(1.05, 2.05, -0.03))
		add(p, "survival/workbench-grind", Vector3(1.55, 0, 0.75), 0.0, 1.4)
		add(p, "town/banner-red", Vector3(1, 0, 0), SOUTH, 1.0)
		add(p, "survival/box", Vector3(-0.7, 0, 0.7), 15.0, 1.3)


# --- Obchod ----------------------------------------------------------------------

static func _shop(p: Node3D) -> void:
	add(p, "town/stall-red", Vector3(-0.55, 0, 0), 0.0)
	add(p, "town/stall-green", Vector3(0.55, 0, 0), 0.0)
	add(p, "survival/box", Vector3(-1.15, 0, 0.35), 15.0, 1.3)
	add(p, "survival/box-open", Vector3(-1.1, 0, -0.1), -10.0, 1.3)
	add(p, "survival/barrel", Vector3(1.15, 0, 0.3), 0.0, 1.3)
	add(p, "town/stall-stool", Vector3(0.1, 0, 0.75), 0.0, 1.2)
	add(p, "town/lantern", Vector3(1.2, 0, -0.3), 0.0, 0.6)


## Plamene vyhne s oranžovým svetlom.
static func fire(parent: Node3D, pos: Vector3) -> void:
	var flames := _particles(Color("ffb02e"), Color(1.0, 0.3, 0.1, 0.0), 0.12, 0.6)
	flames.position = pos
	flames.amount = 16
	flames.emission_sphere_radius = 0.08
	flames.initial_velocity_min = 0.3
	flames.initial_velocity_max = 0.6
	parent.add_child(flames)
	var light := OmniLight3D.new()
	light.light_color = Color("ff9a3c")
	light.light_energy = 1.6
	light.omni_range = 1.4
	light.position = pos + Vector3(0, 0.25, 0)
	parent.add_child(light)


## Dym z komína.
static func smoke(parent: Node3D, pos: Vector3) -> void:
	var puffs := _particles(Color(0.95, 0.95, 0.95, 0.85), Color(0.9, 0.9, 0.9, 0.0), 0.16, 2.6)
	puffs.position = pos
	puffs.amount = 8
	puffs.initial_velocity_min = 0.25
	puffs.initial_velocity_max = 0.4
	puffs.scale_amount_min = 0.8
	puffs.scale_amount_max = 1.6
	parent.add_child(puffs)


static func _particles(start: Color, end: Color, size: float, lifetime: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.local_coords = true
	particles.lifetime = lifetime
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.04
	particles.direction = Vector3.UP
	particles.spread = 12.0
	particles.gravity = Vector3.ZERO
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	particles.mesh = mesh
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([start, end])
	particles.color_ramp = ramp
	return particles


## Hrudka zlata (kameň s lesklým zlatým materiálom).
static func gold_nugget(parent: Node3D, pos: Vector3, scale: float = 1.0) -> Node3D:
	var nugget := add(parent, "survival/resource-stone", pos, pos.x * 131.0, scale)
	for mesh: MeshInstance3D in nugget.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = gold_material()
	return nugget


static func gold_material() -> StandardMaterial3D:
	if _gold_material == null:
		_gold_material = StandardMaterial3D.new()
		_gold_material.albedo_color = GOLD
		_gold_material.metallic = 0.6
		_gold_material.roughness = 0.3
		_gold_material.emission_enabled = true
		_gold_material.emission = Color("aa7700")
		_gold_material.emission_energy_multiplier = 0.4
	return _gold_material
