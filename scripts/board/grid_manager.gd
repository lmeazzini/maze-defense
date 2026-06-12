class_name GridManager
extends Node2D
## Fonte única da verdade da grade: A*, validação de construção (anti-bloqueio)
## e caminhos com cache por célula de origem.
##
## Coordenadas: todas as posições retornadas são locais ao nó pai (Board).

const CELL_SIZE := 64

enum PlacementError {
	OK,
	OUT_OF_BOUNDS,
	CELL_OCCUPIED,
	ENEMY_ON_CELL,
	BLOCKS_PATH,
	ENTRY_EXIT_CELL,
}

var entry_cell: Vector2i
var exit_cell: Vector2i
var grid_size: Vector2i

var _astar: AStarGrid2D
var _fixed_obstacles: Dictionary = {}  # Set de Vector2i (chave → true)
var _path_cache: Dictionary = {}  # Vector2i → PackedVector2Array


func setup(map: MapData) -> void:
	grid_size = map.grid_size
	entry_cell = map.entry_cell
	exit_cell = map.exit_cell
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(Vector2i.ZERO, map.grid_size)
	_astar.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()
	_fixed_obstacles.clear()
	_path_cache.clear()
	for cell: Vector2i in map.blocked_cells:
		_astar.set_point_solid(cell, true)
		_fixed_obstacles[cell] = true


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE + Vector2(CELL_SIZE, CELL_SIZE) * 0.5


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / CELL_SIZE).floor())


func is_inside(cell: Vector2i) -> bool:
	return _astar.region.has_point(cell)


func is_solid(cell: Vector2i) -> bool:
	return is_inside(cell) and _astar.is_point_solid(cell)


func is_fixed_obstacle(cell: Vector2i) -> bool:
	return _fixed_obstacles.has(cell)


## Valida uma construção hipotética sem nunca mutar a grade de verdade.
## enemy_cells deve conter a célula atual E a próxima célula de cada inimigo vivo.
func validate_placement(cell: Vector2i, enemy_cells: Array[Vector2i]) -> PlacementError:
	if not is_inside(cell):
		return PlacementError.OUT_OF_BOUNDS
	if cell == entry_cell or cell == exit_cell:
		return PlacementError.ENTRY_EXIT_CELL
	if _astar.is_point_solid(cell):
		return PlacementError.CELL_OCCUPIED
	if cell in enemy_cells:
		return PlacementError.ENEMY_ON_CELL
	_astar.set_point_solid(cell, true)
	var blocked := _astar.get_id_path(entry_cell, exit_cell).is_empty()
	if not blocked:
		# Nenhum inimigo vivo pode ficar selado num beco sem saída.
		for enemy_cell: Vector2i in enemy_cells:
			if enemy_cell == cell:
				continue
			if _astar.get_id_path(enemy_cell, exit_cell).is_empty():
				blocked = true
				break
	_astar.set_point_solid(cell, false)
	return PlacementError.BLOCKS_PATH if blocked else PlacementError.OK


func commit_tower(cell: Vector2i) -> void:
	_astar.set_point_solid(cell, true)
	_path_cache.clear()
	GameEvents.grid_changed.emit()


func remove_tower(cell: Vector2i) -> void:
	assert(not is_fixed_obstacle(cell), "Obstáculo fixo não pode ser removido")
	_astar.set_point_solid(cell, false)
	_path_cache.clear()
	GameEvents.grid_changed.emit()


## Caminho (centros de célula, coords locais) de from_cell até a saída.
## Cacheado por célula de origem; o cache é limpo a cada mutação da grade.
func get_world_path(from_cell: Vector2i) -> PackedVector2Array:
	if _path_cache.has(from_cell):
		return _path_cache[from_cell]
	var points := PackedVector2Array()
	for cell: Vector2i in _astar.get_id_path(from_cell, exit_cell):
		points.append(cell_to_world(cell))
	_path_cache[from_cell] = points
	return points


func entry_path() -> PackedVector2Array:
	return get_world_path(entry_cell)


func grid_pixel_size() -> Vector2:
	return Vector2(grid_size) * CELL_SIZE
