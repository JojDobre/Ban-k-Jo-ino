extends SceneTree
## Spustenie: godot --headless --path . -s res://tests/run_tests.gd
## Návratový kód 0 = všetko prešlo.

const SUITES := [
	"res://tests/test_mine_production.gd",
	"res://tests/test_economy.gd",
	"res://tests/test_progression.gd",
	"res://tests/test_save.gd",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save_manager := root.get_node("SaveManager")
	save_manager.save_path = "user://test_save.json"
	save_manager.autosave_enabled = false

	var passed := 0
	var failed := 0
	for path: String in SUITES:
		var script: GDScript = load(path)
		for method in script.get_script_method_list():
			var name: String = method.name
			if not name.begins_with("test_"):
				continue
			var suite: RefCounted = script.new()
			suite.tree = self
			suite.before_each()
			suite.call(name)
			if suite.failures.is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL %s::%s" % [path.get_file(), name])
				for failure: String in suite.failures:
					print("    ", failure)

	save_manager.delete_save()
	print("\n%d testov prešlo, %d zlyhalo." % [passed, failed])
	quit(1 if failed > 0 else 0)
