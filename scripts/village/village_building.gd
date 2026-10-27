class_name VillageBuilding
extends Node3D
## Budova v 3D dedine: model podľa úrovne, štítok s názvom, šípka „dá sa vylepšiť“,
## zámok (dom ešte nie je opravený) a oslava po vylepšení. Ťuknutie rieši Village
## cez lúč na StaticBody3D s metadátom „pick“.

const FONT := preload("res://assets/fonts/Baloo2.ttf")
const ARROW := preload("res://assets/icons/arrowUp.png")
const LOCK := preload("res://assets/icons/locked.png")

## id budovy z VillageManager (house, mine, blacksmith) alebo „shop“.
@export var building_id: String = "house"
## Oblasť na ťuknutie (rozmery a posun stredu).
@export var pick_size: Vector3 = Vector3(4, 4, 4)
@export var pick_offset: Vector3 = Vector3.ZERO
## Výška štítku nad zemou.
@export var plate_height: float = 6.0

var _model: Node3D
var _plate: Label3D
var _hint: Sprite3D
var _lock: Sprite3D
var _shown_level := -1
var _time := randf() * TAU


func _ready() -> void:
	var body := StaticBody3D.new()
	body.set_meta(&"pick", building_id)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = pick_size
	shape.shape = box
	shape.position = pick_offset + Vector3(0, pick_size.y * 0.5, 0)
	body.add_child(shape)
	add_child(body)

	_plate = Label3D.new()
	_plate.font = FONT
	_plate.font_size = 56
	_plate.outline_size = 14
	_plate.modulate = Color.WHITE
	_plate.outline_modulate = Color(0.25, 0.15, 0.08)
	# Štítok má na obrazovke stále rovnakú veľkosť bez ohľadu na priblíženie.
	_plate.fixed_size = true
	_plate.pixel_size = 0.0006
	_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_plate.no_depth_test = true
	_plate.line_spacing = -18.0
	_plate.position.y = plate_height
	add_child(_plate)

	_hint = _icon_sprite(ARROW, Color("5fd35f"))
	_lock = _icon_sprite(LOCK, Color.WHITE)
	refresh()


func _process(delta: float) -> void:
	_time += delta
	# Šípka „dá sa vylepšiť“ poskakuje nad štítkom.
	_hint.position.y = plate_height + 1.6 + sin(_time * 4.0) * 0.18


func refresh() -> void:
	var is_shop := building_id == "shop"
	var level := 0 if is_shop else VillageManager.get_level(building_id)
	if level != _shown_level:
		_shown_level = level
		if _model != null:
			_model.queue_free()
		_model = VillageModels.build(building_id, level)
		add_child(_model)
	var available := is_shop or VillageManager.is_available(building_id)
	_lock.visible = not available
	_lock.position.y = plate_height + 1.6
	_hint.visible = not is_shop and VillageManager.can_upgrade(building_id)
	if is_shop:
		_plate.text = "Obchod"
		return
	var definition := VillageManager.get_definition(building_id)
	var status := "Úroveň %d" % level
	if level == 0:
		status = "Treba opraviť" if building_id == VillageManager.HOUSE else "Postaviť"
	_plate.text = "%s\n%s" % [definition.display_name, status]


## Poskočenie modelu a konfety po vylepšení.
func celebrate() -> void:
	refresh()
	_model.scale = Vector3(1.15, 0.75, 1.15)
	var tween := create_tween()
	tween.tween_property(_model, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var confetti := CPUParticles3D.new()
	confetti.one_shot = true
	confetti.explosiveness = 0.9
	confetti.amount = 60
	confetti.lifetime = 1.6
	confetti.direction = Vector3.UP
	confetti.spread = 50.0
	confetti.initial_velocity_min = 5.0
	confetti.initial_velocity_max = 9.0
	confetti.gravity = Vector3(0, -9.0, 0)
	confetti.angular_velocity_min = -360.0
	confetti.angular_velocity_max = 360.0
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.22, 0.14)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	confetti.mesh = mesh
	var colors := Gradient.new()
	colors.colors = PackedColorArray([Color("ff5a5a"), Color("ffd23f"), Color("5fd35f"), Color("4fa3ff"), Color("c77dff")])
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	confetti.color_initial_ramp = colors
	confetti.position.y = plate_height * 0.6
	add_child(confetti)
	confetti.emitting = true
	confetti.finished.connect(confetti.queue_free)


func _icon_sprite(texture: Texture2D, color: Color) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.modulate = color
	sprite.fixed_size = true
	sprite.pixel_size = 0.0009
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.render_priority = 1
	sprite.position.y = plate_height + 1.4
	sprite.visible = false
	add_child(sprite)
	return sprite
