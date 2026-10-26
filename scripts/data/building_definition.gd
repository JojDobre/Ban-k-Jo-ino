class_name BuildingDefinition
extends Resource
## Definícia budovy a jej úrovní (GDD kap. 7.3). Index poľa = cieľová úroveň - 1.

@export var id: String
@export var display_name: String
@export var max_level: int = 1
@export var coin_costs: Array[int] = []
@export var gold_costs: Array[int] = []
@export var production_per_hour: Array[int] = []
@export var effect_descriptions: Array[String] = []
@export var visual_variants: Array[Texture2D] = []


## Cena za postup z current_level na current_level + 1.
func get_upgrade_cost(current_level: int) -> Dictionary:
	if current_level >= max_level or current_level >= coin_costs.size():
		return {}
	return {"coins": coin_costs[current_level], "gold": gold_costs[current_level] if current_level < gold_costs.size() else 0}


func get_production(level: int) -> int:
	if level <= 0 or level > production_per_hour.size():
		return 0
	return production_per_hour[level - 1]
