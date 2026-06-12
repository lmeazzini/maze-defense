class_name Enemy
extends Node2D
## Inimigo terrestre: anda de centro em centro de célula até a saída.
## Invariante de reroteamento: estando entre A e B (indo para o centro de B),
## o novo caminho é calculado A PARTIR DE B — a validação de construção garante
## que B nunca vira sólido, então basta terminar o segmento e seguir.
##
## Coordenadas locais ao Board (mesmo espaço do GridManager).

signal died(enemy: Enemy)
signal leaked(enemy: Enemy)

var data: EnemyData
var current_hp: float
## Distância restante até a saída em px — métrica de mira "primeiro da fila"
var remaining_distance: float = 0.0

var _grid: GridManager
var _path: PackedVector2Array
var _path_index: int = 0
var _slow_factor: float = 1.0
var _slow_time_left: float = 0.0
var _finished: bool = false


func _ready() -> void:
	GameEvents.grid_changed.connect(_on_grid_changed)


## Injeção direta do GridManager (exceção documentada a "sinais em tudo"):
## consulta de caminho é serviço síncrono com retorno.
func setup(grid: GridManager, enemy_data: EnemyData, hp_multiplier: float = 1.0) -> void:
	_grid = grid
	data = enemy_data
	current_hp = data.max_hp * hp_multiplier


## Posiciona na entrada e calcula o caminho inicial. Chamar após add_child.
func start() -> void:
	position = _grid.cell_to_world(_grid.entry_cell)
	_adopt_path(_grid.get_world_path(_grid.entry_cell))


func current_cell() -> Vector2i:
	return _grid.world_to_cell(position)


## Célula para cuja direção o inimigo está andando (== atual quando parado num centro).
func next_cell() -> Vector2i:
	if _path_index < _path.size():
		return _grid.world_to_cell(_path[_path_index])
	return current_cell()


func effective_speed() -> float:
	return data.speed * (_slow_factor if _slow_time_left > 0.0 else 1.0)


func take_damage(amount: float, type: TowerData.DamageType) -> void:
	if _finished:
		return
	var final := amount
	if type == TowerData.DamageType.PHYSICAL:
		final *= 1.0 - data.armor
	current_hp -= final
	queue_redraw()
	if current_hp <= 0.0:
		_finished = true
		died.emit(self)
		queue_free()


## Slow não acumula: mantém o fator mais forte e renova a duração.
func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = minf(factor, _slow_factor) if _slow_time_left > 0.0 else factor
	_slow_time_left = duration
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _finished or _path_index >= _path.size():
		return
	if _slow_time_left > 0.0:
		_slow_time_left -= delta
	var budget := effective_speed() * delta
	while budget > 0.0 and _path_index < _path.size():
		var target := _path[_path_index]
		var dist := position.distance_to(target)
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
	queue_redraw()


func _on_grid_changed() -> void:
	if _finished:
		return
	var anchor := next_cell()
	var new_path := _grid.get_world_path(anchor)
	if new_path.is_empty():
		# Não deveria acontecer: a validação garante caminho para occupied_cells
		push_warning("Inimigo sem caminho após mudança da grade (célula %s)" % anchor)
		return
	_adopt_path(new_path)


func _adopt_path(points: PackedVector2Array) -> void:
	_path = points
	_path_index = 0
	remaining_distance = position.distance_to(points[0])
	for i in points.size() - 1:
		remaining_distance += points[i].distance_to(points[i + 1])


func _draw() -> void:
	if data == null:
		return
	draw_circle(Vector2.ZERO, data.radius, data.placeholder_color)
	if data.armor >= 0.5:
		draw_arc(Vector2.ZERO, data.radius + 2.0, 0.0, TAU, 24, Color(0.6, 0.6, 0.65), 2.0)
	if _slow_time_left > 0.0:
		draw_circle(Vector2.ZERO, data.radius, Color(0.3, 0.6, 1.0, 0.45))
	if current_hp < data.max_hp:
		var width := data.radius * 2.0
		var top := Vector2(-data.radius, -data.radius - 8.0)
		draw_rect(Rect2(top, Vector2(width, 4.0)), Color(0.15, 0.15, 0.15))
		var ratio := clampf(current_hp / data.max_hp, 0.0, 1.0)
		draw_rect(Rect2(top, Vector2(width * ratio, 4.0)), Color(0.25, 0.85, 0.3))
