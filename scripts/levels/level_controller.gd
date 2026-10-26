class_name LevelController
extends Node2D
## Riadi jeden pokus v leveli: srdcia, checkpointy, cieľ a neúspech (GDD kap. 9).
## Výsledok odovzdá ProgressionManager; sám menu ani uloženie nemení.

@export var level_definition: LevelDefinition
## Pod touto výškou Jožino spadol do jamy.
@export var fall_limit_y: float = 900.0
## Pravý okraj levelu pre kameru.
@export var level_width: float = 4060.0
## Spodný okraj, ktorý ešte ukáže kamera.
@export var camera_limit_bottom: float = 900.0

const RESULTS_DELAY := 1.2

var run: LevelRun
var _finished := false

@onready var player: Player = $Player
@onready var hud: Hud = $Hud


func _enter_tree() -> void:
	# Pokus musí existovať skôr, ako sa spustí _ready() detí (hviezdy, truhlice).
	run = LevelRun.new(level_definition.id, GameState.get_max_hearts(), ($Player as Node2D).position)
	GameState.current_run = run


func _exit_tree() -> void:
	if GameState.current_run == run:
		GameState.current_run = null


func _ready() -> void:
	player.magnet_radius = GameState.get_magnet_radius()
	player.damaged.connect(_on_player_damaged)
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_bottom = int(camera_limit_bottom)
	camera.limit_right = int(level_width)
	for goal in get_tree().get_nodes_in_group("goal"):
		(goal as Goal).reached.connect(_on_goal_reached)
	hud.bind(run, level_definition)
	hud.restart_requested.connect(_restart)


func _physics_process(_delta: float) -> void:
	if not _finished and player.global_position.y > fall_limit_y:
		_on_player_fell()


func _on_player_damaged() -> void:
	run.lose_heart()
	if run.is_dead():
		_finish(false)


func _on_player_fell() -> void:
	run.lose_heart()
	Audio.play(&"hurt")
	if run.is_dead():
		_finish(false)
	else:
		player.respawn(run.checkpoint)


func _on_goal_reached() -> void:
	if not _finished:
		_finish(true)


func _finish(success: bool) -> void:
	_finished = true
	if success:
		player.celebrate()
		Audio.play(&"win")
	else:
		player.play_death()
		Audio.play(&"fail")
	var result := ProgressionManager.finish_run(run, success, level_definition)
	# Chvíľa na dohranie animácie pred obrazovkou výsledkov.
	await get_tree().create_timer(RESULTS_DELAY).timeout
	hud.show_results(result)


func _restart() -> void:
	GameState.change_scene(scene_file_path)
