extends Control
## Dedina (GDD kap. 5): budovy v bočnom pohľade, panel vylepšenia, vozík bane s produkciou.
## Logiku rieši VillageManager; táto obrazovka iba zobrazuje a posiela požiadavky.

const GROUND_HEIGHT := 128.0
const PILE := preload("res://assets/village/gold_pile.svg")

var _selected_id := ""

@onready var _spots: Array[BuildingSpot] = [%House, %Mine, %Blacksmith, %Shop]
@onready var _panel: Control = %Panel
@onready var _cart: Control = %Cart
@onready var _pile: TextureRect = %Pile
@onready var _cart_label: Label = %CartLabel
@onready var _miner: AnimatedSprite2D = %Miner
@onready var _smith: AnimatedSprite2D = %Smith


func _ready() -> void:
	Music.play(&"calm")
	%BackButton.pressed.connect(GameState.go_back)
	%MapButton.pressed.connect(GameState.change_scene.bind(GameState.SCENE_WORLD_MAP))
	%CloseButton.pressed.connect(_panel.hide)
	%BuyButton.pressed.connect(_on_buy)
	_cart.gui_input.connect(_on_cart_input)
	for spot in _spots:
		spot.selected.connect(_on_spot_selected)
	VillageManager.building_upgraded.connect(_on_building_upgraded)
	EconomyManager.currency_changed.connect(func(_c: int, _g: int) -> void: _refresh_all())
	_miner.sprite_frames = load("res://assets/player/old/frames.tres")
	_smith.sprite_frames = load("res://assets/player/red_shirt/frames.tres")
	_panel.hide()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh_all()
	_wander(_miner)
	_wander(_smith)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _panel.visible:
			_panel.hide()
		else:
			GameState.go_back()


func _process(_delta: float) -> void:
	# Vozík sa plní priebežne.
	if VillageManager.get_level(VillageManager.MINE) > 0:
		_refresh_cart()


func _layout() -> void:
	var view := get_viewport_rect().size
	var ground_line := view.y - GROUND_HEIGHT + 16.0
	var spot_width := 340.0
	var cart_width := 150.0
	var total := spot_width * _spots.size() + cart_width
	var scale_factor := minf(1.0, (view.x - 40.0) / total)
	var gap := (view.x - total * scale_factor) / (_spots.size() + 2)
	var x := gap
	for spot in _spots:
		spot.scale = Vector2.ONE * scale_factor
		spot.position = Vector2(x, ground_line - 310.0 * scale_factor)
		x += spot_width * scale_factor + gap
		if spot == %Mine:
			# Vozík stojí hneď vedľa bane.
			_cart.scale = Vector2.ONE * scale_factor
			_cart.position = Vector2(x - gap * 0.6, ground_line - 110.0 * scale_factor)
			x += cart_width * scale_factor + gap * 0.4
	_miner.position = Vector2(%Mine.position.x + 250.0 * scale_factor, ground_line - 51.0 * 0.75)
	_smith.position = Vector2(%Blacksmith.position.x + 60.0 * scale_factor, ground_line - 51.0 * 0.75)
	for npc: Node2D in [_miner, _smith]:
		npc.set_meta(&"home_x", npc.position.x)


func _refresh_all() -> void:
	for spot in _spots:
		spot.refresh()
	var mine_built := VillageManager.get_level(VillageManager.MINE) > 0
	_cart.visible = mine_built
	_miner.visible = mine_built
	_smith.visible = VillageManager.get_level(VillageManager.BLACKSMITH) > 0
	if _panel.visible and not _selected_id.is_empty():
		_fill_panel(_selected_id)


func _refresh_cart() -> void:
	var fill := VillageManager.get_mine_fill()
	_pile.visible = fill > 0.01
	_pile.scale = Vector2(lerpf(0.4, 1.0, fill), lerpf(0.3, 1.0, fill))
	var pending := VillageManager.get_pending_mine_coins()
	_cart_label.text = "+%d" % pending if pending > 0 else "%d/h" % VillageManager.get_mine_rate()


func _on_cart_input(event: InputEvent) -> void:
	var released: bool = (event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and not event.pressed)
	if not released:
		return
	var coins := VillageManager.claim_mine()
	if coins > 0:
		Audio.play(&"gold")
		var from := _cart.global_position + Vector2(75, 20) * _cart.scale
		Effects.burst(self, from, Color("ffcc33"), mini(10 + coins / 4, 40), 360.0, 0.9, 500.0)
		Effects.floating_text(self, from + Vector2(0, -40), "+%d mincí" % coins, Color("ffe14d"), 36)
	else:
		Audio.play(&"bump")
		Effects.floating_text(self, _cart.global_position + Vector2(75, -10) * _cart.scale, "Vozík je prázdny", Color.WHITE, 26)


func _on_spot_selected(building_id: String) -> void:
	if building_id == "shop":
		GameState.change_scene(GameState.SCENE_SHOP)
		return
	_selected_id = building_id
	_fill_panel(building_id)
	_panel.show()
	var box := %PanelBox as Control
	box.pivot_offset = box.size * 0.5
	box.scale = Vector2(0.85, 0.85)
	create_tween().tween_property(box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


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
	else:
		Audio.play(&"hurt")


func _on_building_upgraded(building_id: String, _level: int) -> void:
	for spot in _spots:
		if spot.building_id == building_id:
			spot.celebrate()
	_refresh_all()


## Obyvatelia sa pomaly prechádzajú okolo svojej budovy.
func _wander(npc: AnimatedSprite2D) -> void:
	npc.play(&"idle")
	while is_inside_tree():
		await get_tree().create_timer(randf_range(1.5, 3.5)).timeout
		if not is_inside_tree():
			return
		var home: float = npc.get_meta(&"home_x", npc.position.x)
		var target := home + randf_range(-70.0, 70.0)
		npc.flip_h = target < npc.position.x
		npc.play(&"run")
		npc.speed_scale = 0.5
		var tween := create_tween()
		tween.tween_property(npc, "position:x", target, absf(target - npc.position.x) / 60.0)
		await tween.finished
		npc.speed_scale = 1.0
		npc.play(&"idle")
