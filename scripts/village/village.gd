extends Node3D
## Dedina v 3D (GDD kap. 5): šikmý pohľad na farmu s budovami, ťahaním sa posúva,
## dvoma prstami približuje. Ťuknutie na budovu otvorí panel vylepšenia, ťuknutie na
## vozík vyberie produkciu bane. Logiku rieši VillageManager; obrazovka iba zobrazuje.

## Pohyb prsta (px), po ktorom sa dotyk berie ako ťahanie, nie ťuknutie.
const TAP_SLOP := 14.0
const WHEEL_ZOOM := 1.1

var _selected_id := ""
## index prsta -> posledná pozícia
var _touches: Dictionary = {}
var _drag_distance := 0.0
var _mouse_down := false
var _pending_tap := Vector2.INF

@onready var _camera: VillageCamera = %Camera
@onready var _buildings: Array[VillageBuilding] = [%House, %Mine, %Blacksmith, %Shop]
@onready var _cart: MineCart = %Cart
@onready var _jozino: Villager = %Jozino
@onready var _miner: Villager = %Miner
@onready var _smith: Villager = %Smith
@onready var _panel: Control = %Panel
@onready var _ui: Control = %UI


func _ready() -> void:
	Music.play(&"calm")
	%BackButton.pressed.connect(GameState.go_back)
	%MapButton.pressed.connect(GameState.change_scene.bind(GameState.SCENE_WORLD_MAP))
	%CloseButton.pressed.connect(_panel.hide)
	%BuyButton.pressed.connect(_on_buy)
	VillageManager.building_upgraded.connect(_on_building_upgraded)
	EconomyManager.currency_changed.connect(func(_c: int, _g: int) -> void: _refresh_all())
	ShopManager.outfit_changed.connect(func(_o: String) -> void: _jozino.set_outfit(GameState.progress.outfit))
	_jozino.outfit = GameState.progress.outfit
	_panel.hide()
	VillageDecor.build(%Decor, _occupied_areas())
	_refresh_all()
	# Úvodný nájazd kamery.
	_camera.snap_to(Vector3(0, 0, 4), _camera.max_distance)
	_camera.move_focus_to(Vector3(-0.5, 0, -1))
	_camera.zoom_by(0.82)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _panel.visible:
			_panel.hide()
		else:
			GameState.go_back()


func _refresh_all() -> void:
	for building in _buildings:
		building.refresh()
	var house_ready := VillageManager.get_level(VillageManager.HOUSE) > 0
	var mine_built := VillageManager.get_level(VillageManager.MINE) > 0
	_cart.visible = mine_built
	_miner.visible = mine_built
	_smith.visible = VillageManager.get_level(VillageManager.BLACKSMITH) > 0
	_jozino.home = Vector3(1.2, 0, 2.6) if house_ready else Vector3(-1.6, 0, 2.4)
	if _panel.visible and not _selected_id.is_empty():
		_fill_panel(_selected_id)


## Obdĺžniky (x, z) pod budovami a vozíkom, kam sa nedávajú dekorácie.
func _occupied_areas() -> Array[Rect2]:
	var areas: Array[Rect2] = []
	for building in _buildings:
		var center := building.global_position + building.pick_offset
		var half := Vector2(building.pick_size.x, building.pick_size.z) * 0.5
		areas.append(Rect2(Vector2(center.x, center.z) - half, half * 2.0))
	areas.append(Rect2(_cart.global_position.x - 1.5, _cart.global_position.z - 1.5, 3, 3))
	return areas


# --- Ovládanie ----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touches.is_empty():
				_drag_distance = 0.0
			else:
				# Druhý prst = priblíženie, nie ťuknutie.
				_drag_distance = INF
			_touches[touch.index] = touch.position
		else:
			_touches.erase(touch.index)
			if _touches.is_empty() and _drag_distance < TAP_SLOP and not touch.canceled:
				_pending_tap = touch.position
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var previous: Vector2 = _touches.get(drag.index, drag.position)
		_touches[drag.index] = drag.position
		if _touches.size() == 1:
			_drag(drag.relative)
		elif _touches.size() >= 2:
			var other := _other_touch(drag.index)
			var before := previous.distance_to(other)
			var after := drag.position.distance_to(other)
			if after > 1.0 and before > 1.0:
				_camera.zoom_by(before / after)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		match button.button_index:
			MOUSE_BUTTON_LEFT:
				_mouse_down = button.pressed
				if button.pressed:
					_drag_distance = 0.0
				elif _drag_distance < TAP_SLOP:
					_pending_tap = button.position
			MOUSE_BUTTON_WHEEL_UP:
				_camera.zoom_by(1.0 / WHEEL_ZOOM)
			MOUSE_BUTTON_WHEEL_DOWN:
				_camera.zoom_by(WHEEL_ZOOM)
	elif event is InputEventMouseMotion and _mouse_down:
		_drag((event as InputEventMouseMotion).relative)


func _drag(relative: Vector2) -> void:
	_drag_distance += relative.length()
	if _drag_distance >= TAP_SLOP:
		_camera.pan_pixels(relative)


func _other_touch(index: int) -> Vector2:
	for key: int in _touches:
		if key != index:
			return _touches[key]
	return Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if _pending_tap == Vector2.INF:
		return
	var screen := _pending_tap
	_pending_tap = Vector2.INF
	var from := _camera.project_ray_origin(screen)
	var query := PhysicsRayQueryParameters3D.create(from, from + _camera.project_ray_normal(screen) * 200.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var picked: String = (hit.collider as Node).get_meta(&"pick", "")
	if picked == "cart":
		_claim_cart()
	elif not picked.is_empty():
		_select(picked)


# --- Budovy a panel ------------------------------------------------------------

func _select(building_id: String) -> void:
	Audio.play(&"switch")
	if building_id == "shop":
		GameState.change_scene(GameState.SCENE_SHOP)
		return
	for building in _buildings:
		if building.building_id == building_id:
			_camera.move_focus_to(building.global_position + Vector3(0, 0, 1.5))
	_selected_id = building_id
	_fill_panel(building_id)
	_panel.show()
	var box := %PanelBox as Control
	box.pivot_offset = box.size * 0.5
	box.scale = Vector2(0.85, 0.85)
	create_tween().tween_property(box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _claim_cart() -> void:
	var screen := _camera.unproject_position(_cart.get_effect_point())
	var coins := VillageManager.claim_mine()
	if coins > 0:
		Audio.play(&"gold")
		Effects.burst(_ui, screen, Color("ffcc33"), mini(10 + coins / 4, 40), 360.0, 0.9, 500.0)
		Effects.floating_text(_ui, screen + Vector2(0, -40), "+%d mincí" % coins, Color("ffe14d"), 36)
	else:
		Audio.play(&"bump")
		Effects.floating_text(_ui, screen, "Vozík je prázdny", Color.WHITE, 26)


## Panel budovy (GDD kap. 5.4): názov, úroveň, súčasný a ďalší efekt, cena, tlačidlo.
func _fill_panel(building_id: String) -> void:
	var definition := VillageManager.get_definition(building_id)
	var level := VillageManager.get_level(building_id)
	%PanelTitle.text = definition.display_name
	%PanelLevel.text = "Úroveň %d / %d" % [level, definition.max_level]
	%CurrentEffect.text = "Teraz: " + (definition.effect_descriptions[level - 1] if level > 0 else "nič")
	var cost := VillageManager.get_upgrade_cost(building_id)
	var buy := %BuyButton as Button
	var missing_label := %Missing as Label
	if not VillageManager.is_available(building_id):
		%NextEffect.text = "Ďalej: " + definition.effect_descriptions[0]
		%Cost.hide()
		missing_label.text = "Najprv oprav Jožinov dom."
		missing_label.show()
		buy.hide()
		return
	if cost.is_empty():
		%NextEffect.text = "Budova má najvyššiu úroveň."
		%Cost.hide()
		missing_label.hide()
		buy.hide()
		return
	%NextEffect.text = "Ďalej: " + definition.effect_descriptions[level]
	%Cost.show()
	%CostCoins.text = str(cost.coins)
	%CostGold.text = str(cost.gold)
	%GoldIcon.visible = cost.gold > 0
	%CostGold.visible = cost.gold > 0
	buy.show()
	if level == 0:
		buy.text = "Opraviť" if building_id == VillageManager.HOUSE else "Postaviť"
	else:
		buy.text = "Vylepšiť"
	if cost.coins == 0 and cost.gold == 0:
		%Cost.hide()
	var missing := VillageManager.get_missing(building_id)
	buy.disabled = not VillageManager.can_upgrade(building_id)
	var parts: Array[String] = []
	if missing.coins > 0:
		parts.append("%d mincí" % missing.coins)
	if missing.gold > 0:
		parts.append("%d zlata" % missing.gold)
	missing_label.visible = not parts.is_empty()
	missing_label.text = "Chýba " + " a ".join(parts)


func _on_buy() -> void:
	if VillageManager.upgrade(_selected_id):
		Audio.play(&"powerup")
		_panel.hide()
	else:
		Audio.play(&"hurt")


func _on_building_upgraded(building_id: String, _level: int) -> void:
	for building in _buildings:
		if building.building_id == building_id:
			building.celebrate()
	_refresh_all()
