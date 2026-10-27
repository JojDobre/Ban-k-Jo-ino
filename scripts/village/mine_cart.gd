class_name MineCart
extends Node3D
## Vozík pred baňou: kopa zlata rastie s produkciou, nad ním bublina s počtom mincí.
## Ťuknutie (metadáta „pick“ = „cart“) vyberie produkciu cez VillageManager.claim_mine().

const COIN := preload("res://assets/ui/hud_coin.png")
const FONT := preload("res://assets/fonts/Baloo2.ttf")
const NUGGETS := 9

var _pile: Node3D
var _bubble: Node3D
var _label: Label3D
var _nuggets: Array[Node3D] = []
var _time := 0.0


func _ready() -> void:
	VillageModels.add(self, "town/cart", Vector3.ZERO, 90.0, 1.7)
	_pile = Node3D.new()
	_pile.position.y = 0.55
	add_child(_pile)
	for i in NUGGETS:
		var angle := i * 2.4
		var radius := 0.12 + 0.05 * (i % 3)
		var pos := Vector3(cos(angle) * radius * 2.2, 0.05 * (i / 3), sin(angle) * radius)
		_nuggets.append(VillageModels.gold_nugget(_pile, pos, 1.6))

	_bubble = Node3D.new()
	add_child(_bubble)
	var coin := Sprite3D.new()
	coin.texture = COIN
	coin.fixed_size = true
	coin.pixel_size = 0.0008
	coin.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	coin.no_depth_test = true
	coin.offset = Vector2(-60, 0)
	_bubble.add_child(coin)
	_label = Label3D.new()
	_label.font = FONT
	_label.font_size = 64
	_label.outline_size = 16
	_label.modulate = Color("ffe14d")
	_label.outline_modulate = Color(0.25, 0.15, 0.08)
	_label.fixed_size = true
	_label.pixel_size = 0.0007
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.offset = Vector2(-20, 0)
	_bubble.add_child(_label)

	var body := StaticBody3D.new()
	body.set_meta(&"pick", "cart")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.8, 2.6, 2.4)
	shape.shape = box
	shape.position.y = 1.0
	body.add_child(shape)
	add_child(body)


func _process(delta: float) -> void:
	_time += delta
	var fill := VillageManager.get_mine_fill()
	var shown := ceili(fill * NUGGETS)
	for i in NUGGETS:
		_nuggets[i].visible = i < shown
	var pending := VillageManager.get_pending_mine_coins()
	_bubble.visible = pending > 0
	_label.text = "+%d" % pending
	# Plný vozík pulzuje výraznejšie.
	var pulse := 0.08 if fill >= 1.0 else 0.03
	_bubble.position.y = 2.1 + sin(_time * 3.0) * 0.12
	_bubble.scale = Vector3.ONE * (1.0 + sin(_time * 6.0) * pulse)


## Bod nad vozíkom pre efekty v obrazovke.
func get_effect_point() -> Vector3:
	return global_position + Vector3(0, 1.5, 0)
