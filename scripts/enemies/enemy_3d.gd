class_name Enemy3D
extends Node3D
## Versão 3D do inimigo: anda de centro em centro de célula no plano XZ até a
## saída. Mesmo invariante de reroteamento do Enemy 2D: estando entre A e B
## (indo para o centro de B), o novo caminho é calculado A PARTIR DE B.

signal died(enemy: Enemy3D)
signal leaked(enemy: Enemy3D)

var data: EnemyData
var current_hp: float
var remaining_distance: float = 0.0

var _grid: GridManager
var _path: PackedVector3Array
var _path_index: int = 0
var _finished: bool = false

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	GameEvents.grid_changed.connect(_on_grid_changed)


func setup(grid: GridManager, enemy_data: EnemyData, hp_multiplier: float = 1.0) -> void:
	_grid = grid
	data = enemy_data
	current_hp = data.max_hp * hp_multiplier


func start() -> void:
	position = _grid.cell_to_world_3d(_grid.entry_cell)
	_adopt_path(_grid.get_world_path_3d(_grid.entry_cell))
	_tint_placeholder()


func current_cell() -> Vector2i:
	return _grid.world_to_cell_3d(position)


func next_cell() -> Vector2i:
	if _path_index < _path.size():
		return _grid.world_to_cell_3d(_path[_path_index])
	return current_cell()


func is_alive() -> bool:
	return not _finished


func _physics_process(delta: float) -> void:
	if _finished or _path_index >= _path.size():
		return
	var budget := data.speed * GridManager.CELL_SIZE_3D / float(GridManager.CELL_SIZE) * delta
	# Escala a velocidade (definida em px/s no .tres) para unidades 3D/s
	while budget > 0.0 and _path_index < _path.size():
		var target := _path[_path_index]
		var dist := position.distance_to(target)
		if dist > 0.001:
			look_at(target, Vector3.UP)
		if dist <= budget:
			position = target
			budget -= dist
			remaining_distance = maxf(remaining_distance - dist, 0.0)
			_path_index += 1
		else:
			position += (target - position) / dist * budget
			remaining_distance = maxf(remaining_distance - budget, 0.0)
			budget = 0.0
	if _path_index >= _path.size():
		_finished = true
		leaked.emit(self)
		queue_free()


func _on_grid_changed() -> void:
	if _finished:
		return
	var anchor := next_cell()
	var new_path := _grid.get_world_path_3d(anchor)
	if new_path.is_empty():
		push_warning("Inimigo 3D sem caminho após mudança da grade (célula %s)" % anchor)
		return
	_adopt_path(new_path)


func _adopt_path(points: PackedVector3Array) -> void:
	_path = points
	_path_index = 0
	remaining_distance = position.distance_to(points[0])
	for i in points.size() - 1:
		remaining_distance += points[i].distance_to(points[i + 1])


func _tint_placeholder() -> void:
	if _mesh == null or data == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = data.placeholder_color
	_mesh.material_override = mat
