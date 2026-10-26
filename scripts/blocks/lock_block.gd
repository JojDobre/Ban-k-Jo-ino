class_name LockBlock
extends StaticBody2D
## Zamknutý blok – zmizne, keď Jožino nájde kľúč (GDD: tajné miesta).


func _ready() -> void:
	add_to_group(&"lock_block")


func unlock(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	Audio.play(&"break", 0.1)
	Effects.poof(self, global_position)
	Effects.sparkle(self, global_position)
	queue_free()
