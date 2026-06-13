class_name GridView3D
extends Node3D
## Renderiza o tabuleiro em 3D com malhas simples (placeholders até o port da
## arte): tiles de chão, obstáculos, entrada/saída, blocos de torre, marcadores
## do caminho e o preview de construção (verde/vermelho). Reage a grid_changed.

const TILE := 0.96  # tamanho do tile (deixa uma fresta entre células)
const COLOR_GROUND := Color(0.27, 0.62, 0.33)
const COLOR_OBSTACLE := Color(0.32, 0.24, 0.18)
const COLOR_BLOCK := Color(0.85, 0.55, 0.12)
const COLOR_ENTRY := Color(0.25, 0.78, 0.35)
const COLOR_EXIT := Color(0.88, 0.28, 0.22)
const COLOR_PATH := Color(0.95, 0.9, 0.3)
const COLOR_PREVIEW_OK := Color(0.2, 0.9, 0.3)
const COLOR_PREVIEW_BAD := Color(0.95, 0.2, 0.15)

var _grid: GridManager
var _blocks: Node3D
var _path_markers: Node3D
var _preview: MeshInstance3D
var _tile_mesh: BoxMesh
var _block_mesh: BoxMesh
var _marker_mesh: BoxMesh
var _mats: Dictionary = {}


func setup(grid: GridManager) -> void:
	_grid = grid
	_build_meshes()
	_build_static_board()
	_blocks = Node3D.new()
	add_child(_blocks)
	_path_markers = Node3D.new()
	add_child(_path_markers)
	_build_preview()
	GameEvents.grid_changed.connect(_redraw_dynamic)
	_redraw_dynamic()


func set_preview(cell: Vector2i, valid: bool) -> void:
	if not _grid.is_inside(cell):
		_preview.visible = false
		return
	_preview.visible = true
	_preview.position = _grid.cell_to_world_3d(cell, 0.12)
	_preview.material_override = _mat(COLOR_PREVIEW_OK if valid else COLOR_PREVIEW_BAD, 0.5)


func clear_preview() -> void:
	_preview.visible = false


func _build_meshes() -> void:
	_tile_mesh = BoxMesh.new()
	_tile_mesh.size = Vector3(TILE, 0.1, TILE)
	_block_mesh = BoxMesh.new()
	_block_mesh.size = Vector3(TILE, 0.6, TILE)
	_marker_mesh = BoxMesh.new()
	_marker_mesh.size = Vector3(0.22, 0.04, 0.22)


func _build_static_board() -> void:
	var static_root := Node3D.new()
	add_child(static_root)
	for x in _grid.grid_size.x:
		for y in _grid.grid_size.y:
			var cell := Vector2i(x, y)
			var color := COLOR_GROUND
			if cell == _grid.entry_cell:
				color = COLOR_ENTRY
			elif cell == _grid.exit_cell:
				color = COLOR_EXIT
			elif _grid.is_fixed_obstacle(cell):
				color = COLOR_OBSTACLE
			var is_obstacle := _grid.is_fixed_obstacle(cell)
			var tile := MeshInstance3D.new()
			tile.mesh = _block_mesh if is_obstacle else _tile_mesh
			tile.material_override = _mat(color)
			tile.position = _grid.cell_to_world_3d(cell, 0.3 if is_obstacle else 0.0)
			static_root.add_child(tile)


func _build_preview() -> void:
	_preview = MeshInstance3D.new()
	_preview.mesh = _tile_mesh
	_preview.visible = false
	add_child(_preview)


func _redraw_dynamic() -> void:
	for child in _blocks.get_children():
		child.queue_free()
	for child in _path_markers.get_children():
		child.queue_free()
	# Blocos de torre = células sólidas que não são obstáculos fixos
	for x in _grid.grid_size.x:
		for y in _grid.grid_size.y:
			var cell := Vector2i(x, y)
			if _grid.is_solid(cell) and not _grid.is_fixed_obstacle(cell):
				var block := MeshInstance3D.new()
				block.mesh = _block_mesh
				block.material_override = _mat(COLOR_BLOCK)
				block.position = _grid.cell_to_world_3d(cell, 0.3)
				_blocks.add_child(block)
	# Marcadores do caminho entrada→saída
	var mat := _mat(COLOR_PATH)
	for cell in _grid.get_cell_path(_grid.entry_cell):
		var marker := MeshInstance3D.new()
		marker.mesh = _marker_mesh
		marker.material_override = mat
		marker.position = _grid.cell_to_world_3d(cell, 0.12)
		_path_markers.add_child(marker)


func _mat(color: Color, alpha: float = 1.0) -> StandardMaterial3D:
	var key := "%s_%.2f" % [color.to_html(), alpha]
	if _mats.has(key):
		return _mats[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color, alpha)
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = mat
	return mat
