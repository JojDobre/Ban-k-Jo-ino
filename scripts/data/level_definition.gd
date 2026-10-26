class_name LevelDefinition
extends Resource
## Definícia levelu (GDD kap. 7.2). Ukladá sa ako .tres v data/levels/.

@export var id: String
@export var world_id: String = "green_valley"
@export var display_name: String
@export_file("*.tscn") var scene_path: String
@export var order: int = 0
@export var completion_coins: int = 20
@export var first_clear_gold: int = 1
## Levely, ktoré musia byť dokončené pred odomknutím tohto levelu.
@export var unlock_requirements: Array[String] = []
## Poloha uzla na mape sveta (0–1 vzhľadom na veľkosť obrazovky).
@export var map_position: Vector2 = Vector2(0.5, 0.5)
