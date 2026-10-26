class_name PhantomEnemy
extends Enemy
## Mucha, ktorá mizne: chvíľu poletuje na mieste, potom zmizne a objaví sa
## na druhom mieste. Keď je neviditeľná, nezraňuje a nedá sa zasiahnuť.

enum State { VISIBLE, FADING_OUT, HIDDEN, FADING_IN }

## Druhé miesto, kam mucha preskakuje (relatívne k štartu).
@export var jump_offset: Vector2 = Vector2(256, -64)
@export var visible_time: float = 2.4
@export var hidden_time: float = 1.0
const FADE_TIME := 0.35

var _state := State.VISIBLE
var _state_time := 0.0
var _anchors: Array[Vector2] = []
var _anchor := 0


func _on_ready() -> void:
	_anchors = [global_position, global_position + jump_offset]
	_state_time = randf() * visible_time


func _move(delta: float) -> void:
	_state_time += delta
	var anchor := _anchors[_anchor]
	global_position = anchor + Vector2(sin(_time * 1.7) * 18.0, sin(_time * 3.1) * 12.0)
	match _state:
		State.VISIBLE:
			if _state_time > visible_time:
				_set_state(State.FADING_OUT)
				Effects.burst(self, global_position, Color(0.8, 0.9, 1.0, 0.8), 8, 90.0, 0.8, 0.0)
		State.FADING_OUT:
			if _state_time > FADE_TIME:
				_set_state(State.HIDDEN)
		State.HIDDEN:
			if _state_time > hidden_time:
				_anchor = (_anchor + 1) % _anchors.size()
				direction = -direction
				_set_state(State.FADING_IN)
		State.FADING_IN:
			if _state_time > FADE_TIME:
				_set_state(State.VISIBLE)
	_harmless = _state == State.HIDDEN or _state == State.FADING_OUT or (_state == State.FADING_IN and _state_time < FADE_TIME * 0.7)


func _animate(_delta: float) -> void:
	sprite.speed_scale = 1.6
	var alpha := 1.0
	match _state:
		State.FADING_OUT:
			alpha = 1.0 - _state_time / FADE_TIME
		State.HIDDEN:
			alpha = 0.0
		State.FADING_IN:
			alpha = _state_time / FADE_TIME
	sprite.modulate.a = clampf(alpha, 0.0, 1.0)
	sprite.scale = Vector2.ONE * lerpf(0.6, 1.0, clampf(alpha, 0.0, 1.0))


func _set_state(state: State) -> void:
	_state = state
	_state_time = 0.0
