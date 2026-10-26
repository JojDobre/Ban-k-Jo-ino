extends RefCounted
## Základ testovacej sady. Testy sú metódy začínajúce na `test_`.

var failures: Array[String] = []
var tree: SceneTree


func before_each() -> void:
	pass


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s – očakávané %s, skutočné %s" % [message, expected, actual])
