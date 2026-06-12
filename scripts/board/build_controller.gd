class_name BuildController
extends Node2D
## FSM de input do tabuleiro: IDLE ↔ BUILDING(tower_data) ↔ TOWER_SELECTED(tower).
## Une validação (GridManager), custo (Economy) e ciclo de vida das torres.

## Razão extra de rejeição além de GridManager.PlacementError (não é assunto da grade)
const REASON_NO_GOLD := 100

enum State { IDLE, BUILDING, TOWER_SELECTED }

signal tower_selected(tower: Tower)
signal selection_cleared

const TOWER_SCENE := preload("res://scenes/towers/tower.tscn")

var _state := State.IDLE
var _build_data: TowerData
var _selected: Tower
var _towers_by_cell: Dictionary = {}

var _grid: GridManager
var _registry: EnemyRegistry
var _economy: Economy
var _board: Node2D
var _towers: Node2D
var _projectiles: Node2D
var _overlay: GridOverlay
var _catalog: Array[TowerData] = []


func setup(
	grid: GridManager,
	registry: EnemyRegistry,
	economy: Economy,
	board: Node2D,
	towers: Node2D,
	projectiles: Node2D,
	overlay: GridOverlay,
	catalog: Array[TowerData],
) -> void:
	_grid = grid
	_registry = registry
	_economy = economy
	_board = board
	_towers = towers
	_projectiles = projectiles
	_overlay = overlay
	_catalog = catalog


func enter_build_mode(data: TowerData) -> void:
	_clear_selection()
	_state = State.BUILDING
	_build_data = data
	GameEvents.build_mode_changed.emit(data)
	_refresh_preview()


func exit_build_mode() -> void:
	if _state == State.BUILDING:
		_state = State.IDLE
		_build_data = null
		GameEvents.build_mode_changed.emit(null)
		_overlay.clear_hover()


func selected_tower() -> Tower:
	return _selected


func is_building() -> bool:
	return _state == State.BUILDING


func upgrade_selected() -> void:
	if _selected == null or not _selected.can_upgrade():
		return
	if not _economy.spend(_selected.upgrade_cost()):
		GameEvents.placement_rejected.emit(REASON_NO_GOLD)
		return
	_selected.upgrade()
	tower_selected.emit(_selected)  # painel reabre com números novos


func sell_selected() -> void:
	if _selected == null:
		return
	var tower := _selected
	_clear_selection()
	var refund := _economy.sell_refund(tower.invested)
	_economy.add_gold(refund)
	_towers_by_cell.erase(tower.cell)
	_grid.remove_tower(tower.cell)  # emite grid_changed → inimigos reroteiam
	GameEvents.tower_sold.emit(tower.cell, refund)
	tower.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_refresh_preview()
	elif event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_handle_click()
	elif event.is_action_pressed(&"cancel_build"):
		exit_build_mode()
		_clear_selection()
	else:
		for i in _catalog.size():
			if event.is_action_pressed("select_tower_%d" % (i + 1)):
				enter_build_mode(_catalog[i])
				return


func _mouse_cell() -> Vector2i:
	return _grid.world_to_cell(_board.to_local(_board.get_global_mouse_position()))


func _refresh_preview() -> void:
	if _state != State.BUILDING:
		return
	var cell := _mouse_cell()
	if not _grid.is_inside(cell):
		_overlay.clear_hover()
		return
	var error := _grid.validate_placement(cell, _registry.occupied_cells())
	var valid := error == GridManager.PlacementError.OK \
		and _economy.can_afford(_build_data.levels[0].cost)
	_overlay.set_hover(cell, valid, _build_data.levels[0].range_px)


func _handle_click() -> void:
	var cell := _mouse_cell()
	if not _grid.is_inside(cell):
		return
	match _state:
		State.BUILDING:
			_try_place(cell)
		State.IDLE, State.TOWER_SELECTED:
			_select_at(cell)


func _try_place(cell: Vector2i) -> void:
	var error := _grid.validate_placement(cell, _registry.occupied_cells())
	if error != GridManager.PlacementError.OK:
		GameEvents.placement_rejected.emit(error)
		return
	if not _economy.spend(_build_data.levels[0].cost):
		GameEvents.placement_rejected.emit(REASON_NO_GOLD)
		return
	var tower: Tower = TOWER_SCENE.instantiate()
	_towers.add_child(tower)
	tower.position = _grid.cell_to_world(cell)
	tower.setup(_build_data, _registry, _projectiles, cell)
	_towers_by_cell[cell] = tower
	_grid.commit_tower(cell)  # emite grid_changed → inimigos reroteiam
	GameEvents.tower_placed.emit(tower)
	_refresh_preview()  # continua no modo build para colocar várias


func _select_at(cell: Vector2i) -> void:
	var tower: Tower = _towers_by_cell.get(cell)
	if tower == null:
		_clear_selection()
		return
	_selected = tower
	_state = State.TOWER_SELECTED
	_overlay.set_hover(cell, true, tower.stats().range_px)
	tower_selected.emit(tower)


func _clear_selection() -> void:
	if _selected != null or _state == State.TOWER_SELECTED:
		_selected = null
		_state = State.IDLE
		_overlay.clear_hover()
		selection_cleared.emit()
