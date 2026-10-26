extends Control
## Mapa sveta Zelené údolie: uzly levelov spojené cestičkou, Jožino stojí pri aktuálnom leveli.
## Dotyk na uzol: Jožino k nemu prejde a otvorí sa okno s detailom levelu.

const PATH_COLOR := Color(1, 0.97, 0.88, 0.95)
const GROUND_HEIGHT := 128.0

var _nodes: Array[LevelNode] = []
var _selected: LevelDefinition
var _jozino_level_id := ""

@onready var _map: Control = %Map
@onready var _jozino: AnimatedSprite2D = %Jozino
@onready var _popup: Control = %Popup


func _ready() -> void:
	Music.play(&"calm")
	%BackButton.pressed.connect(GameState.change_scene.bind(GameState.SCENE_MAIN_MENU))
	%VillageButton.pressed.connect(GameState.change_scene.bind(GameState.SCENE_VILLAGE))
	%ShopButton.pressed.connect(GameState.change_scene.bind(GameState.SCENE_SHOP))
	%PlayButton.pressed.connect(_play_selected)
	%CloseButton.pressed.connect(_popup.hide)
	_popup.hide()
	_jozino.sprite_frames = load("res://assets/player/%s/frames.tres" % GameState.progress.outfit)
	_jozino.play(&"idle")
	for i in ProgressionManager.LEVELS.size():
		var node := LevelNode.new()
		node.setup(ProgressionManager.LEVELS[i], i + 1)
		node.selected.connect(_on_level_selected)
		_map.add_child(node)
		_nodes.append(node)
	_map.draw.connect(_draw_path)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_jozino_level_id = ProgressionManager.get_current_level_id()
	_place_jozino(_jozino_level_id, false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _popup.visible:
			_popup.hide()
		else:
			GameState.change_scene(GameState.SCENE_MAIN_MENU)


func _process(_delta: float) -> void:
	_jozino.offset.y = sin(Time.get_ticks_msec() * 0.004) * 2.0


func _layout() -> void:
	var view := get_viewport_rect().size
	var top := 150.0
	var bottom := view.y - GROUND_HEIGHT - 120.0
	for node in _nodes:
		var rel := node.level.map_position
		var center := Vector2(rel.x * view.x, lerpf(top, bottom, rel.y))
		node.position = center - Vector2(node.size.x * 0.5, LevelNode.RADIUS + 10)
	# Dekorácie: hrad budúceho sveta vpravo, stromy pri ceste.
	var ground_y := view.y - GROUND_HEIGHT + 14.0
	%Castle.position = Vector2(view.x - 130.0, ground_y)
	%ComingSoon.position = Vector2(view.x - 275.0, ground_y - 250.0)
	%Tree1.position = Vector2(view.x * 0.08, ground_y)
	%Tree2.position = Vector2(view.x * 0.36, ground_y)
	%Tree3.position = Vector2(view.x * 0.62, ground_y)
	_map.queue_redraw()
	if not _jozino_level_id.is_empty():
		_place_jozino(_jozino_level_id, false)


func _node_center(node: LevelNode) -> Vector2:
	return node.position + Vector2(node.size.x * 0.5, LevelNode.RADIUS + 10)


## Bodkovaná cestička medzi uzlami (mierne prehnutá).
func _draw_path() -> void:
	for i in _nodes.size() - 1:
		var a := _node_center(_nodes[i])
		var b := _node_center(_nodes[i + 1])
		var control := (a + b) * 0.5 + Vector2(0, 70)
		var unlocked := ProgressionManager.is_unlocked(_nodes[i + 1].level.id)
		var steps := 14
		for s in range(1, steps):
			var t := float(s) / steps
			var p := a.lerp(control, t).lerp(control.lerp(b, t), t)
			_map.draw_circle(p + Vector2(0, 4), 9.0, Color(0, 0, 0, 0.15))
			_map.draw_circle(p, 9.0, PATH_COLOR if unlocked else Color(1, 1, 1, 0.45))


func _place_jozino(level_id: String, animate: bool) -> void:
	for node in _nodes:
		if node.level.id != level_id:
			continue
		# Jožino stojí nad uzlom (chodidlá na hornom okraji kruhu).
		var target := _node_center(node) + Vector2(0, -LevelNode.RADIUS - 51.0 * _jozino.scale.y + 8.0)
		if animate:
			_jozino.flip_h = target.x < _jozino.position.x
			_jozino.play(&"run")
			var tween := create_tween()
			tween.tween_property(_jozino, "position", target, 0.45).set_trans(Tween.TRANS_SINE)
			tween.tween_callback(_jozino.play.bind(&"idle"))
			await tween.finished
		else:
			_jozino.position = target
		_jozino_level_id = level_id
		return


func _on_level_selected(level: LevelDefinition) -> void:
	if not ProgressionManager.is_unlocked(level.id):
		Audio.play(&"hurt")
		Effects.floating_text(self, _node_center(_nodes[ProgressionManager.LEVELS.find(level)]) + Vector2(0, -90), "Najprv dokonči predchádzajúci level", Color("ffd84d"), 28)
		return
	Audio.play(&"bump")
	_selected = level
	if level.id != _jozino_level_id:
		await _place_jozino(level.id, true)
	_show_popup(level)


func _show_popup(level: LevelDefinition) -> void:
	var number := ProgressionManager.LEVELS.find(level) + 1
	%LevelTitle.text = "Level %d" % number
	%LevelName.text = level.display_name
	var found := GameState.progress.get_stars(level.id).size()
	for i in %PopupStars.get_child_count():
		(%PopupStars.get_child(i) as CanvasItem).modulate = Color.WHITE if i < found else Color(0.2, 0.15, 0.1, 0.35)
	%LevelStatus.text = "Dokončený" if ProgressionManager.is_completed(level.id) else "Nový level"
	%PlayButton.text = "Hrať znova" if ProgressionManager.is_completed(level.id) else "Hrať"
	_popup.show()
	var panel := %PopupPanel as Control
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.8, 0.8)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _play_selected() -> void:
	if _selected != null:
		ProgressionManager.start_level(_selected.id)
