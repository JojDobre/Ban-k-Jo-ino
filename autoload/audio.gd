extends Node
## Krátke zvukové efekty. Použitie: `Audio.play(&"coin")`.
## Hlasitosť sa riadi nastavením `sfx_volume` v PlayerProgress.

const SOUNDS := {
	&"jump": preload("res://assets/audio/sfx_jump.ogg"),
	&"spring": preload("res://assets/audio/sfx_jump_high.ogg"),
	&"coin": preload("res://assets/audio/sfx_coin.ogg"),
	&"star": preload("res://assets/audio/sfx_magic.ogg"),
	&"gold": preload("res://assets/audio/gold.wav"),
	&"checkpoint": preload("res://assets/audio/sfx_gem.ogg"),
	&"hurt": preload("res://assets/audio/sfx_hurt.ogg"),
	&"stomp": preload("res://assets/audio/sfx_bump.ogg"),
	&"fail": preload("res://assets/audio/sfx_disappear.ogg"),
	&"win": preload("res://assets/audio/win.mp3"),
	&"bump": preload("res://assets/audio/sfx_bump.ogg"),
	&"break": preload("res://assets/audio/break.ogg"),
	&"secret": preload("res://assets/audio/secret.ogg"),
	&"powerup": preload("res://assets/audio/powerup.ogg"),
	&"key": preload("res://assets/audio/key.ogg"),
	&"slam": preload("res://assets/audio/slam.ogg"),
	&"shield_pop": preload("res://assets/audio/shield_pop.ogg"),
	&"switch": preload("res://assets/audio/switch.ogg"),
	&"alert": preload("res://assets/audio/alert.ogg"),
}
const POOL_SIZE := 12

var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


## `pitch_variation` náhodne mierne zmení výšku tónu, aby opakované zvuky (mince) neboli monotónne.
func play(sound: StringName, pitch_variation: float = 0.0) -> void:
	var stream: AudioStream = SOUNDS.get(sound)
	if stream == null:
		push_warning("Neznámy zvuk: %s" % sound)
		return
	var player := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.volume_db = linear_to_db(maxf(float(GameState.progress.settings.get("sfx_volume", 1.0)), 0.0001))
	player.play()

