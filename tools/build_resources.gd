extends SceneTree
## Vygeneruje TileSet terénu a SpriteFrames postáv z obrázkov v assets/.
## Spustenie (po `--import`): godot --headless --path . -s res://tools/build_resources.gd
## Výsledné .tres sú v repozitári; spusti znova iba pri zmene obrázkov.

const TILE := 64

# Diel terénu (stĺpec v atlase) -> susedia s rovnakým terénom. Poradie zodpovedá
# TERRAIN_TILES v tools/prepare_assets.py. Režim „match sides“ potrebuje práve 16 dielov.
const T := TileSet.CELL_NEIGHBOR_TOP_SIDE
const R := TileSet.CELL_NEIGHBOR_RIGHT_SIDE
const B := TileSet.CELL_NEIGHBOR_BOTTOM_SIDE
const L := TileSet.CELL_NEIGHBOR_LEFT_SIDE
const GRASS_NEIGHBORS := [
	[], [R], [L, R], [L],
	[B], [T, B], [T],
	[R, B], [L, R, B], [L, B],
	[T, R, B], [T, R, B, L], [T, L, B],
	[T, R], [T, L, R], [T, L],
]
const CLOUD_NEIGHBORS := [[R], [L, R], [L]]
## Viditeľná výška oblačnej plošiny v pixeloch (zvyšok dlaždice je priehľadný).
const CLOUD_HEIGHT := 40.0


func _initialize() -> void:
	_build_tileset()
	_build_player_frames()
	_build_enemy_frames("slime", {"walk": ["slime_normal_walk_a", "slime_normal_walk_b"], "dead": ["slime_normal_flat"]}, 6.0)
	_build_enemy_frames("spike_slime", {"walk": ["slime_spike_walk_a", "slime_spike_walk_b"], "dead": ["slime_spike_flat"]}, 6.0)
	_build_enemy_frames("snail", {"walk": ["snail_walk_a", "snail_walk_b"], "dead": ["snail_shell"]}, 4.0)
	_build_enemy_frames("mouse", {"walk": ["mouse_walk_a", "mouse_walk_b"], "rest": ["mouse_rest"], "dead": ["mouse_rest"]}, 8.0)
	_build_enemy_frames("frog", {"walk": ["frog_idle"], "jump": ["frog_jump"], "rest": ["frog_rest"], "dead": ["frog_rest"]}, 4.0)
	_build_enemy_frames("bee", {"walk": ["bee_a", "bee_b"], "dead": ["bee_rest"]}, 12.0)
	_build_enemy_frames("fly", {"walk": ["fly_a", "fly_b"], "dead": ["fly_rest"]}, 12.0)
	_build_enemy_frames("saw", {"walk": ["saw_a", "saw_b"]}, 10.0)
	quit()


func _build_tileset() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)

	tileset.add_terrain_set()
	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tileset.add_terrain(0)
	tileset.set_terrain_name(0, 0, "Tráva")
	tileset.set_terrain_color(0, 0, Color("46b33a"))
	tileset.add_terrain(0)
	tileset.set_terrain_name(0, 1, "Oblak (plošina)")
	tileset.set_terrain_color(0, 1, Color("ffffff"))

	var source := TileSetAtlasSource.new()
	source.texture = load("res://assets/tilesets/terrain_grass.png")
	source.texture_region_size = Vector2i(TILE, TILE)
	tileset.add_source(source, 0)

	var half := TILE * 0.5
	var full := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for i in GRASS_NEIGHBORS.size():
		_add_terrain_tile(source, Vector2i(i, 0), 0, GRASS_NEIGHBORS[i], full, false)

	# Oblaky sú plošiny, na ktoré sa dá vyskočiť zospodu.
	var top := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, -half + CLOUD_HEIGHT), Vector2(-half, -half + CLOUD_HEIGHT)])
	for i in CLOUD_NEIGHBORS.size():
		_add_terrain_tile(source, Vector2i(i, 1), 1, CLOUD_NEIGHBORS[i], top, true)

	_save(tileset, "res://assets/tilesets/terrain.tres")


func _add_terrain_tile(source: TileSetAtlasSource, coords: Vector2i, terrain: int, neighbors: Array, polygon: PackedVector2Array, one_way: bool) -> void:
	source.create_tile(coords)
	var data := source.get_tile_data(coords, 0)
	data.terrain_set = 0
	data.terrain = terrain
	for side: int in neighbors:
		data.set_terrain_peering_bit(side, terrain)
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, polygon)
	data.set_collision_polygon_one_way(0, 0, one_way)


func _build_player_frames() -> void:
	# animácia -> [fps, slučka]
	var animations := {
		"idle": [12.0, true],
		"run": [14.0, true],
		"jump": [14.0, false],
		"fall": [12.0, true],
		"hurt": [14.0, false],
		"die": [10.0, false],
	}
	# Obleky – zhodné s MINER_OUTFITS v tools/prepare_assets.py.
	for outfit: String in ["green", "yellow", "red_shirt", "blue", "old"]:
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		for anim: String in animations:
			var texture: Texture2D = load("res://assets/player/%s/jozino_%s.png" % [outfit, anim])
			var height := texture.get_height()
			# Snímky sú vedľa seba; šírka snímky je vždy 107 px (pozri prepare_assets.py).
			var frame_width := 107
			var count := texture.get_width() / frame_width
			frames.add_animation(anim)
			frames.set_animation_speed(anim, animations[anim][0])
			frames.set_animation_loop(anim, animations[anim][1])
			for i in count:
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(i * frame_width, 0, frame_width, height)
				frames.add_frame(anim, atlas)
		_save(frames, "res://assets/player/%s/frames.tres" % outfit)


func _build_enemy_frames(enemy_name: String, animations: Dictionary, fps: float) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim: String in animations:
		frames.add_animation(anim)
		frames.set_animation_speed(anim, fps)
		frames.set_animation_loop(anim, anim == "walk")
		for file: String in animations[anim]:
			frames.add_frame(anim, load("res://assets/enemies/%s.png" % file))
	_save(frames, "res://assets/enemies/%s_frames.tres" % enemy_name)


func _save(resource: Resource, path: String) -> void:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Nepodarilo sa uložiť %s: %s" % [path, error_string(err)])
	else:
		print("uložené: ", path)
