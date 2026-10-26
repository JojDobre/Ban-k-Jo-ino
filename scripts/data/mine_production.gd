class_name MineProduction
extends RefCounted
## Čistý výpočet offline produkcie bane (GDD kap. 5.3). Bez stavu, ľahko testovateľný.

const SECONDS_PER_HOUR := 3600


## Vráti {"coins": int, "new_last_claim": int}.
## Ak čas uplynul menej, ako treba na celú mincu, zvyšok sa zachová
## (posunie sa iba o čas zodpovedajúci vyplateným minciam).
static func calculate(last_claim: int, now: int, coins_per_hour: int, cap_hours: float, time_scale: float = 1.0) -> Dictionary:
	if coins_per_hour <= 0 or last_claim <= 0:
		return {"coins": 0, "new_last_claim": now}
	var elapsed := now - last_claim
	if elapsed < 0:
		# Systémový čas sa posunul dozadu – nič nevyplatiť, začať odznova.
		return {"coins": 0, "new_last_claim": now}

	var cap_seconds := int(cap_hours * SECONDS_PER_HOUR / time_scale)
	if elapsed >= cap_seconds:
		var capped := int(cap_hours * coins_per_hour)
		return {"coins": capped, "new_last_claim": now}

	var game_seconds := elapsed * time_scale
	var earned := int(floor(game_seconds * coins_per_hour / SECONDS_PER_HOUR))
	var consumed := int(ceil(float(earned) * SECONDS_PER_HOUR / coins_per_hour / time_scale))
	return {"coins": earned, "new_last_claim": last_claim + mini(consumed, elapsed)}
