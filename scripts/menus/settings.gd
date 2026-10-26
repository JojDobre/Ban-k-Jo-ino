extends Control
## Nastavenia: hlasitosť hudby a zvukov, vymazanie postupu.
## Hodnoty sa ukladajú v PlayerProgress.settings.

@onready var _music: HSlider = %MusicSlider
@onready var _sfx: HSlider = %SfxSlider
@onready var _confirm: Control = %Confirm


func _ready() -> void:
	var settings := GameState.progress.settings
	_music.value = float(settings.get("music_volume", 0.8))
	_sfx.value = float(settings.get("sfx_volume", 1.0))
	_music.value_changed.connect(_on_music_changed)
	_sfx.value_changed.connect(_on_sfx_changed)
	_sfx.drag_ended.connect(func(_changed: bool) -> void: Audio.play(&"coin"))
	%BackButton.pressed.connect(GameState.go_back)
	%ResetButton.pressed.connect(_confirm.show)
	%ConfirmNo.pressed.connect(_confirm.hide)
	%ConfirmYes.pressed.connect(_reset_progress)
	%FastMine.visible = OS.is_debug_build()
	%FastMine.button_pressed = GameState.debug_time_scale > 1.0
	%FastMine.toggled.connect(func(on: bool) -> void: GameState.debug_time_scale = 60.0 if on else 1.0)
	_confirm.hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _confirm.visible:
			_confirm.hide()
		else:
			GameState.go_back()


func _on_music_changed(value: float) -> void:
	GameState.progress.settings["music_volume"] = value
	Music.refresh_volume()
	SaveManager.request_save()


func _on_sfx_changed(value: float) -> void:
	GameState.progress.settings["sfx_volume"] = value
	SaveManager.request_save()


func _reset_progress() -> void:
	SaveManager.delete_save()
	GameState.set_progress(SaveManager.load_progress())
	SaveManager.save_now()
	GameState.previous_scene = ""
	GameState.change_scene(GameState.SCENE_MAIN_MENU)
