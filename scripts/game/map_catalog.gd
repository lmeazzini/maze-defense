class_name MapCatalog
extends RefCounted
## Ordem canônica dos mapas — usada pela seleção, desbloqueio e "próximo mapa".

const MAP_PATHS: Array[String] = [
	"res://data/maps/map_01.tres",
	"res://data/maps/map_02.tres",
	"res://data/maps/map_03.tres",
]


static func all() -> Array[MapData]:
	var maps: Array[MapData] = []
	for path in MAP_PATHS:
		maps.append(load(path) as MapData)
	return maps


static func next_after(map_id: StringName) -> MapData:
	var maps := all()
	for i in maps.size() - 1:
		if maps[i].id == map_id:
			return maps[i + 1]
	return null
