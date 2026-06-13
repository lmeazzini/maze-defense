class_name GameLevel3D
extends Node3D
## Vertical slice 3D: carrega o mapa, monta o tabuleiro 3D, posiciona a câmera
## top-down inclinada e permite colocar/remover blocos por raycast (reusando a
## validação anti-bloqueio do GridManager). Espaço gera um inimigo que anda e
## reroteia ao vivo. Sem torres/economia ainda — é prova de conceito da camada 3D.

const DEFAULT_MAP := preload("res://data/maps/map_01.tres")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_3d.tscn")
const DEBUG_ENEMY := preload("res://data/enemies/normal.tres")

@onready var _grid: GridManager = $GridManager
@onready var _view: GridView3D = $GridView3D
@onready var _camera: Camera3D = $Camera3D
@onready var _enemies: Node3D = $Enemies

var _map: MapData
var _alive: Array[Enemy3D] = []


func _ready() -> void:
	_map = GameLevel.next_map if GameLevel.next_map != null else DEFAULT_MAP
	_grid.setup(_map)
	_view.setup(_grid)
	_place_camera()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _place_camera() -> void:
	var w := _grid.grid_size.x * GridManager.CELL_SIZE_3D
	var h := _grid.grid_size.y * GridManager.CELL_SIZE_3D
	var center := Vector3(w * 0.5, 0.0, h * 0.5)
	var span := maxf(w, h)
	_camera.position = center + Vector3(0.0, span * 0.78, span * 0.62)
	_camera.look_at(center, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell := _cell_under_mouse()
		if _grid.is_inside(cell):
			_view.set_preview(cell, _can_place(cell))
		else:
			_view.clear_preview()
	elif event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_handle_click()
	elif event.is_action_pressed(&"start_wave"):
		_spawn_enemy()


func _cell_under_mouse() -> Vector2i:
	var mouse := get_viewport().get_mouse_position()
	var from := _camera.project_ray_origin(mouse)
	var dir := _camera.project_ray_normal(mouse)
	var ground := Plane(Vector3.UP, 0.0)
	var hit: Variant = ground.intersects_ray(from, dir)
	if hit == null:
		return Vector2i(-1, -1)
	return _grid.world_to_cell_3d(hit)


func _can_place(cell: Vector2i) -> bool:
	return _grid.validate_placement(cell, _occupied_cells()) == GridManager.PlacementError.OK


func _handle_click() -> void:
	var cell := _cell_under_mouse()
	if not _grid.is_inside(cell) or _grid.is_fixed_obstacle(cell):
		return
	if _grid.is_solid(cell):
		_grid.remove_tower(cell)
	elif _can_place(cell):
		_grid.commit_tower(cell)
	else:
		GameEvents.placement_rejected.emit(GridManager.PlacementError.BLOCKS_PATH)


func _spawn_enemy() -> void:
	var enemy: Enemy3D = ENEMY_SCENE.instantiate()
	_enemies.add_child(enemy)
	enemy.setup(_grid, DEBUG_ENEMY)
	enemy.start()
	enemy.died.connect(_on_enemy_removed)
	enemy.leaked.connect(_on_enemy_removed)
	_alive.append(enemy)


func _on_enemy_removed(enemy: Enemy3D) -> void:
	_alive.erase(enemy)


## Célula atual + próxima de cada inimigo vivo (deduplicadas) para a validação.
func _occupied_cells() -> Array[Vector2i]:
	var seen: Dictionary = {}
	for enemy in _alive:
		seen[enemy.current_cell()] = true
		seen[enemy.next_cell()] = true
	var cells: Array[Vector2i] = []
	for cell: Vector2i in seen:
		cells.append(cell)
	return cells
