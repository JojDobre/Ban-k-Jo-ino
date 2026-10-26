class_name BumpBlock
extends StaticBody2D
## Blok, do ktorého Jožino buchne hlavou zospodu. Podľa obsahu vypadne minca,
## viac mincí postupne, srdce alebo kryštál; tehla sa rozbije. Skrytý blok je
## neviditeľný a objaví sa až po údere zospodu. Nepriateľ stojaci na bloku je pri údere porazený.

enum Content { COIN, ITEM, BRICK }

@export var content: Content = Content.COIN
## Koľko mincí blok dá (viac úderov).
@export var coin_count: int = 1
## Scéna predmetu, ktorý vyskočí (srdce, kryštál) – pri Content.ITEM.
@export var item_scene: PackedScene
@export var invisible: bool = false
@export var active_texture: Texture2D
@export var empty_texture: Texture2D = preload("res://assets/blocks/block_empty.png")

const BUMP_HEIGHT := 14.0

var _used := false
var _busy := false

@onready var _sprite: Sprite2D = $Sprite
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _top: Area2D = $Top
@onready var _reveal: Area2D = $Reveal


func _ready() -> void:
	if active_texture != null:
		_sprite.texture = active_texture
	if invisible:
		_sprite.visible = false
		_shape.disabled = true
	else:
		_reveal.monitoring = false


func _physics_process(_delta: float) -> void:
	if not invisible:
		set_physics_process(false)
		return
	# Skrytý blok nemá kolíziu – úder zospodu sa zistí cez oblasť Reveal.
	for body in _reveal.get_overlapping_bodies():
		var player := body as Player
		if player != null and player.velocity.y < 0.0 and player.global_position.y > global_position.y + 20.0:
			_reveal_block(player)
			return


## Volá Jožino pri náraze hlavou (pozri Player._bump_ceiling).
func bump(player: Player) -> void:
	if _busy or (_used and content != Content.BRICK):
		_bounce()
		return
	_defeat_enemies_on_top()
	match content:
		Content.BRICK:
			_break()
			return
		Content.COIN:
			_pop_coin()
			coin_count -= 1
			if coin_count <= 0:
				_set_used()
		Content.ITEM:
			_spawn_item()
			_set_used()
	_bounce()
	if player != null:
		player.velocity.y = maxf(player.velocity.y, 0.0)


func _reveal_block(player: Player) -> void:
	invisible = false
	_sprite.visible = true
	_shape.set_deferred("disabled", false)
	_reveal.set_deferred("monitoring", false)
	player.velocity.y = 0.0
	player.global_position.y = global_position.y + 32.0 + Player.BODY_SIZE.y * 0.5 + 1.0
	Effects.sparkle(self, global_position, Color.WHITE)
	bump(player)


func _bounce() -> void:
	_busy = true
	Audio.play(&"bump", 0.05)
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", -BUMP_HEIGHT, 0.07).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "position:y", 0.0, 0.12).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func() -> void: _busy = false)


func _set_used() -> void:
	_used = true
	_sprite.texture = empty_texture


func _pop_coin() -> void:
	var run := GameState.current_run
	if run != null:
		run.add_coins(1)
	Audio.play(&"coin", 0.08)
	var coin := Sprite2D.new()
	coin.texture = preload("res://assets/items/coin_gold.png")
	coin.z_index = 10
	add_child(coin)
	coin.position = Vector2(0, -40)
	var tween := coin.create_tween()
	tween.tween_property(coin, "position:y", -130.0, 0.25).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(coin, "scale:x", 0.1, 0.12).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_property(coin, "scale:x", 1.0, 0.12)
	tween.tween_property(coin, "position:y", -90.0, 0.15).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		Effects.sparkle(self, coin.global_position)
		coin.queue_free())


func _spawn_item() -> void:
	if item_scene == null:
		return
	var item := item_scene.instantiate() as Node2D
	Effects.sparkle(self, global_position + Vector2(0, -32), Color.WHITE)
	get_parent().add_child(item)
	item.global_position = global_position
	if item.has_method(&"rise_from_block"):
		item.call(&"rise_from_block")


func _break() -> void:
	_busy = true
	Audio.play(&"break")
	Effects.debris(self, global_position, _sprite.texture)
	Effects.burst(self, global_position, Color(0.85, 0.6, 0.45), 10, 180.0, 0.7, 500.0)
	queue_free()


func _defeat_enemies_on_top() -> void:
	for body in _top.get_overlapping_bodies():
		if body is Enemy:
			(body as Enemy).defeat()
