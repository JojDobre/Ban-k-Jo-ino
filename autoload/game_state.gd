extends Node
## Vlastní jediný PlayerProgress a aktuálny LevelRun (GDD kap. 8.1).
## Ostatné systémy stav menia cez svoje funkcie, UI sa pripája na signály.

## Vyslaný, keď sa celý progres nahradí (načítanie uloženia, nová hra).
signal progress_replaced

const BLACKSMITH_ID := "blacksmith"
const BASE_HEARTS := 3
const MAGNET_RADIUS := 110.0

var progress: PlayerProgress = PlayerProgress.new()
var current_run: LevelRun

## Ladiaci násobič času pre baňu (GDD kap. 5.3): 60 = 1 herná hodina za 1 minútu.
## V release zostavení sa vždy použije 1.
var debug_time_scale: float = 1.0


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
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(path)
