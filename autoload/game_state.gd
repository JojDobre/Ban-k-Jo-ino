extends Node
## Vlastní jediný PlayerProgress a aktuálny LevelRun (GDD kap. 8.1).
## Ostatné systémy stav menia cez svoje funkcie, UI sa pripája na signály.

## Vyslaný, keď sa celý progres nahradí (načítanie uloženia, nová hra).
signal progress_replaced

const BLACKSMITH_ID := "blacksmith"

## Obrazovky hry.
const SCENE_MAIN_MENU := "res://scenes/menus/main_menu.tscn"
const SCENE_WORLD_MAP := "res://scenes/world_map/world_map.tscn"
const SCENE_VILLAGE := "res://scenes/village/village.tscn"
const SCENE_SHOP := "res://scenes/menus/shop.tscn"
const SCENE_SETTINGS := "res://scenes/menus/settings.tscn"
const FADE_TIME := 0.22
const BASE_HEARTS := 3
const MAGNET_RADIUS := 110.0

var progress: PlayerProgress = PlayerProgress.new()
var current_run: LevelRun

## Ladiaci násobič času pre baňu (GDD kap. 5.3): 60 = 1 herná hodina za 1 minútu.
## V release zostavení sa vždy použije 1.
var debug_time_scale: float = 1.0

## Obrazovka, z ktorej hráč prišiel (pre tlačidlo Späť v obchode a nastaveniach).
var previous_scene: String = ""

var _fade: ColorRect
var _changing := false


func _ready() -> void:
	# Prechod medzi obrazovkami: krátke stmavnutie cez celú obrazovku.
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.08, 0.06, 0.12, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func set_progress(new_progress: PlayerProgress) -> void:
	progress = new_progress
	progress_replaced.emit()


func now() -> int:
	return int(Time.get_unix_time_from_system())


func get_time_scale() -> float:
	return debug_time_scale if OS.is_debug_build() else 1.0


## Kováčska dielňa úr. 1: +1 srdce (GDD kap. 5.2).
func get_max_hearts() -> int:
	return BASE_HEARTS + (1 if progress.get_building_level(BLACKSMITH_ID) >= 1 else 0)


## Kováčska dielňa úr. 2: magnet na mince.
func get_magnet_radius() -> float:
	return MAGNET_RADIUS if progress.get_building_level(BLACKSMITH_ID) >= 2 else 0.0


func change_scene(path: String) -> void:
	if _changing:
		return
	_changing = true
	var current := get_tree().current_scene
	if current != null and current.scene_file_path != path:
		previous_scene = current.scene_file_path
	# Počas prechodu sa nedá klikať.
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	_changing = false


## Návrat na predchádzajúcu obrazovku (alebo do hlavného menu).
func go_back() -> void:
	change_scene(previous_scene if not previous_scene.is_empty() else SCENE_MAIN_MENU)
