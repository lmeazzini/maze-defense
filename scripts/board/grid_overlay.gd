class_name GridOverlay
extends Node2D
## Camada de desenho da grade: linhas, obstáculos, blocos, entrada/saída,
## polyline do caminho e preview de construção (verde/vermelho).
## Tudo via _draw — placeholders até a arte do M6.

const COLOR_GRID_LINE := Color(0.0, 0.0, 0.0, 0.10)
const COLOR_FIXED := Color(0.35, 0.35, 0.35)
const COLOR_TOWER_BLOCK := Color(0.97, 0.64, 0.12)

const GROUND_TEXTURE := preload("res://assets/sprites/ground_grass.png")
const OBSTACLE_TEXTURE := preload("res://assets/sprites/obstacle_bush.png")
const COLOR_ENTRY := Color(0.2, 0.8, 0.3)
const COLOR_EXIT := Color(0.9, 0.25, 0.2)
const COLOR_PATH := Color(0.95, 0.9, 0.3, 0.9)
const COLOR_PREVIEW_OK := Color(0.2, 0.9, 0.3, 0.35)
const COLOR_PREVIEW_BAD := Color(0.95, 0.15, 0.1, 0.45)

var _grid: GridManager
var _hover_cell := Vector2i(-1, -1)
var _hover_valid := false
var _has_hover := false
var _hover_range_px := 0.0


func setup(grid: GridManager) -> void:
	_grid = grid
	GameEvents.grid_changed.connect(queue_redraw)
	queue_redraw()


func set_hover(cell: Vector2i, valid: bool, range_px: float = 0.0) -> void:
	if _has_hover and cell == _hover_cell and valid == _hover_valid and range_px == _hover_range_px:
		return
	_hover_cell = cell
	_hover_valid = valid
	_hover_range_px = range_px
	_has_hover = true
	queue_redraw()


func clear_hover() -> void:
	if not _has_hover:
		return
	_has_hover = false
	queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
	var cell := float(GridManager.CELL_SIZE)
	var size_px := _grid.grid_pixel_size()

	# Chão (grama) em toda a grade
	for x in _grid.grid_size.x:
		for y in _grid.grid_size.y:
			draw_texture_rect(GROUND_TEXTURE, Rect2(Vector2(x, y) * cell, Vector2.ONE * cell), false)

	for x in _grid.grid_size.x + 1:
		draw_line(Vector2(x * cell, 0.0), Vector2(x * cell, size_px.y), COLOR_GRID_LINE)
	for y in _grid.grid_size.y + 1:
		draw_line(Vector2(0.0, y * cell), Vector2(size_px.x, y * cell), COLOR_GRID_LINE)

	for x in _grid.grid_size.x:
		for y in _grid.grid_size.y:
			var c := Vector2i(x, y)
			if _grid.is_fixed_obstacle(c):
				draw_texture_rect(
					OBSTACLE_TEXTURE, Rect2(Vector2(c) * cell, Vector2.ONE * cell), false
				)
			# Células sólidas restantes são torres — elas desenham a si mesmas

	_fill_cell(_grid.entry_cell, COLOR_ENTRY)
	_fill_cell(_grid.exit_cell, COLOR_EXIT)

	var path := _grid.entry_path()
	if path.size() >= 2:
		draw_polyline(path, COLOR_PATH, 4.0)

	if _has_hover and _grid.is_inside(_hover_cell):
		_fill_cell(_hover_cell, COLOR_PREVIEW_OK if _hover_valid else COLOR_PREVIEW_BAD)
		if _hover_range_px > 0.0:
			var center := _grid.cell_to_world(_hover_cell)
			draw_arc(center, _hover_range_px, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.4), 2.0)
			draw_circle(center, _hover_range_px, Color(1.0, 1.0, 1.0, 0.06))


func _fill_cell(c: Vector2i, color: Color) -> void:
	var cell := float(GridManager.CELL_SIZE)
	draw_rect(Rect2(Vector2(c) * cell + Vector2.ONE * 2.0, Vector2.ONE * (cell - 4.0)), color)
