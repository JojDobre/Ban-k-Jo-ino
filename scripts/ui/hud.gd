class_name Hud
extends CanvasLayer
## Herné UI: mince, srdcia, hviezdy, pauza a výsledky (GDD kap. 2.2).
## Iba zobrazuje stav pokusu; nič nepočíta.

signal restart_requested

var _run: LevelRun

@onready var _coins_label: Label = %CoinsLabel
@onready var _hearts_label: Label = %HeartsLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _overlay: Control = %Overlay
@onready var _title_label: Label = %TitleLabel
@onready var _info_label: Label = %InfoLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _touch_controls: TouchControls = %TouchControls


func _ready() -> void:
	_overlay.hide()
	%PauseButton.pressed.connect(_toggle_pause)
	_continue_button.pressed.connect(_toggle_pause)
	%RestartButton.pressed.connect(func() -> void: restart_requested.emit())


func _unhandled_input(event: InputEvent) -> void:
	# Počas výsledkov sa pauza nedá prepnúť.
	if event.is_action_pressed("pause") and (_continue_button.visible or not _overlay.visible):
		_toggle_pause()


func bind(run: LevelRun, level: LevelDefinition) -> void:
	_run = run
	run.changed.connect(_refresh)
	%LevelLabel.text = level.display_name
	_refresh()


func show_results(result: Dictionary) -> void:
	_touch_controls.release_all()
	_title_label.text = "Level dokončený!" if result.success else "Skús to znova"
	var lines: Array[String] = ["Mince: +%d" % result.coins]
	if result.gold > 0:
		lines.append("Zlato: +%d" % result.gold)
	if result.new_stars > 0:
		lines.append("Nové hviezdy: %d" % result.new_stars)
	if not result.success:
		lines.append("(Pri neúspechu ostáva polovica mincí.)")
	lines.append("Spolu: %d mincí, %d zlata" % [GameState.progress.coins, GameState.progress.gold])
	_info_label.text = "\n".join(lines)
	_continue_button.hide()
	%PauseButton.hide()
	_overlay.show()


func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_touch_controls.release_all()
	_title_label.text = "Pauza"
	_info_label.text = ""
	_continue_button.show()
	_overlay.visible = paused


func _refresh() -> void:
	_coins_label.text = "Mince: %d" % _run.coins
	_hearts_label.text = "Srdcia: %d / %d" % [_run.hearts, _run.max_hearts]
	_stars_label.text = "Hviezdy: %d / %d" % [_run.stars.size(), ProgressionManager.STARS_PER_LEVEL]
