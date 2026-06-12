extends Node
## Persistência local em user://save.json (escrita atômica: temp + rename).
## Guarda: mapas desbloqueados, melhor onda/estrelas por mapa, volumes.

const SAVE_PATH := "user://save.json"
const SAVE_PATH_TMP := "user://save.json.tmp"
const SCHEMA_VERSION := 1
const FIRST_MAP := &"map_01"

var _data: Dictionary = {}


func _ready() -> void:
	load_profile()


func load_profile() -> void:
	_data = _defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Falha ao abrir save: %s" % FileAccess.get_open_error())
		return
	# JSON.new().parse retorna o erro sem poluir o log de engine (parse_string loga)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("Save corrompido — usando padrões.")
		return
	var parsed: Variant = json.data
	if parsed is Dictionary and (parsed as Dictionary).get("version") == SCHEMA_VERSION:
		_data = parsed
	else:
		push_warning("Save de versão desconhecida — usando padrões.")


func is_unlocked(map_id: StringName) -> bool:
	return str(map_id) in (_data["unlocked"] as Array)


func unlock_map(map_id: StringName) -> void:
	if not is_unlocked(map_id):
		(_data["unlocked"] as Array).append(str(map_id))
		_persist()


func record_result(map_id: StringName, best_wave: int, stars: int) -> void:
	var results: Dictionary = _data["results"]
	var prev: Dictionary = results.get(str(map_id), {"best_wave": 0, "stars": 0})
	results[str(map_id)] = {
		"best_wave": maxi(best_wave, int(prev["best_wave"])),
		"stars": maxi(stars, int(prev["stars"])),
	}
	_persist()


func get_best_wave(map_id: StringName) -> int:
	return int((_data["results"] as Dictionary).get(str(map_id), {}).get("best_wave", 0))


func get_stars(map_id: StringName) -> int:
	return int((_data["results"] as Dictionary).get(str(map_id), {}).get("stars", 0))


func set_volume(bus: StringName, linear: float) -> void:
	(_data["audio"] as Dictionary)[str(bus)] = clampf(linear, 0.0, 1.0)
	_persist()


func get_volume(bus: StringName) -> float:
	return float((_data["audio"] as Dictionary).get(str(bus), 1.0))


func _defaults() -> Dictionary:
	return {
		"version": SCHEMA_VERSION,
		"unlocked": [str(FIRST_MAP)],
		"results": {},
		"audio": {"Music": 0.8, "SFX": 1.0},
	}


func _persist() -> void:
	var file := FileAccess.open(SAVE_PATH_TMP, FileAccess.WRITE)
	if file == null:
		push_error("Falha ao gravar save: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()
	var err := DirAccess.rename_absolute(SAVE_PATH_TMP, SAVE_PATH)
	if err != OK:
		push_error("Falha ao renomear save temporário: %s" % err)
