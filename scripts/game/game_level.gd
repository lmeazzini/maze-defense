class_name GameLevel
extends Node2D
## Orquestrador da partida. No M1: carrega o mapa, centraliza o tabuleiro e
## permite colocar/remover blocos com preview — valida anti-bloqueio ao vivo.
## (O input de construção migra para o BuildController no M3.)

const DEFAULT_MAP := preload("res://data/maps/map_01.tres")

## Definido pela seleção de mapa antes da troca de cena (M5)
static var next_map: MapData

@onready var _board: Node2D = $Board
@onready var _grid: GridManager = $Board/GridManager
@onready var _overlay: GridOverlay = $Board/GridOverlay

var _map: MapData


func _ready() -> void:
	_map = next_map if next_map != null else DEFAULT_MAP
	next_map = null
	_grid.setup(_map)
	_overlay.setup(_grid)
	_board.position = ((get_viewport_rect().size - _grid.grid_pixel_size()) * 0.5).floor()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover()
	elif event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_handle_click()


func _mouse_cell() -> Vector2i:
	return _grid.world_to_cell(_board.to_local(get_global_mouse_position()))


func _update_hover() -> void:
	var cell := _mouse_cell()
	if not _grid.is_inside(cell):
		_overlay.clear_hover()
		return
	if _grid.is_solid(cell) and not _grid.is_fixed_obstacle(cell):
		# Bloco removível: hover "válido" sinaliza ação possível (remover)
		_overlay.set_hover(cell, true)
		return
	var error := _grid.validate_placement(cell, _enemy_cells())
	_overlay.set_hover(cell, error == GridManager.PlacementError.OK)


func _handle_click() -> void:
	var cell := _mouse_cell()
	if not _grid.is_inside(cell):
		return
	if _grid.is_fixed_obstacle(cell):
		return
	if _grid.is_solid(cell):
		_grid.remove_tower(cell)
	else:
		var error := _grid.validate_placement(cell, _enemy_cells())
		if error == GridManager.PlacementError.OK:
			_grid.commit_tower(cell)
		else:
			GameEvents.placement_rejected.emit(error)
	_update_hover()


func _enemy_cells() -> Array[Vector2i]:
	# M2: virá do EnemyRegistry (célula atual + próxima de cada inimigo vivo)
	return []
