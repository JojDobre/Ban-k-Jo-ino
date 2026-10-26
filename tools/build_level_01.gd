extends SceneTree
## Postaví scenes/levels/level_01.tscn z textovej mapy nižšie.
## Spustenie: godot --headless --path . -s res://tools/build_level_01.gd
##
## POZOR: prepíše level_01.tscn. Ak level upravuješ ručne v editore, generátor už nespúšťaj
## (alebo najprv prenes zmeny sem). Po zmene mapy spusti tests/level_checks.tscn.
##
## MAP – 1 znak = 1 dlaždica 64×64 px, riadok 9 je bežná výška zeme:
##   Terén:      #  tráva   =  oblak (plošina zospodu priechodná)   L  láva
##   Hráč, cieľ: P  štart   D  cieľové dvere   K  checkpoint   J  pružina
##   Predmety:   C  minca   S  hviezda (a, b, c zľava)   G  zlatý poklad   H  srdce   k  kľúč
##               U  kryštál štítu   V  kryštál rýchlosti   R  kryštál magnetu
##   Bloky:      ?  minca   $  veľa mincí   h  srdce   u/v/w  kryštál štítu/rýchlosti/magnetu
##               o  tehla   i  skrytý blok s mincou   j  skrytý blok so srdcom
##               l  zámok (otvorí ho kľúč)   T  vypínač   t  modrý blok (pevný)   q  modrý blok (vypnutý)
##   Plošiny:    -  pohyblivá vodorovne   |  pohyblivá zvislo   _  padajúci mostík   ~  mostík
##   Nebezpečné: ^  ostne   X  drvič   W  píla
##   Nepriatelia: E  sliz   Z  ostnatý sliz   N  slimák   M  myš (rozbieha sa)   F  žaba   B  včela   Y  mucha (mizne)
##   Dekorácie:  b  ker   g  tráva   p  fialová tráva   m/n  hríb   r  kameň   f  plot   s  smerovka
##   (Na voľných miestach na zemi sa doplnia náhodné dekorácie.)
##
## SECRET – rovnaký rozmer; „%“ = falošná stena: vyzerá ako zem, ale dá sa ňou prejsť
## a pri vstupe sa zprehľadní (tajné miesto). Obsah buniek ostáva v MAP.

const MAP := [
	"                                                                                                                                                                                                                        ",
	"                                                                               CCCk                                     S                                                                                               ",
	"                                                                               =====                                                                                                                                    ",
	"                                                                                                                 Y    q                                                              X     X                  S         ",
	"            C                                                                                     X                                  B                                                                                  ",
	"         ? o?o h      i         B                                                                              t    q                                    ?o$ov               j                                          ",
	"                              C C C   CCCC                                              #######                t                  CCCCCC                          #######                                    B          ",
	"                                                                                        l     #                t  q                                                C   C                                                ",
	" bP s  CCC        E            _ _     ^^     M     K    F  g           b       J     ##lCCGCC#  CCC   Z   T   t         ^^      -           K    W   F      N     CHCRC   g    U   CC CC CC       M      b        D ff ",
	"##############################     ###############################  ###########################################################          | #############################################################################",
	"##############################LLLLL############################        ########################################################LLLLLLLLLLLL#############################################################################",
	"##############################LLLLL############################ C    C ########################################################LLLLLLLLLLLL#############################################################################",
	"##############################LLLLL############################CC J CSC########################################################LLLLLLLLLLLL#############################################################################",
	"##############################LLLLL############################################################################################LLLLLLLLLLLL#############################################################################",
]

const SECRET := [
	"                                                                                                                                                                                                                        ",
	"                                                                                                                                                                                                                        ",
	"                                                                                                                                                                                                                        ",
	"                                                                                                                                                                                                                        ",
	"                                                                                                                                                                                                                        ",
	"                                                                                                                                                                                                                        ",
	"                                                                                                                                                                                                                        ",
	"                                                                                                                                                                  %%%%%%%                                               ",
	"                                                                                                                                                                  %%%%%%%                                               ",
	"                                                                  %%                                                                                                                                                    ",
	"                                                               %%%%%%%%                                                                                                                                                 ",
	"                                                               %%%%%%%%                                                                                                                                                 ",
	"                                                               %%%%%%%%                                                                                                                                                 ",
	"                                                                                                                                                                                                                        ",
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
	"H": "res://scenes/items/heart.tscn",
	"U": "res://scenes/items/crystal_blue.tscn",
	"V": "res://scenes/items/crystal_green.tscn",
	"R": "res://scenes/items/crystal_red.tscn",
	"k": "res://scenes/items/key.tscn",
	"K": "res://scenes/items/checkpoint.tscn",
	"D": "res://scenes/items/goal.tscn",
	"J": "res://scenes/items/spring.tscn",
	"E": "res://scenes/enemies/slime.tscn",
	"Z": "res://scenes/enemies/spike_slime.tscn",
	"N": "res://scenes/enemies/snail.tscn",
	"M": "res://scenes/enemies/mouse.tscn",
	"F": "res://scenes/enemies/frog.tscn",
	"B": "res://scenes/enemies/bee.tscn",
	"Y": "res://scenes/enemies/fly.tscn",
	"?": "res://scenes/blocks/bump_block.tscn",
	"$": "res://scenes/blocks/bump_block.tscn",
	"h": "res://scenes/blocks/bump_block.tscn",
	"u": "res://scenes/blocks/bump_block.tscn",
	"v": "res://scenes/blocks/bump_block.tscn",
	"w": "res://scenes/blocks/bump_block.tscn",
	"o": "res://scenes/blocks/bump_block.tscn",
	"i": "res://scenes/blocks/bump_block.tscn",
	"j": "res://scenes/blocks/bump_block.tscn",
	"l": "res://scenes/blocks/lock_block.tscn",
	"t": "res://scenes/blocks/toggle_block.tscn",
	"q": "res://scenes/blocks/toggle_block.tscn",
	"T": "res://scenes/blocks/switch.tscn",
	"^": "res://scenes/hazards/spikes.tscn",
	"X": "res://scenes/hazards/crusher.tscn",
	"W": "res://scenes/hazards/saw.tscn",
	"-": "res://scenes/platforms/moving_platform.tscn",
	"|": "res://scenes/platforms/moving_platform.tscn",
	"_": "res://scenes/platforms/falling_platform.tscn",
	"~": "res://scenes/platforms/bridge.tscn",
}
## Skupina (uzol v leveli), do ktorej sa objekt pridá.
const GROUPS := {
	"C": "Coins", "S": "Secrets", "G": "Secrets", "H": "Items", "U": "Items", "V": "Items", "R": "Items", "k": "Items",
	"E": "Enemies", "Z": "Enemies", "N": "Enemies", "M": "Enemies", "F": "Enemies", "B": "Enemies", "Y": "Enemies",
	"?": "Blocks", "$": "Blocks", "h": "Blocks", "u": "Blocks", "v": "Blocks", "w": "Blocks", "o": "Blocks",
	"i": "Blocks", "j": "Blocks", "l": "Blocks", "t": "Blocks", "q": "Blocks", "T": "Blocks",
	"^": "Hazards", "X": "Hazards", "W": "Hazards",
	"-": "Platforms", "|": "Platforms", "_": "Platforms", "~": "Platforms",
}
## Výška pôvodu objektu nad spodkom dlaždice (objekty stoja na zemi).
const GROUND_OFFSET := {
	"P": 36.0, "E": 17.0, "Z": 20.0, "N": 20.0, "M": 18.0, "F": 22.0,
	"K": 0.0, "D": 0.0, "J": 0.0, "T": 0.0, "^": 0.0,
}
## Plošiny majú pôvod na hornom okraji dlaždice (= povrch, na ktorom sa stojí).
const TOP_ALIGNED := ["-", "|", "_", "~"]

const PROPS := {
	"b": "res://assets/props/bush.png",
	"g": "res://assets/props/grass.png",
	"p": "res://assets/props/grass_purple.png",
	"m": "res://assets/props/mushroom_red.png",
	"n": "res://assets/props/mushroom_brown.png",
	"r": "res://assets/props/rock.png",
	"f": "res://assets/props/fence.png",
	"s": "res://assets/props/sign_right.png",
}
## Dekorácie, ktoré sa hýbu vo vetre.
const SWAYING := ["b", "g", "p", "m", "n"]
## Náhodné dekorácie (váhy opakovaním) a pravdepodobnosť na voľnej bunke.
const AUTO_PROPS := "gggppbbmnr"
const AUTO_PROP_CHANCE := 0.4

var _root: Node2D
var _width: int
var _rng := RandomNumberGenerator.new()
var _sway_material: Material


func _initialize() -> void:
	_width = MAP[0].length()
	_rng.seed = 7
	_sway_material = load("res://assets/shaders/sway_material.tres")
	_root = Node2D.new()
	_root.name = "Level01"
	_root.set_script(load("res://scripts/levels/level_controller.gd"))
	_root.set("level_definition", load("res://data/levels/level_01.tres"))
	_root.set("level_width", float(_width * TILE))
	_root.set("camera_limit_bottom", float(MAP.size() * TILE))
	_root.set("fall_limit_y", float(MAP.size() * TILE + TILE))

	_add_instance("res://scenes/levels/environment.tscn", _root, Vector2.ZERO)
	_build_background()
	_build_lava()
	_build_terrain()
	_build_walls()
	_build_objects()
	_build_secrets()
	_add_instance("res://scenes/ui/hud.tscn", _root, Vector2.ZERO)

	var scene := PackedScene.new()
	var err := scene.pack(_root)
	if err == OK:
		err = ResourceSaver.save(scene, OUTPUT)
	print("uložené: " if err == OK else "CHYBA: ", OUTPUT)
	_root.free()
	quit(0 if err == OK else 1)


func _build_background() -> void:
	# Vrstvy od najvzdialenejšej. scroll_scale < 1 = pohyb pomalší ako kamera (hĺbka).
	var layers := [
		["Clouds", "res://assets/backgrounds/layer_clouds.png", 0.1, 2.0, 40.0, -14.0],
		["Trees", "res://assets/backgrounds/layer_trees.png", 0.25, 2.0, 90.0, 0.0],
		["Hills", "res://assets/backgrounds/layer_hills.png", 0.45, 2.0, 100.0, 0.0],
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
		# Oblaky sa pomaly unášajú aj bez pohybu kamery.
		parallax.autoscroll = Vector2(layer[5], 0)
		_add(parallax, background)
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2(scale, scale)
		sprite.position = Vector2(0, layer[4])
		_add(sprite, parallax)


func _build_terrain() -> void:
	var layer := TileMapLayer.new()
	layer.name = "Terrain"
	layer.tile_set = load("res://assets/tilesets/terrain.tres")
	_add(layer, _root)
	for row in MAP.size():
		for col in _width:
			var ch := _cell(col, row)
			if ch == "#":
				layer.set_cell(Vector2i(col, row), 0, Vector2i(GRASS_TILES[_grass_key(col, row)], 0))
			elif ch == "=":
				var left := _cell(col - 1, row) == "="
				var right := _cell(col + 1, row) == "="
				layer.set_cell(Vector2i(col, row), 0, Vector2i(1 if left and right else (2 if left else 0), 1))


func _cell(col: int, row: int) -> String:
	if row < 0 or row >= MAP.size() or col < 0 or col >= _width:
		return ""
	return MAP[row][col]


func _is_fake(col: int, row: int) -> bool:
	return row >= 0 and row < SECRET.size() and col >= 0 and col < _width and SECRET[row][col] == "%"


## Je bunka zem (skutočná alebo falošná)? Okraje mapy (okrem hornej) sa berú ako zem.
func _is_ground(col: int, row: int) -> bool:
	if row < 0:
		return false
	if row >= MAP.size() or col < 0 or col >= _width:
		return true
	return MAP[row][col] == "#" or _is_fake(col, row)


## Reťazec „hore, vpravo, dole, vľavo“ pre výber dielu trávy.
func _grass_key(col: int, row: int) -> String:
	var key := ""
	for offset: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		key += "1" if _is_ground(col + offset.x, row + offset.y) else "0"
	return key


func _build_walls() -> void:
	# Neviditeľné steny na okrajoch levelu.
	for side: Array in [["LeftWall", 0.0, Vector2.RIGHT], ["RightWall", float(_width * TILE), Vector2.LEFT]]:
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


## Láva: pre každé súvislé jazero jedna oblasť (Lava) s vlniacou sa hladinou, žiarou a bublinkami.
func _build_lava() -> void:
	var shader: Shader = load("res://assets/shaders/lava.gdshader")
	var visited := {}
	for row in MAP.size():
		for col in _width:
			if _cell(col, row) != "L" or visited.has(Vector2i(col, row)):
				continue
			# Obdĺžnik jazera: šírka podľa horného riadku, výška po spodok mapy.
			var end := col
			while _cell(end + 1, row) == "L":
				end += 1
			var bottom := row
			while _cell(col, bottom + 1) == "L":
				bottom += 1
			for r in range(row, bottom + 1):
				for c in range(col, end + 1):
					visited[Vector2i(c, r)] = true
			_add_lava(Rect2i(col, row, end - col + 1, bottom - row + 1), shader)


func _add_lava(cells: Rect2i, shader: Shader) -> void:
	var lava := Area2D.new()
	lava.name = "Lava"
	lava.collision_layer = 0
	lava.collision_mask = 2
	lava.monitorable = false
	lava.set_script(load("res://scripts/hazards/lava.gd"))
	lava.position = Vector2(cells.position) * TILE
	_add(lava, _root)
	var size := Vector2(cells.size) * TILE
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x, size.y - 20)
	shape.shape = rect
	shape.position = Vector2(size.x * 0.5, 20 + rect.size.y * 0.5)
	_add(shape, lava)

	var glow := TextureRect.new()
	glow.name = "Glow"
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 0.55, 0.15, 0), Color(1, 0.55, 0.15, 0.45)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	glow.texture = texture
	glow.position = Vector2(-TILE, -TILE * 2)
	glow.size = Vector2(size.x + TILE * 2, TILE * 2 + 16)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(glow, lava)

	for r in cells.size.y:
		var sprite := Sprite2D.new()
		sprite.name = "Surface" if r == 0 else "Body%d" % r
		sprite.texture = load("res://assets/hazards/lava_top.png" if r == 0 else "res://assets/hazards/lava.png")
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, size.x, TILE)
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.position = Vector2(0, r * TILE)
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("wave", 3.0 if r == 0 else 0.0)
		sprite.material = material
		_add(sprite, lava)

	var bubbles := CPUParticles2D.new()
	bubbles.name = "Bubbles"
	bubbles.position = Vector2(size.x * 0.5, 14)
	bubbles.amount = int(cells.size.x * 2)
	bubbles.lifetime = 1.2
	bubbles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	bubbles.emission_rect_extents = Vector2(size.x * 0.5 - 8, 4)
	bubbles.direction = Vector2.UP
	bubbles.spread = 15.0
	bubbles.initial_velocity_min = 20.0
	bubbles.initial_velocity_max = 60.0
	bubbles.gravity = Vector2(0, 30)
	bubbles.scale_amount_min = 3.0
	bubbles.scale_amount_max = 7.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1, 0.85, 0.3, 0.9), Color(1, 0.4, 0.1, 0)])
	bubbles.color_ramp = ramp
	_add(bubbles, lava)


func _build_objects() -> void:
	var groups := {}
	for group_name: String in ["Props", "Platforms", "Blocks", "Hazards", "Coins", "Items", "Secrets", "Enemies", "Objects"]:
		var group := Node2D.new()
		group.name = group_name
		_add(group, _root)
		groups[group_name] = group

	var stars: Array[Node] = []
	for row in MAP.size():
		for col in _width:
			var ch := _cell(col, row)
			var center := Vector2(col * TILE + TILE * 0.5, row * TILE + TILE * 0.5)
			var bottom := Vector2(center.x, (row + 1) * TILE)
			if PROPS.has(ch):
				_add_prop(ch, bottom, groups.Props)
			elif SCENES.has(ch):
				var position := center
				if GROUND_OFFSET.has(ch):
					position = bottom - Vector2(0, GROUND_OFFSET[ch])
				elif ch in TOP_ALIGNED:
					position = Vector2(center.x, row * TILE)
				var parent: Node = groups.get(GROUPS.get(ch, ""), groups.Objects)
				if ch == "P":
					parent = _root
				var node := _add_instance(SCENES[ch], parent, position)
				_configure(node, ch)
				if ch == "S":
					stars.append(node)
			elif ch == " " and _is_ground(col, row + 1) and not _is_fake(col, row + 1) and not _is_fake(col, row) and _cell(col, row + 1) == "#":
				# Voľné miesto na zemi – náhodná dekorácia (nie vedľa objektov).
				if not _near_object(col, row) and _rng.randf() < AUTO_PROP_CHANCE:
					_add_prop(AUTO_PROPS[_rng.randi() % AUTO_PROPS.length()], bottom, groups.Props)

	# Hviezdy dostanú id a, b, c zľava doprava.
	stars.sort_custom(func(a: Node, b: Node) -> bool: return a.position.x < b.position.x)
	for i in stars.size():
		var star_id := "abcdefgh"[i]
		stars[i].set("star_id", star_id)
		stars[i].name = "Star_" + star_id


func _configure(node: Node, ch: String) -> void:
	var blocks := "res://assets/blocks/"
	match ch:
		"$":
			node.set("coin_count", 8)
			node.set("active_texture", load(blocks + "block_strong_coin_active.png"))
			node.set("empty_texture", load(blocks + "block_strong_empty.png"))
		"h", "u", "v", "w", "j":
			var items := {"h": "heart", "j": "heart", "u": "crystal_blue", "v": "crystal_green", "w": "crystal_red"}
			node.set("content", 1)  # BumpBlock.Content.ITEM (trieda sa v -s skripte nedá použiť)
			node.set("item_scene", load("res://scenes/items/%s.tscn" % items[ch]))
			node.set("active_texture", load(blocks + "block_exclamation_active.png"))
			if ch == "j":
				node.set("invisible", true)
		"i":
			node.set("invisible", true)
		"o":
			node.set("content", 2)  # BumpBlock.Content.BRICK
			node.set("active_texture", load(blocks + "bricks_brown.png"))
		"q":
			node.set("starts_solid", false)
		"-":
			node.set("travel", Vector2(320, 0))
			node.set("duration", 3.0)
		"|":
			node.set("travel", Vector2(0, -192))
			node.set("duration", 2.2)


func _near_object(col: int, row: int) -> bool:
	for dc in range(-1, 2):
		var ch := _cell(col + dc, row)
		if ch != " " and ch != "" and not PROPS.has(ch):
			return true
	return false


func _add_prop(ch: String, bottom: Vector2, parent: Node) -> void:
	var prop := Sprite2D.new()
	prop.name = "Prop"
	prop.texture = load(PROPS[ch])
	prop.position = bottom - Vector2(0, TILE * 0.5)
	if ch in SWAYING:
		prop.material = _sway_material
		prop.flip_h = _rng.randf() < 0.5
		var scale := _rng.randf_range(0.85, 1.1)
		prop.scale = Vector2(scale, scale)
		prop.position.y += TILE * 0.5 * (1.0 - scale)
	_add(prop, parent)


## Falošné steny: každá súvislá skupina „%“ je jedno tajné miesto (SecretArea)
## s vlastnou vrstvou dlaždíc bez kolízie, kreslenou pred Jožinom.
func _build_secrets() -> void:
	var tile_set: TileSet = load("res://assets/tilesets/terrain.tres")
	var visited := {}
	var index := 0
	for row in SECRET.size():
		for col in _width:
			if not _is_fake(col, row) or visited.has(Vector2i(col, row)):
				continue
			var cells: Array[Vector2i] = []
			var stack: Array[Vector2i] = [Vector2i(col, row)]
			visited[Vector2i(col, row)] = true
			while not stack.is_empty():
				var cell: Vector2i = stack.pop_back()
				cells.append(cell)
				for offset: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
					var next := cell + offset
					if _is_fake(next.x, next.y) and not visited.has(next):
						visited[next] = true
						stack.append(next)
			index += 1
			_add_secret(cells, tile_set, index)


func _add_secret(cells: Array[Vector2i], tile_set: TileSet, index: int) -> void:
	var bounds := Rect2i(cells[0], Vector2i.ONE)
	for cell in cells:
		bounds = bounds.expand(cell).expand(cell + Vector2i.ONE)
	var area := Area2D.new()
	area.name = "Secret%d" % index
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitorable = false
	area.set_script(load("res://scripts/levels/secret_area.gd"))
	_add(area, _root)
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(bounds.size) * TILE
	shape.shape = rect
	shape.position = Vector2(bounds.position) * TILE + rect.size * 0.5
	_add(shape, area)
	# Tmavá zadná stena jaskyne – po zprehľadnení steny nie je vidieť oblohu.
	var back := TileMapLayer.new()
	back.name = "Back"
	back.tile_set = tile_set
	back.collision_enabled = false
	back.z_index = -1
	back.modulate = Color(0.42, 0.3, 0.26)
	_add(back, area)
	for cell in cells:
		back.set_cell(cell, 0, Vector2i(GRASS_TILES["1111"], 0))
	var wall := TileMapLayer.new()
	wall.name = "Wall"
	wall.tile_set = tile_set
	wall.collision_enabled = false
	wall.z_index = 5
	_add(wall, area)
	for cell in cells:
		wall.set_cell(cell, 0, Vector2i(GRASS_TILES[_grass_key(cell.x, cell.y)], 0))


func _add_instance(path: String, parent: Node, position: Vector2) -> Node:
	var node: Node = load(path).instantiate()
	if node is Node2D:
		node.position = position
	_add(node, parent)
	return node


func _add(node: Node, parent: Node) -> void:
	parent.add_child(node, true)
	node.owner = _root
