class_name Hud
extends CanvasLayer
## Herné UI: mince, srdcia, hviezdy, pauza a výsledky (GDD kap. 2.2).
## Iba zobrazuje stav pokusu; nič nepočíta.

signal restart_requested
signal map_requested

const HEART_FULL := preload("res://assets/ui/hud_heart.png")
const HEART_EMPTY := preload("res://assets/ui/hud_heart_empty.png")
const STAR := preload("res://assets/items/star.png")
const ICON_SIZE := Vector2(56, 56)
const POWERUP_ICONS := {
	Player.POWERUP_SHIELD: preload("res://assets/items/gem_blue.png"),
	Player.POWERUP_SPEED: preload("res://assets/items/gem_green.png"),
	Player.POWERUP_MAGNET: preload("res://assets/items/gem_red.png"),
}

var _run: LevelRun
var _player: Player
var _secrets_total := 0
var _level_name := ""
var _shown_coins := -1

@onready var _coins_label: Label = %CoinsLabel
@onready var _hearts: HBoxContainer = %Hearts
@onready var _stars: HBoxContainer = %Stars
@onready var _overlay: Control = %Overlay
@onready var _title_label: Label = %TitleLabel
@onready var _info_label: Label = %InfoLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _touch_controls: TouchControls = %TouchControls
@onready var _powerups: HBoxContainer = %Powerups
@onready var _key_icon: TextureRect = %KeyIcon


func _ready() -> void:
	_overlay.hide()

	%PauseButton.pressed.connect(_toggle_pause)
	_continue_button.pressed.connect(_toggle_pause)
	%RestartButton.pressed.connect(func() -> void: restart_requested.emit())
	%MapButton.pressed.connect(func() -> void: map_requested.emit())


func _notification(what: int) -> void:
	# Androidové tlačidlo Späť: pauza / pokračovanie.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and (_continue_button.visible or not _overlay.visible):
		_toggle_pause()


func _unhandled_input(event: InputEvent) -> void:
	# Počas výsledkov sa pauza nedá prepnúť.
	if event.is_action_pressed("pause") and (_continue_button.visible or not _overlay.visible):
		_toggle_pause()


func bind(run: LevelRun, level: LevelDefinition, player: Player, secrets_total: int) -> void:
	_run = run
	_player = player
	_secrets_total = secrets_total
	run.changed.connect(_refresh)
	player.powerups_changed.connect(_on_powerups_changed)
	_level_name = level.display_name
	_build_icons(_hearts, run.max_hearts, HEART_FULL)
	_build_icons(_stars, ProgressionManager.STARS_PER_LEVEL, STAR)
	_refresh()


func show_results(result: Dictionary) -> void:
	_touch_controls.release_all()
	_title_label.text = "Level dokončený!" if result.success else "Skús to znova"
	var lines: Array[String] = ["Mince: +%d" % result.coins]
	if result.gold > 0:
		lines.append("Zlato: +%d" % result.gold)
	if result.new_stars > 0:
		lines.append("Nové hviezdy: %d" % result.new_stars)
	if _secrets_total > 0:
		lines.append("Tajné miesta: %d / %d" % [_run.secrets_found, _secrets_total])
	if not result.success:
		lines.append("(Pri neúspechu ostáva polovica mincí.)")
	lines.append("Spolu: %d mincí, %d zlata" % [GameState.progress.coins, GameState.progress.gold])
	_info_label.text = "\n".join(lines)
	_continue_button.hide()
	%MapButton.text = "Pokračovať" if result.success else "Mapa sveta"
	%PauseButton.hide()
	_overlay.show()


func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_touch_controls.release_all()
	_title_label.text = "Pauza – %s" % _level_name
	_info_label.text = ""
	%MapButton.text = "Mapa sveta"
	_continue_button.show()
	_overlay.visible = paused


func _process(_delta: float) -> void:
	if _player == null or _powerups.get_child_count() == 0:
		return
	# Odpočet zostávajúceho času vylepšení.
	var remaining := _player.get_powerups()
	for icon in _powerups.get_children():
		var label := icon.get_child(0) as Label
		var time: float = remaining.get(StringName(icon.name), 0.0)
		label.text = "" if is_inf(time) else str(ceili(time))
		icon.modulate.a = 0.5 + 0.5 * absf(sin(Time.get_ticks_msec() * 0.01)) if time < 2.5 and not is_inf(time) else 1.0


func _on_powerups_changed(powerups: Dictionary) -> void:
	for child in _powerups.get_children():
		_powerups.remove_child(child)
		child.queue_free()
	for powerup: StringName in powerups:
		var icon := TextureRect.new()
		icon.name = powerup
		icon.texture = POWERUP_ICONS[powerup]
		icon.custom_minimum_size = ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_constant_override("outline_size", 6)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.position = Vector2(34, 30)
		icon.add_child(label)
		_powerups.add_child(icon)
		_pop(icon)


func _refresh() -> void:
	if _run.keys > 0 and not _key_icon.visible:
		_key_icon.visible = true
		_pop(_key_icon)
	if _run.coins != _shown_coins:
		if _shown_coins >= 0:
			_pop(_coins_label)
		_shown_coins = _run.coins
	_coins_label.text = str(_run.coins)
	for i in _hearts.get_child_count():
		var heart := _hearts.get_child(i) as TextureRect
		var texture := HEART_FULL if i < _run.hearts else HEART_EMPTY
		if heart.texture != texture:
			heart.texture = texture
			_pop(heart)
	for i in _stars.get_child_count():
		var star := _stars.get_child(i) as TextureRect
		var found := i < _run.stars.size()
		var target := Color.WHITE if found else Color(0, 0, 0, 0.35)
		if star.modulate != target:
			star.modulate = target
			if found:
				_pop(star)


func _build_icons(container: HBoxContainer, count: int, texture: Texture2D) -> void:
	for child in container.get_children():
		child.queue_free()
	for i in count:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(icon)


## Krátke „poskočenie“ ikony pri zmene.
func _pop(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(1.35, 1.35), 0.08)
	tween.tween_property(control, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
