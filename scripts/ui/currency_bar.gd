extends HBoxContainer
## Ukazovateľ mincí a zlata (hlavné menu, mapa, dedina, obchod). Iba zobrazuje stav.

@onready var _coins: Label = $CoinsLabel
@onready var _gold: Label = $GoldLabel


func _ready() -> void:
	EconomyManager.currency_changed.connect(func(_c: int, _g: int) -> void: _refresh(true))
	GameState.progress_replaced.connect(func() -> void: _refresh(false))
	_refresh(false)


func _refresh(animate: bool) -> void:
	var changed := _coins.text != str(GameState.progress.coins) or _gold.text != str(GameState.progress.gold)
	_coins.text = str(GameState.progress.coins)
	_gold.text = str(GameState.progress.gold)
	if animate and changed:
		pivot_offset = size * 0.5
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08)
		tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
