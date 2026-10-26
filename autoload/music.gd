extends Node
## Hudba na pozadí. Použitie: `Music.play(&"level")`. Skladby sa opakujú dookola
## a pri zmene sa plynule prelínajú. Hlasitosť sa riadi nastavením `music_volume`.

const TRACKS := {
	&"level": preload("res://assets/music/happy_clappy_loop.ogg"),
	&"calm": preload("res://assets/music/feel_good_island_loop.ogg"),
}
const FADE_TIME := 0.8
## Hudba je o niečo tichšia ako efekty, aby ich neprekrývala.
const BASE_VOLUME_DB := -6.0

var _player: AudioStreamPlayer
var _current: StringName
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)


func play(track: StringName) -> void:
	if track == _current and _player.playing:
		return
	var stream: AudioStream = TRACKS.get(track)
	if stream == null:
		push_warning("Neznáma skladba: %s" % track)
		return
	_current = track
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_fade_to(-40.0, func() -> void:
		_player.stream = stream
		_player.play()
		_fade_to(_target_volume_db()))


func stop() -> void:
	_current = &""
	_fade_to(-40.0, _player.stop)


## Krátke stíšenie, napr. počas zvuku výhry.
func duck(duration: float) -> void:
	_fade_to(_target_volume_db() - 14.0)
	await get_tree().create_timer(duration).timeout
	if _player.playing:
		_fade_to(_target_volume_db())


func refresh_volume() -> void:
	_player.volume_db = _target_volume_db()


func _target_volume_db() -> float:
	var volume := float(GameState.progress.settings.get("music_volume", 0.8))
	return BASE_VOLUME_DB + linear_to_db(maxf(volume, 0.0001))


func _fade_to(volume_db: float, then: Callable = Callable()) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var time := FADE_TIME if _player.playing else 0.01
	_tween.tween_property(_player, "volume_db", volume_db, time)
	if then.is_valid():
		_tween.tween_callback(then)
