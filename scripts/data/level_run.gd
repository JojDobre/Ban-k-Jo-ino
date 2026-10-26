class_name LevelRun
extends RefCounted
## Dočasný stav jedného pokusu v leveli (GDD kap. 7.4). Neukladá sa.

signal changed

var level_id: String
var coins: int = 0
var stars: Array[String] = []
var collected_items: Array[String] = []
var max_hearts: int = 3
var hearts: int = 3
var checkpoint: Vector2 = Vector2.ZERO


func _init(p_level_id: String, p_max_hearts: int, start_position: Vector2) -> void:
	level_id = p_level_id
	max_hearts = p_max_hearts
	hearts = p_max_hearts
	checkpoint = start_position


func add_coins(amount: int) -> void:
	coins += maxi(amount, 0)
	changed.emit()


## Jedinečné predmety (hviezdy, truhlice) sa dajú zobrať iba raz za pokus.
func collect_item(item_id: String) -> bool:
	if collected_items.has(item_id):
		return false
	collected_items.append(item_id)
	changed.emit()
	return true


func add_star(star_id: String) -> void:
	if collect_item("star:" + star_id):
		stars.append(star_id)
		changed.emit()


func lose_heart() -> void:
	hearts = maxi(hearts - 1, 0)
	changed.emit()


func is_dead() -> bool:
	return hearts <= 0
