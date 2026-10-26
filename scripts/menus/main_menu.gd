extends Control
## Hlavné menu: Hrať, Dedina, Obchod, Nastavenia. Jožino stojí na tráve v zvolenom obleku.

@onready var _jozino: AnimatedSprite2D = %Jozino
@onready var _title: Control = %Title
@onready var _play_button: Button = %PlayButton

var _time := 0.0


func _ready() -> void:
	Music.play(&"calm")
	_play_button.text = "Pokračovať" if not GameState.progress.completed_levels.is_empty() else "Hrať"
	_play_button.pressed.connect(GameState.change_scene.bind(GameState.SCENE_WORLD_MAP))
	%VillageButton.pressed.connect(GameState.change_scene.bind(GameState.SCENE_VILLAGE))
	%ShopButton.pressed.connect(GameState.change_scene.bind(GameState.SCENE_SHOP))
	%SettingsButton.pressed.connect(GameState.change_scene.bind(GameState.SCENE_SETTINGS))
	_jozino.sprite_frames = load("res://assets/player/%s/frames.tres" % GameState.progress.outfit)
	_jozino.play(&"idle")
	get_viewport().size_changed.connect(_place_jozino)
	_place_jozino()
	_hop_loop()


func _process(delta: float) -> void:
	_time += delta
	_title.position.y = 40.0 + sin(_time * 1.6) * 8.0
	_title.rotation = sin(_time * 1.1) * 0.02


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()


func _place_jozino() -> void:
	# Chodidlá na tráve (pás zeme má 128 px, vrch trávy ~12 px pod okrajom dlaždice).
	# Pôvod kresby je v strede snímky; chodidlá sú 51 px pod ním (pred zväčšením).
	var feet := 51.0 * _jozino.scale.y
	_jozino.position = Vector2(get_viewport_rect().size.x * 0.22, get_viewport_rect().size.y - 128.0 + 12.0 - feet)


## Jožino občas poskočí, aby menu nebolo strnulé.
func _hop_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(2.5, 4.5)).timeout
		if not is_inside_tree():
			return
		var base := _jozino.position.y
		_jozino.play(&"jump")
		var tween := create_tween()
		tween.tween_property(_jozino, "position:y", base - 90.0, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(_jozino.play.bind(&"fall"))
		tween.tween_property(_jozino, "position:y", base, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(_jozino.play.bind(&"idle"))
		await tween.finished
