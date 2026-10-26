extends SceneTree
## Postaví scenes/levels/level_01.tscn z textovej mapy nižšie.
## Spustenie: godot --headless --path . -s res://tools/build_level_01.gd
##
## POZOR: prepíše level_01.tscn. Ak level upravuješ ručne v editore, generátor už nespúšťaj
## (alebo najprv prenes zmeny sem).
##
## Legenda (1 znak = 1 dlaždica 64×64 px, riadok 9 je bežná výška zeme):
##   #  tráva (zem)              =  oblak – plošina, na ktorú sa dá vyskočiť zospodu
##   P  štart Jožina             D  cieľové dvere           K  checkpoint
##   C  minca                    S  hviezda (id a, b, c zľava)   G  zlatý poklad
##   E  nepriateľ sliz           N  nepriateľ slimák        J  pružina
##   b  ker   g  tráva   m  hríb   r  kameň   f  plot   s  smerovka

const MAP := [
	"                                                                                                                                  ",
	"                              S                                                                                                   ",
	"                                                       CCCC G                                                                     ",
	"                                                       =======                                                  S                 ",
	"                             ===                                                                                                  ",
	"                                                                           CC                                                     ",
	"                   CCCC  ===                                             CC##                         CCC                         ",
	"             CC    ####        CC                ==                      ####     g                   ===                         ",
	" bP s  CCCCC ##  g ####   b       r g  E CCC  m      K    J    ff  N b ######   ##### g E CCCC E  b         g E   CCCCC  D  ff b  ",
	"###############################  ################  ########################## S #####################     ########################",
	"###############################  ################  ##########################===#####################     ########################",
	"###############################  ################  ##########################   #####################     ########################",
	"###############################  ################  ##########################   #####################     ########################",
	"###############################  ################  ##########################   #####################     ########################",
]

const TILE := 64
const OUTPUT := "res://scenes/levels/level_01.tscn"

# Susedia (hore, vpravo, dole, vľavo) -> stĺpec v atlase. Zhodné s tools/build_resources.gd.
const GRASS_TILES := {
	"0000": 0, "0100": 1, "0101": 2, "0001": 3,
	"0010": 4, "1010": 5, "1000": 6,
	"0110": 7, "0111": 8, "0011": 9,
	"1110": 10, "1111": 11, "1011": 12,
	"1100": 13, "1101": 14, "1001": 15,
}

const SCENES := {
	"P": "res://scenes/player/player.tscn",
	"C": "res://scenes/items/coin.tscn",
	"S": "res://scenes/items/star.tscn",
	"G": "res://scenes/items/chest.tscn",
	"K": "res://scenes/items/checkpoint.tscn",
	"D": "res://scenes/items/goal.tscn",
	"J": "res://scenes/items/spring.tscn",
	"E": "res://scenes/enemies/slime.tscn",
	"N": "res://scenes/enemies/snail.tscn",
}
const PROPS := {
	"b": "res://assets/props/bush.png",
	"g": "res://assets/props/grass.png",
	"m": "res://assets/props/mushroom_red.png",
	"r": "res://assets/props/rock.png",
	"f": "res://assets/props/fence.png",
	"s": "res://assets/props/sign_right.png",
}
## Výška pôvodu objektu nad spodkom dlaždice (objekty stoja na zemi).
const GROUND_OFFSET := {"P": 36.0, "E": 17.0, "N": 20.0, "K": 0.0, "D": 0.0, "J": 0.0}

var _root: Node2D
var _star_ids := ["a", "b", "c"]


func _initialize() -> void:
	var width := MAP[0].length()
	_root = Node2D.new()
	_root.name = "Level01"
	_root.set_script(load("res://scripts/levels/level_controller.gd"))
	_root.set("level_definition", load("res://data/levels/level_01.tres"))
	_root.set("level_width", float(width * TILE))
	_root.set("camera_limit_bottom", float(MAP.size() * TILE))
	_root.set("fall_limit_y", float(MAP.size() * TILE + TILE))

	_build_background(width)
	_build_terrain(width)
	_build_walls(width)
	_build_objects()
	_add_instance("res://scenes/ui/hud.tscn", _root, Vector2.ZERO)

	var scene := PackedScene.new()
	var err := scene.pack(_root)
	if err == OK:
		err = ResourceSaver.save(scene, OUTPUT)
	print("uložené: " if err == OK else "CHYBA: ", OUTPUT)
	_root.free()
	quit(0 if err == OK else 1)


func _build_background(width: int) -> void:
	# Vrstvy od najvzdialenejšej. scroll_scale < 1 = pohyb pomalší ako kamera (hĺbka).
	var layers := [
		["Clouds", "res://assets/backgrounds/layer_clouds.png", 0.1, 2.0, 40.0],
		["Trees", "res://assets/backgrounds/layer_trees.png", 0.25, 2.0, 90.0],
		["Hills", "res://assets/backgrounds/layer_hills.png", 0.45, 2.0, 100.0],
	]
	var background := Node2D.new()
	background.name = "Background"
	background.z_index = -10
	_add(background, _root)
	for layer: Array in layers:
		var texture: Texture2D = load(layer[1])
		var scale: float = layer[3]
		var parallax := Parallax2D.new()
		parallax.name = layer[0]
		parallax.scroll_scale = Vector2(layer[2], layer[2])
		parallax.repeat_size = Vector2(texture.get_width() * scale, 0)
		_add(parallax, background)
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2(scale, scale)
		sprite.position = Vector2(0, layer[4])
		_add(sprite, parallax)


func _build_terrain(width: int) -> void:
	var layer := TileMapLayer.new()
	layer.name = "Terrain"
	layer.tile_set = load("res://assets/tilesets/terrain.tres")
	_add(layer, _root)
	for row in MAP.size():
		for col in width:
			var ch: String = MAP[row][col]
			if ch == "#" or ch == "=":
				var key := _neighbors(col, row, ch, width)
				if ch == "#":
					layer.set_cell(Vector2i(col, row), 0, Vector2i(GRASS_TILES[key], 0))
				else:
					var left := key[3] == "1"
					var right := key[1] == "1"
					layer.set_cell(Vector2i(col, row), 0, Vector2i(1 if left and right else (2 if left else 0), 1))


## Reťazec „hore, vpravo, dole, vľavo“; okraje mapy (okrem hornej) sa berú ako plné.
func _neighbors(col: int, row: int, ch: String, width: int) -> String:
	var offsets := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	var key := ""
	for offset: Vector2i in offsets:
		var c := col + offset.x
		var r := row + offset.y
		var same: bool
		if r < 0:
			same = false
		elif r >= MAP.size() or c < 0 or c >= width:
			same = ch == "#"
		else:
			same = MAP[r][c] == ch
		key += "1" if same else "0"
	return key


func _build_walls(width: int) -> void:
	# Neviditeľné steny na okrajoch levelu.
	for side: Array in [["LeftWall", 0.0, Vector2.RIGHT], ["RightWall", float(width * TILE), Vector2.LEFT]]:
		var body := StaticBody2D.new()
		body.name = side[0]
		body.position = Vector2(side[1], 0)
		body.collision_mask = 0
		_add(body, _root)
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var boundary := WorldBoundaryShape2D.new()
		boundary.normal = side[2]
		shape.shape = boundary
		_add(shape, body)


func _build_objects() -> void:
	var groups := {}
	for group_name: String in ["Props", "Coins", "Secrets", "Enemies", "Objects"]:
		var group := Node2D.new()
		group.name = group_name
		_add(group, _root)
		groups[group_name] = group

	var star_index := 0
	for row in MAP.size():
		var line: String = MAP[row]
		for col in line.length():
			var ch := line[col]
			var center := Vector2(col * TILE + TILE * 0.5, row * TILE + TILE * 0.5)
			var bottom := Vector2(center.x, (row + 1) * TILE)
			if PROPS.has(ch):
				var prop := Sprite2D.new()
				prop.name = "Prop"
				prop.texture = load(PROPS[ch])
				prop.position = bottom - Vector2(0, TILE * 0.5)
				_add(prop, groups.Props)
			elif SCENES.has(ch):
				var position := bottom - Vector2(0, GROUND_OFFSET[ch]) if GROUND_OFFSET.has(ch) else center
				var parent: Node = groups.Objects
				match ch:
					"C":
						parent = groups.Coins
					"S", "G":
						parent = groups.Secrets
					"E", "N":
						parent = groups.Enemies
					"P":
						parent = _root
				var node := _add_instance(SCENES[ch], parent, position)
				if ch == "S":
					node.set("star_id", _star_ids[star_index])
					node.name = "Star_" + _star_ids[star_index]
					star_index += 1


func _add_instance(path: String, parent: Node, position: Vector2) -> Node:
	var node: Node = load(path).instantiate()
	if node is Node2D:
		node.position = position
	_add(node, parent)
	return node


func _add(node: Node, parent: Node) -> void:
	parent.add_child(node, true)
	node.owner = _root
