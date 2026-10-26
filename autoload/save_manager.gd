extends Node
## Ukladanie a načítanie progresu (GDD kap. 6 a 11).
## Atomický zápis: .tmp -> premenovanie, predchádzajúce uloženie ostáva ako .bak.

const DEFAULT_SAVE_PATH := "user://save.json"

## Testy si cestu presmerujú, aby neprepísali skutočné uloženie.
var save_path: String = DEFAULT_SAVE_PATH
## Vypnuté v testoch, aby sa nezapisovalo na disk pri každej zmene meny.
var autosave_enabled: bool = true

var _save_pending := false


## Naplánuje uloženie na koniec snímky. Viac zmien v jednej snímke = jeden zápis,
## takže zložené operácie (mena + čas bane) sa uložia spolu.
func request_save() -> void:
	if not autosave_enabled or _save_pending:
		return
	_save_pending = true
	_flush_save.call_deferred()


func save_now() -> bool:
	_save_pending = false
	return save_progress(GameState.progress)


func save_progress(progress: PlayerProgress) -> bool:
	var tmp_path := save_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("Uloženie zlyhalo, nedá sa otvoriť %s: %s" % [tmp_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(progress.to_dict(), "\t"))
	file.close()

	var backup_path := save_path + ".bak"
	if FileAccess.file_exists(save_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		DirAccess.rename_absolute(save_path, backup_path)
	var err := DirAccess.rename_absolute(tmp_path, save_path)
	if err != OK:
		push_error("Uloženie zlyhalo pri premenovaní: %s" % error_string(err))
		return false
	return true


## Načíta progres: uloženie -> záloha -> predvolený progres. Nikdy nezlyhá.
func load_progress() -> PlayerProgress:
	for path: String in [save_path, save_path + ".bak"]:
		var data := _read_json(path)
		if not data.is_empty():
			return PlayerProgress.from_dict(_migrate(data))
	return _new_game()


func delete_save() -> void:
	for path: String in [save_path, save_path + ".bak", save_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _new_game() -> PlayerProgress:
	var progress := PlayerProgress.new()
	progress.last_mine_claim = GameState.now()
	return progress


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_warning("Poškodené uloženie: %s" % path)
	return {}


## Postupná migrácia starších verzií. Pri zmene dátového modelu zvýš
## PlayerProgress.SAVE_VERSION a pridaj sem krok pre predchádzajúcu verziu.
func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("save_version", 1))
	if version == 1:
		# Verzia 2 pridala obleky, predmety z obchodu a posledný level – štart s predvolenými hodnotami.
		data["owned_outfits"] = [PlayerProgress.DEFAULT_OUTFIT]
		data["outfit"] = PlayerProgress.DEFAULT_OUTFIT
		data["items"] = {}
		data["last_level"] = ""
		version = 2
	data["save_version"] = version
	return data


func _flush_save() -> void:
	if _save_pending:
		save_now()


func _notification(what: int) -> void:
	# Android často ukončí aplikáciu na pozadí bez ďalšieho upozornenia.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if autosave_enabled:
			save_now()
