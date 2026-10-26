extends Node
## Načíta uložený progres a otvorí prvú obrazovku (GDD kap. 9).

## Kým neexistuje hlavné menu a mapa sveta, hra štartuje priamo v leveli.
const FIRST_SCENE := "res://scenes/levels/level_01.tscn"


func _ready() -> void:
	GameState.set_progress(SaveManager.load_progress())
	GameState.change_scene(FIRST_SCENE)
