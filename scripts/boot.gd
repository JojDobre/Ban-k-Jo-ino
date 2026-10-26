extends Node
## Načíta uložený progres a otvorí prvú obrazovku (GDD kap. 9).

## Po načítaní uloženia sa otvorí hlavné menu.
const FIRST_SCENE := "res://scenes/menus/main_menu.tscn"


func _ready() -> void:
	GameState.set_progress(SaveManager.load_progress())
	GameState.change_scene(FIRST_SCENE)
