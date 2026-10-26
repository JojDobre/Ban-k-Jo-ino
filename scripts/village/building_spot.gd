class_name BuildingSpot
extends Control
## Budova v dedine: kresba podľa úrovne, štítok s názvom a úrovňou, dotykom sa otvorí panel.
## Zamknutá budova (dom ešte nie je opravený) je stmavená so zámkom.

signal selected(building_id: String)

const LOCK := preload("res://assets/icons/locked.png")

## id budovy z VillageManager (house, mine, blacksmith) alebo „shop“.
@export var building_id: String = "house"
## Kresby podľa úrovne (index = úroveň).
@export var textures: Array[Texture2D] = []

@onready var _sprite: TextureRect = $Sprite
@onready var _name_label: Label = $Plate/VBox/Name
@onready var _level_label: Label = $Plate/VBox/Level
@onready var _lock: TextureRect = $Lock
@onready var _upgrade_hint: Control = $UpgradeHint

var _time := randf() * TAU


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	refresh()


func _process(delta: float) -> void:
	_time += delta
	# Šípka „dá sa vylepšiť“ poskakuje.
	_upgrade_hint.position.y = -10.0 + sin(_time * 4.0) * 6.0


func refresh() -> void:
	var level := 0 if building_id == "shop" else VillageManager.get_level(building_id)
	var texture: Texture2D = textures[clampi(level, 0, textures.size() - 1)] if not textures.is_empty() else null
	_sprite.texture = texture
	var available := building_id == "shop" or VillageManager.is_available(building_id)
	_lock.visible = not available
	_sprite.modulate = Color.WHITE if available else Color(0.55, 0.55, 0.6)
	if building_id == "shop":
		_name_label.text = "Obchod"
		_level_label.text = "Obleky a predmety"
	else:
		var definition := VillageManager.get_definition(building_id)
		_name_label.text = definition.display_name
		if level == 0:
			_level_label.text = "Zatiaľ nepostavené" if building_id != VillageManager.HOUSE else "Treba opraviť"
		else:
			_level_label.text = "Úroveň %d / %d" % [level, definition.max_level]
	_upgrade_hint.visible = building_id != "shop" and VillageManager.can_upgrade(building_id)


func _gui_input(event: InputEvent) -> void:
	var released: bool = (event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and not event.pressed)
	if released:
		Audio.play(&"bump")
		pivot_offset = Vector2(size.x * 0.5, size.y)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.06, 0.94), 0.06)
		tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
		selected.emit(building_id)
		accept_event()


## Krátka oslava po vylepšení.
func celebrate() -> void:
	refresh()
	pivot_offset = Vector2(size.x * 0.5, size.y)
	scale = Vector2(1.15, 0.85)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC)
	Effects.burst(self, global_position + Vector2(size.x * 0.5, size.y * 0.4), Color("ffe14d"), 30, 380.0, 1.0, 400.0)
	Effects.poof(self, global_position + Vector2(size.x * 0.5, size.y * 0.8))
