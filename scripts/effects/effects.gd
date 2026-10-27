class_name Effects
extends RefCounted
## Krátke vizuálne efekty: obláčik, iskry, plávajúci text, úlomky.
## Pridávajú sa do aktuálneho levelu (skupina „level“), nie pod objekt, ktorý sa práve ruší.
## Obrazovky bez levelu (3D dedina) môžu určiť vrstvu efektov skupinou „effects“.

static var _soft_circle: GradientTexture2D


## Výbuch čiastočiek, napr. obláčik pri porazení nepriateľa alebo iskry pri zbere.
static func burst(context: Node, pos: Vector2, color: Color, amount: int = 12, speed: float = 220.0, size: float = 1.0, gravity: float = 400.0) -> void:
	var particles := CPUParticles2D.new()
	particles.texture = _circle()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = 0.5
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.gravity = Vector2(0, gravity)
	particles.scale_amount_min = 0.35 * size
	particles.scale_amount_max = 0.8 * size
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([color, Color(color, 0.0)])
	particles.color_ramp = ramp
	particles.z_index = 20
	_container(context).add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


static func poof(context: Node, pos: Vector2) -> void:
	burst(context, pos, Color(1, 1, 1, 0.9), 14, 160.0, 1.6, -60.0)


static func sparkle(context: Node, pos: Vector2, color: Color = Color("ffe14d")) -> void:
	burst(context, pos, color, 10, 260.0, 0.6, 200.0)


## Text, ktorý vyletí nahor a zmizne („+1“, „Tajomstvo!“).
static func floating_text(context: Node, pos: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 30) -> void:
	var holder := Node2D.new()
	holder.z_index = 30
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.08))
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(300, 50)
	label.position = Vector2(-150, -25)
	holder.add_child(label)
	_container(context).add_child(holder)
	holder.global_position = pos
	var tween := holder.create_tween()
	tween.tween_property(holder, "position:y", holder.position.y - 70, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(holder, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tween.tween_callback(holder.queue_free)


## Rozbitie bloku na štyri kúsky, ktoré odletia a padnú.
static func debris(context: Node, pos: Vector2, texture: Texture2D) -> void:
	var container := _container(context)
	var half := texture.get_size() * 0.5
	for i in 4:
		var piece := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2(i % 2, i / 2) * half, half)
		piece.texture = atlas
		piece.z_index = 20
		container.add_child(piece)
		var side := -1.0 if i % 2 == 0 else 1.0
		piece.global_position = pos + Vector2(side * half.x * 0.5, (i / 2 - 0.5) * half.y)
		var target := piece.position + Vector2(side * randf_range(60, 130), randf_range(220, 320))
		var tween := piece.create_tween()
		tween.tween_property(piece, "position:x", target.x, 0.7)
		tween.parallel().tween_property(piece, "position:y", piece.position.y - randf_range(60, 120), 0.25).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(piece, "position:y", target.y, 0.45).set_delay(0.25).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(piece, "rotation", side * randf_range(3.0, 6.0), 0.7)
		tween.parallel().tween_property(piece, "modulate:a", 0.0, 0.2).set_delay(0.5)
		tween.tween_callback(piece.queue_free)


static func _container(context: Node) -> Node:
	var tree := context.get_tree()
	var level := tree.get_first_node_in_group("level")
	if level == null:
		level = tree.get_first_node_in_group("effects")
	return level if level != null else tree.current_scene


static func _circle() -> Texture2D:
	if _soft_circle == null:
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
		_soft_circle = GradientTexture2D.new()
		_soft_circle.gradient = gradient
		_soft_circle.fill = GradientTexture2D.FILL_RADIAL
		_soft_circle.fill_from = Vector2(0.5, 0.5)
		_soft_circle.fill_to = Vector2(1.0, 0.5)
		_soft_circle.width = 32
		_soft_circle.height = 32
	return _soft_circle
