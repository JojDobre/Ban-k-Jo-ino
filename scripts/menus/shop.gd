extends Control
## Obchod: obleky pre Jožina a predmety na začiatok levelu (za herné mince a zlato).
## Logiku nákupu rieši ShopManager; obrazovka iba zobrazuje karty.

const COIN := preload("res://assets/ui/hud_coin.png")
const GOLD := preload("res://assets/items/gem_yellow.png")
const ITEM_ICONS := {
	"start_shield": preload("res://assets/items/gem_blue.png"),
	"start_magnet": preload("res://assets/items/gem_red.png"),
}
## Šírka jednej snímky v pásoch animácií baníka (pozri tools/prepare_assets.py).
const FRAME_WIDTH := 107

var _tab := "outfits"

@onready var _cards: HBoxContainer = %Cards


func _ready() -> void:
	Music.play(&"calm")
	%BackButton.pressed.connect(GameState.go_back)
	%OutfitsTab.pressed.connect(_show_tab.bind("outfits"))
	%ItemsTab.pressed.connect(_show_tab.bind("items"))
	ShopManager.purchased.connect(func(_id: String) -> void: _rebuild())
	ShopManager.outfit_changed.connect(func(_id: String) -> void: _rebuild())
	EconomyManager.currency_changed.connect(func(_c: int, _g: int) -> void: _rebuild())
	_show_tab("outfits")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		GameState.go_back()


func _show_tab(tab: String) -> void:
	_tab = tab
	(%OutfitsTab as Button).button_pressed = tab == "outfits"
	(%ItemsTab as Button).button_pressed = tab == "items"
	%OutfitsTab.modulate = Color.WHITE if tab == "outfits" else Color(1, 1, 1, 0.6)
	%ItemsTab.modulate = Color.WHITE if tab == "items" else Color(1, 1, 1, 0.6)
	%Hint.text = "Kúpený oblek si Jožino hneď oblečie." if tab == "outfits" else "Predmety sa použijú samy na začiatku ďalšieho levelu."
	_rebuild()


func _rebuild() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	if _tab == "outfits":
		for outfit: Dictionary in ShopManager.OUTFITS:
			_cards.add_child(_outfit_card(outfit))
	else:
		for item: Dictionary in ShopManager.ITEMS:
			_cards.add_child(_item_card(item))


func _outfit_card(outfit: Dictionary) -> Control:
	var owned := ShopManager.owns_outfit(outfit.id)
	var equipped: bool = GameState.progress.outfit == outfit.id
	var preview := AtlasTexture.new()
	preview.atlas = load("res://assets/player/%s/jozino_idle.png" % outfit.id)
	preview.region = Rect2(0, 0, FRAME_WIDTH, 104)
	var card := _card(preview, outfit.name, equipped)
	var box := card.get_child(0) as VBoxContainer
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 64)
	if equipped:
		box.add_child(_status("Oblečené"))
		button.text = "Oblečené"
		button.disabled = true
	elif owned:
		box.add_child(_status("Vlastníš"))
		button.text = "Obliecť"
		button.pressed.connect(func() -> void:
			ShopManager.equip_outfit(outfit.id)
			Audio.play(&"switch"))
	else:
		box.add_child(_price(outfit.coins, outfit.gold))
		button.text = "Kúpiť"
		button.disabled = not EconomyManager.can_afford(outfit.coins, outfit.gold)
		button.pressed.connect(_buy.bind(card, func() -> bool: return ShopManager.buy_outfit(outfit.id)))
	box.add_child(button)
	return card


func _item_card(item: Dictionary) -> Control:
	var count := GameState.progress.get_item_count(item.id)
	var card := _card(ITEM_ICONS[item.id], item.name, false)
	var box := card.get_child(0) as VBoxContainer
	var description := Label.new()
	description.text = item.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.custom_minimum_size = Vector2(200, 0)
	description.add_theme_font_size_override("font_size", 20)
	box.add_child(description)
	box.add_child(_status("Máš %d / %d" % [count, item.max]))
	box.add_child(_price(item.coins, item.gold))
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 64)
	button.text = "Kúpiť"
	button.disabled = not ShopManager.can_buy_item(item.id)
	button.pressed.connect(_buy.bind(card, func() -> bool: return ShopManager.buy_item(item.id)))
	box.add_child(button)
	return card


func _card(texture: Texture2D, title: String, highlighted: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = &"Card"
	card.custom_minimum_size = Vector2(220, 0)
	if highlighted:
		card.self_modulate = Color(0.85, 1.0, 0.85)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var image := TextureRect.new()
	image.texture = texture
	image.custom_minimum_size = Vector2(0, 150)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(image)
	var name_label := Label.new()
	name_label.text = title
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 26)
	box.add_child(name_label)
	return card


func _status(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.2, 0.5, 0.2))
	label.add_theme_font_size_override("font_size", 24)
	return label


func _price(coins: int, gold: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for pair: Array in [[COIN, coins], [GOLD, gold]]:
		if pair[1] <= 0 and pair[0] == GOLD:
			continue
		var icon := TextureRect.new()
		icon.texture = pair[0]
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var label := Label.new()
		label.text = str(pair[1])
		label.add_theme_font_size_override("font_size", 26)
		row.add_child(label)
	return row


func _buy(card: Control, action: Callable) -> void:
	var where := card.global_position + card.size * Vector2(0.5, 0.3)
	if action.call():
		Audio.play(&"powerup")
		Effects.burst(self, where, Color("ffe14d"), 24, 320.0, 0.9, 300.0)
	else:
		Audio.play(&"hurt")
