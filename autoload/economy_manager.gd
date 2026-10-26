extends Node
## Jediné miesto, kde sa menia mince a zlato (GDD kap. 7.5).
## Mena nikdy neklesne pod nulu a nákup je atomický.

signal currency_changed(coins: int, gold: int)


## Jediný vstupný bod pre všetky príjmy. `source` určuje pôvod:
## "level", "level_fail", "mine", "chest", v budúcnosti "speech_exercise".
func grant_reward(source: String, coins: int, gold: int) -> bool:
	if coins < 0 or gold < 0:
		push_warning("Odmietnutá záporná odmena zo zdroja '%s'." % source)
		return false
	if coins == 0 and gold == 0:
		return true
	var progress := GameState.progress
	progress.coins += coins
	progress.gold += gold
	_changed()
	return true


func can_afford(coins_cost: int, gold_cost: int) -> bool:
	if coins_cost < 0 or gold_cost < 0:
		return false
	var progress := GameState.progress
	return progress.coins >= coins_cost and progress.gold >= gold_cost


## Atomický nákup – buď sa odpočítajú obe meny, alebo nič.
func spend(coins_cost: int, gold_cost: int) -> bool:
	if not can_afford(coins_cost, gold_cost):
		return false
	var progress := GameState.progress
	progress.coins -= coins_cost
	progress.gold -= gold_cost
	_changed()
	return true


## Jednorazová odmena. Druhé volanie s rovnakým `reward_id` nič nepripíše.
func claim_one_time(reward_id: String, coins: int, gold: int) -> bool:
	var progress := GameState.progress
	if reward_id.is_empty() or progress.claimed_rewards.has(reward_id):
		return false
	if not grant_reward(reward_id, coins, gold):
		return false
	progress.claimed_rewards.append(reward_id)
	SaveManager.request_save()
	return true


func _changed() -> void:
	currency_changed.emit(GameState.progress.coins, GameState.progress.gold)
	SaveManager.request_save()
