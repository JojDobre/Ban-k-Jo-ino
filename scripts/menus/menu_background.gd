extends Control
## Spoločné pozadie obrazoviek mimo levelu: obloha so slnkom, kopce a pás trávy dole.
## Vrstvy sa pri zmene veľkosti obrazovky zarovnajú k zemi.

@export var ground_height: float = 128.0

## Vrstva -> výška hrebeňa nad zemou (px) a výška hrebeňa v kresbe (px po zväčšení ×2).
const LAYER_CRESTS := {
	"Clouds": [330.0, 220.0],
	"Trees": [210.0, 160.0],
	"Hills": [110.0, 260.0],
}

@onready var _parallax: Node2D = $Parallax


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var ground_y := get_viewport_rect().size.y - ground_height
	for layer in _parallax.get_children():
		var crest: Array = LAYER_CRESTS.get(String(layer.name), [0.0, 0.0])
		(layer.get_node("Sprite") as Node2D).position.y = ground_y - crest[0] - crest[1]
